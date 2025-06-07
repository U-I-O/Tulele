import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tulele/ai/domain/entities/chat_message.dart';
import 'package:tulele/core/services/api_service.dart';
import 'dart:io';
import 'dart:async';

/// API调用类型
enum ApiType { primary, backup, local, mock }

/// Deepseek API 调用类 - 现通过后端API调用
class DeepseekApi {
  // 创建API服务实例
  final ApiService _apiService = ApiService();

  // 设置为false以确保一定调用后端API
  static const bool _useMockResponse = false;

  /// 发送聊天消息到API
  Future<ChatMessage> sendChatMessage(String message, List<dynamic> history) async {
    try {
      print('调用后端API聊天: $message');
      
      // 将聊天历史转换为API所需格式
      final List<Map<String, dynamic>> formattedHistory = [];
      
      // 处理不同格式的聊天历史
      for (var msg in history) {
        if (msg is ChatMessage) {
          // 如果是ChatMessage类型
          if (msg.type == ChatMessageType.text) {
            formattedHistory.add({
              'role': msg.isUserMessage ? 'user' : 'assistant',
              'content': msg.content,
            });
          }
        } else if (msg is Map) {
          // 如果是Map类型
          formattedHistory.add({
            'role': msg['isUserMessage'] == true ? 'user' : 'assistant',
            'content': msg['content'] ?? '',
          });
        }
      }
      
      // 限制历史记录条数 - 只保留最近5条
      final limitedHistory = formattedHistory.length > 5 
          ? formattedHistory.sublist(formattedHistory.length - 5) 
          : formattedHistory;

      print('📤 发送到API的数据: message=$message, history=${jsonEncode(limitedHistory)}');
      print('📡 调用AI聊天接口');
      
      // 调用后端AI聊天接口
      final response = await _apiService.sendAiChatMessage(message, limitedHistory);
      
      print('📥 收到后端响应: ${jsonEncode(response)}');
      
      // 解析响应
      final content = response['content'] as String? ?? '抱歉，无法获取回复内容';
      final List<String> suggestions = response.containsKey('suggestions') && response['suggestions'] != null
          ? List<String>.from(response['suggestions'])
          : ['帮我规划行程', '推荐热门目的地', '查看我的行程'];
      
      return ChatMessage(
        content: content,
        isUserMessage: false,
        suggestions: suggestions,
      );
    } catch (e) {
      print('❌ API调用失败: $e');
      // 错误时抛出异常，不使用模拟数据
      String errorMessage = '与AI服务通信失败';
      
      // 提取更具体的错误信息
      if (e.toString().contains('422')) {
        errorMessage = '与AI服务通信失败: 请求格式错误';
      } else if (e.toString().contains('401')) {
        errorMessage = '与AI服务通信失败: API认证失败';
      } else if (e.toString().contains('429')) {
        errorMessage = '与AI服务通信失败: 请求频率超限';
      } else if (e.toString().contains('500')) {
        errorMessage = '与AI服务通信失败: 服务器内部错误';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '与AI服务通信失败: 请求超时';
      } else {
        errorMessage = '与AI服务通信失败: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// 生成模拟AI响应
  ChatMessage _generateMockResponse(String message) {
    print('⚠️ 使用模拟响应，原因：实际API调用失败或被跳过');
    
    String response;
    List<String> suggestions = [];
    
    message = message.toLowerCase();
    if (message.contains('你好') || message.contains('hi') || message.contains('hello')) {
      return ChatMessage(
        content: '你好！我是途乐乐，您的专业旅游助理。我可以帮您规划行程、推荐景点、提供旅游建议等。请问您想去哪里旅游？或者需要什么旅游帮助？',
        isUserMessage: false,
        suggestions: ['我想去北京旅游', '推荐国内热门景点', '帮我规划3天的上海行程'],
      );
    } else if (message.contains('规划') || message.contains('行程')) {
      return ChatMessage(
        content: '好的，我很乐意帮您规划行程。为了给您提供最合适的建议，请告诉我：\n1. 您想去哪个目的地？\n2. 计划旅行几天？\n3. 有什么特别的偏好吗？(如文化、美食、购物、自然风光等)\n4. 预算大概是多少？',
        isUserMessage: false,
        suggestions: ['北京3天文化之旅', '上海周末美食游', '成都5天深度游'],
      );
    } else {
      return ChatMessage(
        content: '您好！我很乐意为您提供旅游信息和行程建议，但目前我无法连接到AI服务器。请告诉我您感兴趣的具体目的地，我可以在连接恢复后为您提供更详细的信息。',
        isUserMessage: false,
        suggestions: ['推荐热门旅游目的地', '国内旅游', '国际旅游'],
      );
    }
  }

  /// 生成旅游行程规划
  Future<Map<String, dynamic>> generateTripPlan(String prompt, List<dynamic> history) async {
    try {
      print('调用后端API生成行程: $prompt');
      
      // 将聊天历史转换为API所需格式
      final List<Map<String, dynamic>> formattedHistory = [];
      
      // 处理不同格式的聊天历史
      for (var msg in history) {
        if (msg is ChatMessage) {
          // 如果是ChatMessage类型
          if (msg.type == ChatMessageType.text) {
            formattedHistory.add({
              'role': msg.isUserMessage ? 'user' : 'assistant',
              'content': msg.content,
            });
          }
        } else if (msg is Map) {
          // 如果是Map类型
          formattedHistory.add({
            'role': msg['isUserMessage'] == true ? 'user' : 'assistant',
            'content': msg['content'] ?? '',
          });
        }
      }
      
      // 限制历史记录条数
      final limitedHistory = formattedHistory.take(5).toList();
      
      print('格式化后的历史记录: ${limitedHistory.length}条消息');
      
      // 调用后端AI生成行程接口
      final Map<String, dynamic> tripData = 
          await _apiService.generateAiTripPlan(prompt, limitedHistory);
      
      print('后端返回行程数据');
      
      return tripData;
    } catch (e) {
      print('生成行程失败: $e');
      // 错误时抛出异常，不使用前端模拟数据
      throw Exception('无法生成行程: $e');
    }
  }

  /// 修改现有行程
  Future<Map<String, dynamic>> modifyTripPlan(String prompt, Map<String, dynamic> currentPlan, List<dynamic> history) async {
    try {
      print('调用后端API修改行程: $prompt');
      
      // 将聊天历史转换为API所需格式
      final List<Map<String, dynamic>> formattedHistory = [];
      
      // 处理不同格式的聊天历史
      for (var msg in history) {
        if (msg is ChatMessage) {
          // 如果是ChatMessage类型
          if (msg.type == ChatMessageType.text) {
            formattedHistory.add({
              'role': msg.isUserMessage ? 'user' : 'assistant',
              'content': msg.content,
            });
          }
        } else if (msg is Map) {
          // 如果是Map类型
          formattedHistory.add({
            'role': msg['isUserMessage'] == true ? 'user' : 'assistant',
            'content': msg['content'] ?? '',
          });
        }
      }
      
      // 限制历史记录条数
      final limitedHistory = formattedHistory.take(5).toList();
      
      print('格式化后的历史记录: ${limitedHistory.length}条消息');
      print('当前行程数据: ${currentPlan['name']}');
      
      // 调用后端AI修改行程接口
      final modifiedPlan = await _apiService.modifyAiTripPlan(prompt, currentPlan, limitedHistory);
      
      print('后端返回修改后的行程数据');
      
      return modifiedPlan;
    } catch (e) {
      print('修改行程失败: $e');
      // 错误时抛出异常，不使用前端模拟数据
      throw Exception('无法修改行程: $e');
    }
  }

  // 以下是辅助方法：

  /// 从提示中提取目的地
  String _extractDestination(String prompt) {
    // 简单实现：查找常见表达方式中的目的地
    final destinationPatterns = [
      RegExp(r'去([\u4e00-\u9fa5]+)旅游'),
      RegExp(r'([\u4e00-\u9fa5]+)之旅'),
      RegExp(r'([\u4e00-\u9fa5]+)旅行'),
      RegExp(r'([\u4e00-\u9fa5]+)游玩'),
      RegExp(r'去([\u4e00-\u9fa5]+)玩'),
      RegExp(r'去([\u4e00-\u9fa5]+)度假'),
    ];
    
    for (var pattern in destinationPatterns) {
      final match = pattern.firstMatch(prompt);
      if (match != null && match.groupCount >= 1) {
        final destination = match.group(1);
        if (destination != null && destination.length >= 2 && destination.length <= 10) {
          return destination;
        }
      }
    }
    
    // 如果没有匹配，尝试提取2-3个字的城市名
    final cityPattern = RegExp(r'([\u4e00-\u9fa5]{2,3}市?)');
    final match = cityPattern.firstMatch(prompt);
    if (match != null) {
      return match.group(1) ?? '北京'; // 默认北京
    }
    
    return '北京'; // 默认返回北京
  }

  /// 从提示中提取天数
  int _extractDays(String prompt) {
    // 匹配数字+天的模式
    final daysPattern = RegExp(r'(\d+)\s*天');
    final match = daysPattern.firstMatch(prompt);
    if (match != null && match.groupCount >= 1) {
      return int.tryParse(match.group(1) ?? '') ?? 3;
    }
    return 3; // 默认3天
  }

  /// 从提示中提取标签
  List<String> _extractTags(String prompt) {
    final allTags = [
      '文化', '美食', '购物', '亲子', '自然风光', '历史',
      '古迹', '艺术', '博物馆', '休闲', '冒险', '户外',
      '温泉', '海滩', '山川', '乡村', '城市', '摄影',
    ];
    
    List<String> matchedTags = [];
    for (var tag in allTags) {
      if (prompt.contains(tag)) {
        matchedTags.add(tag);
      }
    }
    
    return matchedTags.isEmpty ? ['文化', '美食'] : matchedTags;
  }

  /// 验证并修复行程数据
  Map<String, dynamic> _validateAndFixTripData(Map<String, dynamic> tripData, String destination, int days, List<String> tags) {
    try {
      // 确保行程数据中包含必要的字段
      if (!tripData.containsKey('name')) {
        tripData['name'] = '$destination${days}天${tags.isNotEmpty ? tags.first : ''}之旅';
      }
      
      if (!tripData.containsKey('destination')) {
        tripData['destination'] = destination;
      }
      
      if (!tripData.containsKey('tags') || tripData['tags'] is! List || (tripData['tags'] as List).isEmpty) {
        tripData['tags'] = tags;
      }
      
      if (!tripData.containsKey('days') || tripData['days'] is! List || (tripData['days'] as List).isEmpty) {
        tripData['days'] = _createDefaultDays(destination, days);
      } else {
        // 确保每天的行程数据格式正确
        List<Map<String, dynamic>> daysList = List<Map<String, dynamic>>.from(tripData['days']);
        for (int i = 0; i < daysList.length; i++) {
          Map<String, dynamic> day = daysList[i];
          
          if (!day.containsKey('dayNumber')) {
            day['dayNumber'] = i + 1;
          }
          
          if (!day.containsKey('date')) {
            day['date'] = DateTime.now().add(Duration(days: i)).toString().split(' ')[0];
          }
          
          if (!day.containsKey('title') || day['title'] == null || day['title'] == '') {
            day['title'] = '第${i + 1}天：$destination游览';
          }
          
          if (!day.containsKey('activities') || day['activities'] is! List || (day['activities'] as List).isEmpty) {
            day['activities'] = _createDefaultActivities(i + 1);
          }
          
          if (!day.containsKey('notes')) {
            day['notes'] = '行程安排仅供参考，可根据实际情况调整。';
          }
        }
      }
      
      return tripData;
    } catch (e) {
      print('验证行程数据时出错: $e');
      // 如果验证和修复出错，返回默认行程
      return _generateDetailedMockTrip(destination, days, tags);
    }
  }

  /// 验证修改后的行程
  Map<String, dynamic> _validateModifiedPlan(Map<String, dynamic> modifiedPlan, Map<String, dynamic> originalPlan) {
    try {
      // 确保修改后的行程包含所有必要字段
      if (!modifiedPlan.containsKey('name') || modifiedPlan['name'] == null) {
        modifiedPlan['name'] = originalPlan['name'];
      }
      
      if (!modifiedPlan.containsKey('destination') || modifiedPlan['destination'] == null) {
        modifiedPlan['destination'] = originalPlan['destination'];
      }
      
      if (!modifiedPlan.containsKey('tags') || modifiedPlan['tags'] == null) {
        modifiedPlan['tags'] = originalPlan['tags'];
      }
      
      if (!modifiedPlan.containsKey('days') || modifiedPlan['days'] == null || modifiedPlan['days'] is! List) {
        modifiedPlan['days'] = originalPlan['days'];
      }
      
      return modifiedPlan;
    } catch (e) {
      print('验证修改后行程时出错: $e');
      return originalPlan; // 出错时返回原始行程
    }
  }

  /// 简单模拟对行程的修改
  Map<String, dynamic> _simulateModification(Map<String, dynamic> currentPlan) {
    // 创建深拷贝避免修改原对象
    Map<String, dynamic> modifiedPlan = json.decode(json.encode(currentPlan));
    
    // 对行程名称作简单修改
    modifiedPlan['name'] = '修改后的' + currentPlan['name'];
    
    // 如果有行程天数数据
    if (modifiedPlan.containsKey('days') && modifiedPlan['days'] is List && (modifiedPlan['days'] as List).isNotEmpty) {
      List<dynamic> days = modifiedPlan['days'] as List;
      
      // 修改第一天的标题
      if (days.isNotEmpty && days[0] is Map) {
        (days[0] as Map)['title'] = '修改后的' + ((days[0] as Map)['title'] ?? '第一天行程');
        
        // 修改第一天的第一个活动描述
        List<dynamic> activities = (days[0] as Map)['activities'] as List? ?? [];
        if (activities.isNotEmpty && activities[0] is Map) {
          (activities[0] as Map)['description'] = '修改后的' + ((activities[0] as Map)['description'] ?? '活动');
        }
      }
    }
    
    return modifiedPlan;
  }

  /// 生成详细的模拟行程
  Map<String, dynamic> _generateDetailedMockTrip(String destination, int days, List<String> tags) {
    // 确保天数有效
    days = days > 0 ? days : 3;
    
    // 创建行程名称
    final String tripName = '$destination${days}天${tags.isNotEmpty ? tags[0] : '休闲'}之旅';
    
    // 创建每天的行程
    final List<Map<String, dynamic>> daysList = _generateMockDays(destination, days);
    
    return {
      'name': tripName,
      'destination': destination,
      'tags': tags.isEmpty ? ['休闲', '美食'] : tags,
      'days': daysList,
    };
  }

  /// 生成模拟天数行程
  List<Map<String, dynamic>> _generateMockDays(String destination, int days) {
    final daysList = <Map<String, dynamic>>[];
    
    // 模拟景点列表
    final attractions = [
      '${destination}博物馆',
      '${destination}公园',
      '${destination}古街',
      '${destination}著名景区',
      '${destination}标志性建筑',
      '${destination}历史遗迹',
      '${destination}文化中心',
      '${destination}特色街区',
    ];
    
    for (int i = 0; i < days; i++) {
      final attractionIndex = i * 2 % attractions.length;
      
      // 添加当天活动
      final activities = [
        {
          'id': 'act_${i+1}_1',
          'time': '09:00',
          'description': '游览${attractions[attractionIndex % attractions.length]}',
          'location': '${attractions[attractionIndex % attractions.length]}',
        },
        {
          'id': 'act_${i+1}_2',
          'time': '12:00',
          'description': '午餐',
          'location': '${destination}特色餐厅',
        },
        {
          'id': 'act_${i+1}_3',
          'time': '14:00',
          'description': '游览${attractions[(attractionIndex+1) % attractions.length]}',
          'location': '${attractions[(attractionIndex+1) % attractions.length]}',
        },
        {
          'id': 'act_${i+1}_4',
          'time': '18:00',
          'description': '晚餐',
          'location': '${destination}本地特色美食',
        },
      ];
      
      // 给第一天添加额外的抵达内容，最后一天添加返程内容
      if (i == 0) {
        activities.insert(0, {
          'id': 'act_${i+1}_0',
          'time': '08:00',
          'description': '抵达${destination}',
          'location': '${destination}机场/火车站',
        });
      } else if (i == days - 1) {
        activities.add({
          'id': 'act_${i+1}_5',
          'time': '20:00',
          'description': '返程准备',
          'location': '酒店',
        });
      }
      
      daysList.add({
        'dayNumber': i + 1,
        'date': DateTime.now().add(Duration(days: i)).toString().split(' ')[0],
        'title': '第${i+1}天：${destination}${_getDayTheme(i+1, days)}',
        'activities': activities,
        'notes': '这是自动生成的基础行程，建议根据实际情况调整时间和活动安排。',
      });
    }
    
    return daysList;
  }
  
  /// 获取天数对应的主题
  String _getDayTheme(int day, int totalDays) {
    if (day == 1) {
      return '初体验';
    } else if (day == totalDays) {
      return '精华探索与告别';
    } else if (day == 2 && totalDays > 3) {
      return '文化之旅';
    } else if (day == 3 && totalDays > 3) {
      return '自然风光';
    } else {
      return '深度游';
    }
  }

  /// 创建默认天数行程
  List<Map<String, dynamic>> _createDefaultDays(String destination, int days) {
    final daysList = <Map<String, dynamic>>[];
    
    for (int i = 0; i < days; i++) {
      daysList.add({
        'dayNumber': i + 1,
        'date': DateTime.now().add(Duration(days: i)).toString().split(' ')[0],
        'title': '第${i+1}天：$destination游览',
        'activities': _createDefaultActivities(i + 1),
        'notes': '这是自动生成的基础行程，您可以根据实际情况调整。',
      });
    }
    
    return daysList;
  }

  /// 创建默认活动
  List<Map<String, dynamic>> _createDefaultActivities(int dayNumber) {
    return [
      {
        'id': 'act_${dayNumber}_1',
        'time': '09:00',
        'description': '上午景点游览',
        'location': '待选景点',
      },
      {
        'id': 'act_${dayNumber}_2',
        'time': '12:00',
        'description': '午餐',
        'location': '当地餐厅',
      },
      {
        'id': 'act_${dayNumber}_3',
        'time': '14:00',
        'description': '下午景点游览',
        'location': '待选景点',
      },
      {
        'id': 'act_${dayNumber}_4',
        'time': '18:00',
        'description': '晚餐',
        'location': '当地特色餐厅',
      },
    ];
  }
} 
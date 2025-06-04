import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tulele/ai/domain/entities/chat_message.dart';
import 'dart:io';
import 'dart:async';

/// API调用类型
enum ApiType { primary, backup, local, mock }

/// Deepseek API 调用类
class DeepseekApi {
  // API配置 - 请替换为实际有效的API密钥
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String _apiKey = 'sk-5ed287ed4abc4f9d86bd4c8d4251b7dd'; // 原始API密钥，需要替换为有效密钥
  
  // 备用API配置 - 使用OpenAI兼容格式
  static const String _backupApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _backupApiKey = 'sk-5ed287ed4abc4f9d86bd4c8d4251b7dd'; // 需要替换为有效密钥
  
  // 模型名称
  static const String _primaryModel = 'deepseek-chat';
  static const String _backupModel = 'gpt-3.5-turbo';
  
  // 是否使用模拟响应 (临时解决方案，当API无法连接时)
  static const bool _useMockResponse = false;
  
  // 增强版旅游系统提示词
  static const String _travelSystemPrompt = '''
你是一个专业的旅游助理，名叫"途乐乐"。你擅长为用户提供旅游规划和建议。
请记住以下几点：
1. 你的回答必须与旅游相关，如果用户询问非旅游相关的问题，请礼貌地将话题引导回旅游领域
2. 你的建议应当详尽并提供实用信息，包括具体的景点推荐、交通建议、餐饮选择和住宿推荐等
3. 所有日期必须是真实有效的，每天安排2-4个活动，每个活动必须包含具体地点、时间、描述
4. 保持友好、专业的语气，避免过于冗长的回答
5. 如果用户提供的信息不足以做出完整规划，可以询问更多细节

对于行程规划，请确保包含以下信息：
- 行程名称要具体，例如"北京4日文化探索之旅"
- 目的地必须明确，例如"北京"
- 为行程添加合适的标签，例如"文化"、"美食"、"亲子"等
- 每日清晰的行程安排，包括早中晚的活动
- 每个活动都有具体时间(例如"09:00")、详细描述和具体地点
- 提供实用的交通建议、餐饮和住宿推荐
- 合理的预算分配建议
''';

  /// 发送聊天消息到API
  Future<ChatMessage> sendChatMessage(String message, List<ChatMessage> history) async {
    // 将历史消息转换为API所需格式，但限制历史消息数量以提高响应速度
    final List<Map<String, dynamic>> formattedHistory = history
        .where((msg) => msg.type == ChatMessageType.text) // 只包含文本消息
        .take(5) // 只保留最近5条消息
        .map((msg) {
          return {
            'role': msg.isUserMessage ? 'user' : 'assistant',
            'content': msg.content,
          };
        }).toList();

    // 添加系统提示和当前用户消息
    final List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': _travelSystemPrompt},
      ...formattedHistory,
      {'role': 'user', 'content': message},
    ];

    // 如果强制使用模拟响应，直接返回模拟响应
    if (_useMockResponse) {
      print('使用模拟AI响应');
      return _generateMockResponse(message);
    }

    // 依次尝试主API、备用API和本地处理
    for (var apiType in [ApiType.primary, ApiType.backup, ApiType.local]) {
      try {
        print('尝试使用 ${apiType.toString()} API');
        
        switch (apiType) {
          case ApiType.primary:
            return await _callPrimaryApi(messages);
          case ApiType.backup:
            return await _callBackupApi(messages);
          case ApiType.local:
            return _generateLocalResponse(message);
          default:
            continue;
        }
      } catch (e) {
        print('${apiType.toString()} API调用失败: $e');
        // 如果不是最后一种方法，继续尝试下一种
        if (apiType != ApiType.local) {
          continue;
        } else {
          // 如果连本地处理也失败了，返回模拟响应
          print('所有API方法失败，使用模拟响应');
          return _generateMockResponse(message);
        }
      }
    }
    
    // 这行代码理论上不会执行到，但为了满足Dart的返回要求
    return _generateMockResponse(message);
  }

  /// 生成模拟AI响应
  ChatMessage _generateMockResponse(String message) {
    String response;
    List<String> suggestions = [];
    
    message = message.toLowerCase();
    if (message.contains('你好') || message.contains('hi') || message.contains('hello')) {
      response = '您好！欢迎使用途乐乐旅游助手，我可以帮您规划旅行、推荐景点和提供旅游建议。请问您想去哪里旅游呢？';
      suggestions = ['我想去三亚', '推荐国内热门景点', '规划一个北京3日游'];
    } else if (message.contains('三亚') || message.contains('海南')) {
      response = '三亚是一个非常美丽的海滨城市，拥有亚龙湾、天涯海角、蜈支洲岛等知名景点。'
          '最佳旅游季节是10月到次年4月，可以享受阳光沙滩和丰富的海鲜美食。需要我为您规划一份详细的三亚行程吗？';
      suggestions = ['帮我规划三亚3日游', '三亚有哪些必玩景点', '三亚的美食推荐'];
    } else if (message.contains('北京')) {
      response = '北京作为中国的首都，拥有众多历史文化景点，如故宫、长城、天坛、颐和园等。'
          '北京的美食也非常有特色，比如北京烤鸭、炸酱面、豆汁等。您想了解北京的哪些方面呢？';
      suggestions = ['规划北京4日文化之旅', '北京有哪些小众景点', '推荐北京特色美食'];
    } else if (message.contains('规划') || message.contains('行程')) {
      response = '我很乐意帮您规划行程。为了给您提供更准确的建议，请告诉我您想去的具体目的地、出行天数、出行时间以及您的兴趣爱好(如文化、美食、购物等)。';
      suggestions = ['我想去上海3天', '帮我规划一个家庭亲子游', '周末两日游推荐'];
    } else {
      response = '感谢您的咨询。作为旅游助手，我可以帮您规划行程、推荐景点、美食和住宿，提供旅游相关的各种信息。请告诉我您感兴趣的目的地或您需要什么样的旅游信息？';
      suggestions = ['国内热门旅游目的地', '出国旅游推荐', '周边游好去处'];
    }
    
    return ChatMessage(
      content: response,
      isUserMessage: false,
      suggestions: suggestions,
    );
  }

  /// 调用主API
  Future<ChatMessage> _callPrimaryApi(List<Map<String, dynamic>> messages) async {
    try {
      // 最多重试2次
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          print('调用主API (尝试 ${attempt + 1}/2)');
          final response = await http.post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _primaryModel,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          ).timeout(const Duration(seconds: 60)); // 增加超时时间

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final content = data['choices'][0]['message']['content'];
            
            // 检查是否包含旅游建议
            bool hasSuggestions = content.contains('建议') || content.contains('推荐') || content.contains('行程');
            List<String>? suggestions;
            
            if (hasSuggestions) {
              suggestions = [
                '听起来不错，详细规划一下行程',
                '我想修改一些细节',
                '有其他推荐吗'
              ];
            }

            return ChatMessage(
              content: content,
              isUserMessage: false,
              suggestions: suggestions,
            );
          } else {
            print('API错误状态码: ${response.statusCode}, 响应: ${response.body}');
            // 如果是5xx服务器错误，尝试重试
            if (response.statusCode >= 500 && attempt < 1) {
              print('服务器错误，将重试...');
              continue;
            }
            throw Exception('API错误: ${response.statusCode} - ${response.body}');
          }
        } on TimeoutException {
          print('API请求超时 (尝试 ${attempt + 1}/2)');
          if (attempt < 1) {
            print('将重试请求...');
            continue;
          }
          throw Exception('API请求超时，请检查网络连接后重试');
        }
      }
      // 所有重试都失败
      throw Exception('多次尝试后API请求仍失败');
    } catch (e) {
      print('API请求异常: $e');
      throw e;
    }
  }

  /// 调用备用API
  Future<ChatMessage> _callBackupApi(List<Map<String, dynamic>> messages) async {
    try {
      // 最多重试1次
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          print('调用备用API (尝试 ${attempt + 1}/2)');
          final response = await http.post(
            Uri.parse(_backupApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_backupApiKey',
            },
            body: jsonEncode({
              'model': _backupModel,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          ).timeout(const Duration(seconds: 60)); // 增加超时时间

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final content = data['choices'][0]['message']['content'];
            
            return ChatMessage(
              content: content,
              isUserMessage: false,
              suggestions: ['规划行程', '查询景点', '修改计划'],
            );
          } else {
            print('备用API错误状态码: ${response.statusCode}, 响应: ${response.body}');
            if (response.statusCode >= 500 && attempt < 1) {
              print('服务器错误，将重试...');
              continue;
            }
            throw Exception('备用API错误: ${response.statusCode} - ${response.body}');
          }
        } on TimeoutException {
          print('备用API请求超时 (尝试 ${attempt + 1}/2)');
          if (attempt < 1) {
            print('将重试请求...');
            continue;
          }
          throw Exception('备用API请求超时，请检查网络连接后重试');
        }
      }
      throw Exception('多次尝试后备用API请求仍失败');
    } catch (e) {
      print('备用API请求异常: $e');
      throw e;
    }
  }

  /// 生成本地响应（当API都不可用时）
  ChatMessage _generateLocalResponse(String message) {
    String destination = _extractDestination(message);
    
    if (destination != '未知目的地') {
      return ChatMessage(
        content: '您好！我看到您对$destination感兴趣。我很乐意为您提供有关$destination的旅游信息和行程建议，但目前我无法连接到AI服务器。您可以稍后重试，或者先浏览一些热门景点信息。',
        isUserMessage: false,
        suggestions: ['稍后重试', '$destination热门景点', '$destination美食推荐'],
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
  Future<Map<String, dynamic>> generateTripPlan(String prompt, List<ChatMessage> history) async {
    // 解析用户请求中的关键信息
    String destination = _extractDestination(prompt);
    int days = _extractDays(prompt);
    List<String> tags = _extractTags(prompt);
    
    // 如果强制使用模拟数据，直接返回生成的行程
    if (_useMockResponse) {
      print('使用模拟行程数据');
      return _generateDetailedMockTrip(destination, days, tags);
    }
    
    // 构建行程生成提示词
    final String planningPrompt = '''
请为用户生成一个详细且具体的${destination}${days > 0 ? ' $days天' : ''}行程规划。请确保包含真实景点、餐厅和活动。

行程必须符合以下格式要求：
1. 行程名称必须具体明确，例如"${destination}${days > 0 ? ' $days天' : ''} ${tags.isNotEmpty ? tags.join('') : ''}之旅"
2. 目的地必须是"$destination"
3. 每天必须有明确的主题，例如"文化探索"或"美食品尝"等
4. 每个活动必须有具体时间（例如"09:00"）、详细描述和实际存在的地点名称
5. 每天安排2-5个活动，合理分配在上午、下午和晚上
6. 确保行程在现实中可行，考虑交通时间和景点开放时间

同时，请将规划以结构化的JSON格式返回，格式如下：
{
  "name": "行程名称（必须具体）",
  "destination": "${destination}",
  "tags": ["标签1", "标签2"],
  "days": [
    {
      "dayNumber": 1,
      "date": "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
      "title": "第一天主题（必须具体）",
      "activities": [
        {"id": "act1", "time": "09:00", "description": "详细活动描述", "location": "具体地点"}
      ],
      "notes": "当天笔记和提示"
    }
  ]
}

用户原始请求: ${prompt}
''';

    final messages = [
      {'role': 'system', 'content': _travelSystemPrompt},
      {'role': 'user', 'content': planningPrompt},
    ];

    // 依次尝试不同的API
    try {
      // 先尝试主API
      print('尝试使用 primary API 生成行程');
      try {
        final tripData = await _callPrimaryApiForTrip(messages);
        return _validateAndFixTripData(tripData, destination, days, tags);
      } catch (e) {
        print('主API生成行程失败: $e');
        
        // 尝试备用API
        print('尝试使用 backup API 生成行程');
        try {
          final tripData = await _callBackupApiForTrip(messages);
          return _validateAndFixTripData(tripData, destination, days, tags);
        } catch (e2) {
          print('备用API生成行程失败: $e2');
          throw e2; // 重新抛出错误
        }
      }
    } catch (e) {
      // 所有API都失败了，使用详细的模拟行程数据
      print('所有API都失败，使用模拟行程数据');
      return _generateDetailedMockTrip(destination, days, tags);
    }
  }
  
  /// 验证并修复行程数据
  Map<String, dynamic> _validateAndFixTripData(Map<String, dynamic> tripData, String destination, int days, List<String> tags) {
    // 检查和修复关键字段
    tripData['name'] = tripData['name'] ?? '${destination}${days}日游';
    tripData['destination'] = tripData['destination'] ?? destination;
    
    if (tripData['tags'] == null || (tripData['tags'] as List).isEmpty) {
      tripData['tags'] = tags.isEmpty ? ['旅游'] : tags;
    }
    
    // 确保days字段存在且格式正确
    if (tripData['days'] == null || (tripData['days'] as List).isEmpty) {
      tripData['days'] = _createDetailedDefaultDays(destination, days);
    } else {
      // 对每一天进行检查和修复
      for (int i = 0; i < (tripData['days'] as List).length; i++) {
        var day = tripData['days'][i];
        // 确保dayNumber字段存在且正确
        day['dayNumber'] = day['dayNumber'] ?? (i + 1);
        
        // 确保date字段存在
        if (day['date'] == null) {
          day['date'] = DateTime.now().add(Duration(days: i)).toString().split(' ')[0];
        }
        
        // 确保title字段存在
        day['title'] = day['title'] ?? '第${i+1}天：${destination}游览';
        
        // 确保activities字段存在且格式正确
        if (day['activities'] == null || (day['activities'] as List).isEmpty) {
          day['activities'] = _createDefaultActivities(i + 1);
        } else {
          // 对每个活动进行检查和修复
          for (int j = 0; j < (day['activities'] as List).length; j++) {
            var activity = day['activities'][j];
            activity['id'] = activity['id'] ?? 'act_${i+1}_$j';
            activity['time'] = activity['time'] ?? '${9 + j * 2}:00';
            activity['description'] = activity['description'] ?? '游览活动';
            activity['location'] = activity['location'] ?? '待定地点';
          }
        }
        
        // 确保notes字段存在
        day['notes'] = day['notes'] ?? '根据实际情况调整行程';
      }
    }
    
    return tripData;
  }

  /// 调用主API生成行程
  Future<Map<String, dynamic>> _callPrimaryApiForTrip(List<Map<String, dynamic>> messages) async {
    try {
      // 最多重试1次
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          print('调用主API生成行程 (尝试 ${attempt + 1}/2)');
          final response = await http.post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _primaryModel,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 2048,
            }),
          ).timeout(const Duration(seconds: 80)); // 增加超时时间

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final content = data['choices'][0]['message']['content'];
            
            print('行程生成API响应: $content');
            
            // 提取JSON部分
            final tripData = _extractTripDataFromContent(content);
            if (tripData != null) {
              return tripData;
            }
            
            // 如果是第一次尝试并未提取到有效JSON，重试一次
            if (attempt < 1) {
              print('无法从响应中提取有效JSON，将重试...');
              continue;
            }
            
            throw Exception('无法从API响应中提取有效的行程数据');
          } else {
            print('行程生成API错误状态码: ${response.statusCode}, 响应: ${response.body}');
            if (response.statusCode >= 500 && attempt < 1) {
              print('服务器错误，将重试...');
              continue;
            }
            throw Exception('API错误: ${response.statusCode} - ${response.body}');
          }
        } on TimeoutException {
          print('行程生成API请求超时 (尝试 ${attempt + 1}/2)');
          if (attempt < 1) {
            print('将重试请求...');
            continue;
          }
          throw Exception('行程API请求超时，将使用本地生成的行程');
        }
      }
      throw Exception('多次尝试后行程生成API请求仍失败');
    } catch (e) {
      print('行程生成API请求异常: $e');
      throw e;
    }
  }

  /// 调用备用API生成行程
  Future<Map<String, dynamic>> _callBackupApiForTrip(List<Map<String, dynamic>> messages) async {
    try {
      // 最多重试1次
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          print('调用备用API生成行程 (尝试 ${attempt + 1}/2)');
          final response = await http.post(
            Uri.parse(_backupApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_backupApiKey',
            },
            body: jsonEncode({
              'model': _backupModel,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 2048,
            }),
          ).timeout(const Duration(seconds: 80)); // 增加超时时间

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final content = data['choices'][0]['message']['content'];
            
            print('备用API行程生成响应: $content');
            
            // 提取JSON部分
            final tripData = _extractTripDataFromContent(content);
            if (tripData != null) {
              return tripData;
            }
            
            // 如果是第一次尝试并未提取到有效JSON，重试一次
            if (attempt < 1) {
              print('无法从备用API响应中提取有效JSON，将重试...');
              continue;
            }
            
            throw Exception('无法从备用API响应中提取有效的行程数据');
          } else {
            print('备用行程生成API错误状态码: ${response.statusCode}, 响应: ${response.body}');
            if (response.statusCode >= 500 && attempt < 1) {
              print('服务器错误，将重试...');
              continue;
            }
            throw Exception('备用API错误: ${response.statusCode} - ${response.body}');
          }
        } on TimeoutException {
          print('备用行程生成API请求超时 (尝试 ${attempt + 1}/2)');
          if (attempt < 1) {
            print('将重试请求...');
            continue;
          }
          throw Exception('备用行程API请求超时，将使用本地生成的行程');
        }
      }
      throw Exception('多次尝试后备用行程生成API请求仍失败');
    } catch (e) {
      print('备用行程生成API请求异常: $e');
      throw e;
    }
  }

  /// 从内容中提取行程数据JSON
  Map<String, dynamic>? _extractTripDataFromContent(String content) {
    // 尝试提取JSON格式（代码块或普通JSON）
    final RegExp jsonRegExp = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```|(\{[\s\S]*?\})');
    final match = jsonRegExp.firstMatch(content);
    
    if (match != null) {
      final jsonStr = (match.group(1) ?? match.group(2))?.trim();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          return jsonDecode(jsonStr);
        } catch (e) {
          print('JSON解析错误: $e');
          print('待解析JSON: $jsonStr');
        }
      }
    }
    
    return null;
  }

  /// 本地生成行程（当API都不可用时）
  Map<String, dynamic> _generateLocalTrip(String destination, int days, List<String> tags) {
    if (days <= 0) days = 3;
    
    // 添加更具体的行程名称和标签
    String tripName = '$destination${days}日游';
    if (tags.isNotEmpty) {
      tripName = '$destination${days}日${tags.first}之旅';
    }
    
    final tripData = {
      'name': tripName,
      'destination': destination,
      'tags': tags.isEmpty ? ['旅游', '休闲'] : tags,
      'days': _createDetailedDefaultDays(destination, days),
      'note': '由于网络连接问题，这是一个基本行程。您可以在编辑模式下进一步完善。',
    };
    
    return tripData;
  }

  /// 创建更详细的默认天数行程
  List<Map<String, dynamic>> _createDetailedDefaultDays(String destination, int days) {
    final daysList = <Map<String, dynamic>>[];
    
    // 常见城市的景点列表
    final cityAttractions = {
      '北京': ['故宫', '长城', '颐和园', '天坛', '北海公园', '鸟巢', '798艺术区', '南锣鼓巷'],
      '上海': ['外滩', '东方明珠', '豫园', '南京路', '迪士尼乐园', '田子坊', '静安寺'],
      '广州': ['白云山', '珠江夜游', '陈家祠', '北京路', '沙面', '长隆', '广州塔'],
      '深圳': ['世界之窗', '东部华侨城', '深圳湾', '大梅沙', '欢乐谷', '莲花山'],
      '三亚': ['亚龙湾', '天涯海角', '蜈支洲岛', '南山寺', '大小洞天', '西岛'],
      '成都': ['宽窄巷子', '锦里', '春熙路', '杜甫草堂', '武侯祠', '大熊猫基地'],
    };
    
    // 获取当前目的地的景点，如果没有则使用通用景点
    final attractions = cityAttractions[destination] ?? ['景点1', '景点2', '景点3', '景点4', '景点5', '景点6'];
    
    for (int i = 0; i < days; i++) {
      // 每天景点计数
      int attractionIndex = i * 2; // 每天分配2个不同的主要景点
      if (attractionIndex >= attractions.length) {
        attractionIndex = i % attractions.length;
      }
      
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

  /// 修改现有行程
  Future<Map<String, dynamic>> modifyTripPlan(String prompt, Map<String, dynamic> currentPlan, List<ChatMessage> history) async {
    // 构建修改提示
    final String modifyPrompt = '''
请根据用户的要求，修改以下现有的旅游行程规划。保持原有的结构，只调整用户指定的部分。
必须确保：
1. 所有活动有具体时间、详细描述和真实存在的地点
2. 行程安排合理可行，考虑交通时间
3. 不要创建虚构的景点或地点
4. 返回完整的修改后行程计划

当前行程:
${jsonEncode(currentPlan)}

用户修改要求: ${prompt}

请以与原行程完全相同的JSON格式返回完整的修改后行程。确保每个活动都有id、time、description和location字段。
''';

    final messages = [
      {'role': 'system', 'content': _travelSystemPrompt},
      {'role': 'user', 'content': modifyPrompt},
    ];

    try {
      // 尝试调用API修改行程
      Map<String, dynamic> modifiedPlan;
      
      try {
        modifiedPlan = await _callPrimaryApiForTrip(messages);
      } catch (e) {
        print('主API修改行程失败，尝试备用API: $e');
        try {
          modifiedPlan = await _callBackupApiForTrip(messages);
        } catch (e2) {
          print('备用API也失败: $e2');
          throw e2;
        }
      }
      
      // 验证修改后的计划格式是否完整
      if (_validateTripPlan(modifiedPlan)) {
        return modifiedPlan;
      } else {
        // 手动应用部分修改
        return _applyPartialModification(prompt, currentPlan);
      }
    } catch (e) {
      print('修改行程失败: $e');
      
      // 添加错误说明但保持原计划不变
      final Map<String, dynamic> unchanged = Map<String, dynamic>.from(currentPlan);
      unchanged['modificationNote'] = '由于技术原因无法应用您的修改请求。您可以在编辑模式中手动调整行程。';
      
      return unchanged;
    }
  }

  /// 验证行程计划的完整性
  bool _validateTripPlan(Map<String, dynamic> plan) {
    if (plan['name'] == null || plan['destination'] == null || plan['days'] == null) {
      return false;
    }
    
    if ((plan['days'] as List).isEmpty) {
      return false;
    }
    
    for (var day in plan['days']) {
      if (day['dayNumber'] == null || day['title'] == null || day['activities'] == null) {
        return false;
      }
      
      if ((day['activities'] as List).isEmpty) {
        return false;
      }
      
      for (var activity in day['activities']) {
        if (activity['time'] == null || activity['description'] == null || activity['location'] == null) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// 手动应用部分修改
  Map<String, dynamic> _applyPartialModification(String prompt, Map<String, dynamic> currentPlan) {
    final newPlan = Map<String, dynamic>.from(currentPlan);
    
    // 简单的文本分析来应用修改
    prompt = prompt.toLowerCase();
    
    // 处理一些常见的修改请求
    if (prompt.contains('增加一天') || prompt.contains('添加一天')) {
      if (newPlan['days'] != null && newPlan['days'] is List) {
        final int newDayNumber = (newPlan['days'] as List).length + 1;
        final newDay = {
          'dayNumber': newDayNumber,
          'date': DateTime.now().add(Duration(days: newDayNumber - 1)).toString().split(' ')[0],
          'title': '第$newDayNumber天：${newPlan['destination'] ?? ''}游览',
          'activities': _createDefaultActivities(newDayNumber),
          'notes': '这是新添加的一天，请根据需要修改具体内容。',
        };
        (newPlan['days'] as List).add(newDay);
      }
    } else if (prompt.contains('减少一天') || prompt.contains('删除最后一天')) {
      if (newPlan['days'] != null && newPlan['days'] is List && (newPlan['days'] as List).length > 1) {
        (newPlan['days'] as List).removeLast();
      }
    }
    
    // 添加标签
    for (final tag in ['文化', '美食', '购物', '亲子', '自然', '摄影', '户外', '休闲']) {
      if (prompt.contains(tag)) {
        if (newPlan['tags'] == null) {
          newPlan['tags'] = [];
        }
        if (!(newPlan['tags'] as List).contains(tag)) {
          (newPlan['tags'] as List).add(tag);
        }
      }
    }
    
    newPlan['modificationNote'] = '已尝试根据您的要求进行部分修改。您可以在编辑模式中进一步调整行程。';
    
    return newPlan;
  }
  
  // 辅助函数：从用户输入中提取目的地
  String _extractDestination(String input) {
    final List<String> destinations = ['北京', '上海', '广州', '深圳', '杭州', '成都', '重庆', '西安', 
                                    '厦门', '三亚', '丽江', '大理', '桂林', '张家界', '黄山', '苏州',
                                    '南京', '武汉', '长沙', '青岛', '大连', '哈尔滨', '拉萨', '青海',
                                    '西藏', '新疆', '云南', '四川', '海南', '广西', '内蒙古', '香港', '澳门'];
    
    for (final destination in destinations) {
      if (input.toLowerCase().contains(destination.toLowerCase())) {
        return destination;
      }
    }
    
    // 尝试通过正则表达式匹配"去XX"、"到XX"等模式
    final goToRegex = RegExp(r'[去到去往前往游览游玩](\w{2,4})[旅游玩游览逛]');
    final match = goToRegex.firstMatch(input);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }
    
    return '未知目的地';
  }
  
  // 辅助函数：从用户输入中提取天数
  int _extractDays(String input) {
    final daysRegex = RegExp(r'(\d+)\s*[天日]');
    final match = daysRegex.firstMatch(input);
    if (match != null && match.group(1) != null) {
      return int.tryParse(match.group(1)!) ?? 3;
    }
    return 3; // 默认3天
  }
  
  // 辅助函数：从用户输入中提取标签
  List<String> _extractTags(String input) {
    final List<String> tags = [];
    final Map<String, List<String>> tagKeywords = {
      '文化': ['文化', '历史', '博物馆', '古迹', '古建筑', '寺庙', '传统'],
      '美食': ['美食', '吃', '餐', '味', '菜', '小吃', '饮食'],
      '购物': ['购物', '买', '商场', '街', '超市', '市场', '店'],
      '亲子': ['亲子', '孩子', '小孩', '家庭', '儿童', '宝宝', '孩'],
      '自然': ['自然', '风景', '景色', '山', '水', '海', '湖', '森林'],
      '摄影': ['摄影', '拍照', '照片', '相机'],
      '户外': ['户外', '探险', '徒步', '登山', '爬山', '露营'],
      '休闲': ['休闲', '放松', '度假', '舒适', '悠闲'],
    };
    
    for (final entry in tagKeywords.entries) {
      for (final keyword in entry.value) {
        if (input.toLowerCase().contains(keyword)) {
          tags.add(entry.key);
          break;
        }
      }
    }
    
    return tags;
  }

  /// 生成详细的模拟行程数据
  Map<String, dynamic> _generateDetailedMockTrip(String destination, int days, List<String> tags) {
    if (days <= 0) days = 3;
    
    // 添加更具体的行程名称和标签
    String tripName = '$destination${days}日游';
    if (tags.isNotEmpty) {
      tripName = '$destination${days}日${tags.first}之旅';
    }
    
    final tripData = {
      'name': tripName,
      'destination': destination,
      'tags': tags.isEmpty ? ['旅游', '休闲'] : tags,
      'days': _createDetailedDefaultDays(destination, days),
      'budget': {
        'total': days * 800,
        'accommodation': days * 300,
        'food': days * 200,
        'transportation': days * 150,
        'activities': days * 100,
        'shopping': days * 50,
        'currency': 'CNY'
      },
      'tips': [
        '提前预订热门景点门票可以节省排队时间',
        '关注天气预报，准备适当的衣物和防晒用品',
        '建议下载${destination}地图应用，方便导航',
        '带好常用药品、充电宝和相机等必要物品'
      ],
      'transportation': {
        'arrival': {
          'method': '飞机/火车',
          'notes': '抵达${destination}后可以选择地铁或出租车前往市区'
        },
        'local': ['地铁', '公交', '出租车', '共享单车'],
        'departure': {
          'method': '飞机/火车',
          'notes': '建议提前2小时到达机场/火车站办理手续'
        }
      },
      'note': '这是根据您的需求自动生成的行程，您可以在编辑模式下进一步完善。',
    };
    
    return tripData;
  }
} 
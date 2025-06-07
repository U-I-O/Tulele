// lib/ai/presentation/pages/ai_planner_page.dart
import 'package:flutter/material.dart';
import 'dart:math'; // 用于生成随机ID (如果需要为新行程生成ID)

// 核心服务和模型
import '../../../core/services/api_service.dart';
import '../../../core/models/api_trip_plan_model.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/utils/auth_utils.dart'; // 用于获取 creator_id

// 页面跳转
import '../../../trips/presentation/pages/trip_detail_page.dart';
// 导入共享枚举
import '../../../core/enums/trip_enums.dart';

// 导入AI相关类
import '../../domain/entities/chat_message.dart' as domain;
import '../../data/datasources/deepseek_api.dart';


// ChatMessage 类定义 (重命名为AIPageChatMessage，避免与导入的ChatMessage冲突)
class AIPageChatMessage {
  final String text;
  final bool isUserMessage;
  final bool hasSuggestions;
  final List<String>? suggestions;

  AIPageChatMessage({
    required this.text,
    required this.isUserMessage,
    this.hasSuggestions = false,
    this.suggestions,
  });
}

class AiPlannerPage extends StatefulWidget {
  const AiPlannerPage({super.key});

  @override
  State<AiPlannerPage> createState() => _AiPlannerPageState();
}

class _AiPlannerPageState extends State<AiPlannerPage> {
  final TextEditingController _textController = TextEditingController();
  final List<AIPageChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  final ApiService _apiService = ApiService(); // API服务实例
  final DeepseekApi _deepseekApi = DeepseekApi(); // 使用DeepseekApi进行行程生成
  bool _isProcessingAiPlan = false;            // 防止重复处理
  Map<String, dynamic>? _aiGeneratedTripData; // 保存AI生成的原始行程数据

  // 用于暂存AI生成的计划，以便用户确认后创建
  ApiTripPlan _currentAiGeneratedPlan = ApiTripPlan(
    name: 'AI待规划行程',
    tags: [],
    days: [],
  );


  @override
  void initState() {
    super.initState();
    _addInitialAiMessage();
  }

  void _addInitialAiMessage() {
    _messages.add(AIPageChatMessage(
      text: '您好！我是您的AI旅行助手"途乐乐"。想去哪里？可以告诉我您的目的地、预算、兴趣和时间，我会为您规划行程。',
          isUserMessage: false,
          hasSuggestions: true,
      suggestions: ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅', '推荐欧洲10日游高性价比路线'],
      ));
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(AIPageChatMessage(text: text, isUserMessage: true));
    _textController.clear();
    });

    _scrollToBottom();

    // 模拟AI处理中状态
    setState(() {
      _messages.add(AIPageChatMessage(text: '正在处理您的请求...', isUserMessage: false));
    });

    _scrollToBottom();

    // 基于用户消息的内容来决定如何响应
    _processUserMessage(text);
  }

  void _scrollToBottom() {
    // 确保在状态更新后滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 处理用户消息
  Future<void> _processUserMessage(String userMessage) async {
    // 处理各种不同类型的用户消息
    if (userMessage.toLowerCase().startsWith("生成行程方案") || 
        userMessage.toLowerCase() == "生成行程" || 
        userMessage.toLowerCase() == "生成方案") {
      
      // 从历史消息中寻找最近提到的目的地
      String destinationFromHistory = _findDestinationFromHistory();
      
      if (destinationFromHistory.isEmpty) {
        setState(() {
          _messages.removeLast();
          _messages.add(AIPageChatMessage(
            text: '抱歉，我不确定您想要规划哪个目的地的行程。请告诉我您想去哪里旅游？',
            isUserMessage: false,
            hasSuggestions: true,
            suggestions: ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅', '推荐欧洲10日游高性价比路线'],
          ));
        });
        return;
      }

      setState(() {
        _messages.add(AIPageChatMessage(
          text: '正在为您生成${destinationFromHistory}行程规划，请稍候...',
          isUserMessage: false,
        ));
      });

      try {
        // 使用DeepseekApi生成行程
        final chatMessages = _messages
            .where((msg) => !msg.text.contains('正在') && !msg.text.contains('处理'))
            .map((msg) => AIPageChatMessage(
                  text: msg.text,
                  isUserMessage: msg.isUserMessage,
                ))
            .toList();

        // 从AiChatRepository导入的ChatMessage类型转换为deepseek_api中使用的ChatMessage类型
        final List<dynamic> convertedMessages = chatMessages.map((msg) => 
          {
            'content': msg.text, 
            'isUserMessage': msg.isUserMessage,
            'type': 'text'
          }).toList();

        // 调用后端AI生成行程 - 使用从历史中找到的目的地
        String planPrompt = "请为我规划一个${destinationFromHistory}行程";
        _aiGeneratedTripData = await _deepseekApi.generateTripPlan(planPrompt, convertedMessages);
        
        // 根据AI生成的数据构建ApiTripPlan对象
        _convertAiDataToTripPlan(_aiGeneratedTripData!);

        // 移除之前的处理消息
        setState(() {
          _messages.removeLast();
          // 添加AI响应
          _messages.add(AIPageChatMessage(
            text: _buildTripSummary(_aiGeneratedTripData!),
            isUserMessage: false,
            hasSuggestions: true,
            suggestions: ['看起来不错，采用这个方案并查看详情', '我想修改一下行程', '再生成一个不同的方案'],
          ));
        });

      } catch (e) {
        // 处理错误情况
        setState(() {
          _messages.removeLast(); // 移除处理中消息
          _messages.add(AIPageChatMessage(
            text: '抱歉，生成行程时遇到了问题：${e.toString()}\n您可以尝试重新请求或简化需求。',
            isUserMessage: false,
            hasSuggestions: true,
            suggestions: ['重试', '联系客服', '查看热门目的地'],
          ));
        });
      }

    } else if (userMessage.toLowerCase().contains('采用方案') || 
               userMessage.toLowerCase().contains('采用这个方案') || 
               userMessage.toLowerCase().contains('详细安排') || 
               userMessage.toLowerCase().contains('看起来不错') ||
               userMessage.toLowerCase().contains('用这个方案')) {
      if (!mounted) return;
      
      print('检测到采用方案指令: "$userMessage"');
      
      // 即使_aiGeneratedTripData为null，也检查消息历史中是否包含行程信息
      bool hasFoundTripInfo = false;
      String tripInfoMessage = '';
      
      // 反向遍历消息历史，查找包含行程信息的AI消息
      for (int i = _messages.length - 1; i >= 0; i--) {
        final msg = _messages[i];
        if (!msg.isUserMessage && 
            (msg.text.contains('行程概览') || 
             msg.text.contains('天行程') || 
             msg.text.contains('活动：'))) {
          hasFoundTripInfo = true;
          tripInfoMessage = msg.text;
          break;
        }
      }
      
      if (_aiGeneratedTripData == null && !hasFoundTripInfo) {
        setState(() {
          _messages.removeLast(); // 移除处理中消息
          _messages.add(AIPageChatMessage(
            text: '抱歉，我还没有为您生成行程方案。请先告诉我您想去哪里旅游？',
            isUserMessage: false,
            hasSuggestions: true,
            suggestions: ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅', '推荐欧洲10日游高性价比路线'],
          ));
        });
        return;
      }
      
      // 如果找到了行程信息但_aiGeneratedTripData为null，尝试创建默认行程
      if (_aiGeneratedTripData == null && hasFoundTripInfo) {
        _createDefaultTripFromMessage(tripInfoMessage);
        print('从历史消息中恢复行程数据');
      }
      
      // 添加用户反馈
      setState(() {
        _messages.add(AIPageChatMessage(text: '好的，正在为您创建详细的行程方案...', isUserMessage: false));
      });
      _scrollToBottom();
      
      // 调用统一的方法处理采用方案逻辑
      _handleAdoptTripPlan();
    } else {
      // 非行程规划相关的消息处理 - 使用后端AI处理
      // 移除"正在处理"消息
      if (_messages.isNotEmpty && !_messages.last.isUserMessage) {
        setState(() {
          _messages.removeLast();
        });
      }

      setState(() {
        _messages.add(AIPageChatMessage(
          text: '正在思考回答...',
          isUserMessage: false,
        ));
      });

      try {
        // 将聊天历史转换为API需要的格式
        final chatMessages = _messages
            .where((msg) => msg.text != '正在思考回答...' && msg.text != '正在处理您的请求...')
            .map((msg) => AIPageChatMessage(
                  text: msg.text,
                  isUserMessage: msg.isUserMessage,
                ))
            .toList();

        // 转换消息格式
        final List<dynamic> convertedMessages = chatMessages.map((msg) => 
          {
            'content': msg.text, 
            'isUserMessage': msg.isUserMessage,
            'type': 'text'
          }).toList();

        // 调用后端AI聊天接口
        final domain.ChatMessage aiResponse = await _deepseekApi.sendChatMessage(userMessage, convertedMessages);

        // 移除处理中的消息
        setState(() {
          _messages.removeLast();
          
          // 添加AI回复，将domain.ChatMessage转换为AIPageChatMessage
          _messages.add(AIPageChatMessage(
            text: aiResponse.content, // 使用API返回的content作为本地的text
            isUserMessage: false,
            hasSuggestions: aiResponse.suggestions != null && aiResponse.suggestions!.isNotEmpty,
            suggestions: aiResponse.suggestions,
          ));
        });
      } catch (e) {
        // 处理错误情况
    setState(() {
          _messages.removeLast(); // 移除处理中消息
          _messages.add(AIPageChatMessage(
            text: '抱歉，我无法回答这个问题：${e.toString()}',
        isUserMessage: false,
            hasSuggestions: true,
            suggestions: ['帮我规划行程', '推荐旅游目的地', '联系客服'],
      ));
        });
      }
    }
  }

  // 判断消息是否与行程规划相关
  bool _isMessageAboutTripPlanning(String message) {
    message = message.toLowerCase();
    return message.contains('规划') || 
           message.contains('行程') || 
           message.contains('旅游') && (message.contains('天') || message.contains('游')) ||
           message.contains('生成方案');
  }

  // 根据AI生成的数据构建ApiTripPlan对象
  void _convertAiDataToTripPlan(Map<String, dynamic> aiData) {
    // 确定起始日期和结束日期
    DateTime startDate = DateTime.now().add(const Duration(days: 30)); // 默认一个月后出发
    int days = 1; // 默认天数
    
    // 从AI数据中获取天数
    if (aiData.containsKey('days') && aiData['days'] is List && (aiData['days'] as List).isNotEmpty) {
      days = (aiData['days'] as List).length;
    }
    
    DateTime endDate = startDate.add(Duration(days: days - 1));
    
    // 创建ApiTripPlan对象
    _currentAiGeneratedPlan = ApiTripPlan(
      name: aiData['name'] ?? 'AI行程规划',
      origin: '用户当前城市', // TODO: 可以通过定位或用户配置获取
      destination: aiData['destination'] ?? '目的地',
      startDate: startDate,
      endDate: endDate,
      durationDays: days,
      tags: aiData['tags'] != null ? List<String>.from(aiData['tags']) : ['AI生成'],
      description: aiData['description'] ?? '这是由AI为您定制的行程计划，包含推荐景点、活动和用餐建议。',
      days: _convertAiDaysToPlanDays(aiData['days'] ?? []),
      isFeaturedOnMarket: false,
    );
  }

  // 将AI生成的天数数据转换为ApiPlanDay列表
  List<ApiPlanDay> _convertAiDaysToPlanDays(List<dynamic> aiDays) {
    List<ApiPlanDay> planDays = [];
    DateTime startDate = DateTime.now().add(const Duration(days: 30));
    
    print('转换AI天数数据，天数: ${aiDays.length}');
    
    for (int i = 0; i < aiDays.length; i++) {
      Map<String, dynamic> dayData = aiDays[i];
      DateTime dayDate = startDate.add(Duration(days: i));
      
      print('处理第${i+1}天数据: ${dayData['title'] ?? '未命名'}');
      
      List<ApiPlanActivity> activities = [];
      if (dayData['activities'] != null && dayData['activities'] is List) {
        print('活动数量: ${(dayData['activities'] as List).length}');
        for (var activity in dayData['activities']) {
          print('处理活动: ${activity['title'] ?? activity['description'] ?? '未命名活动'}');
          try {
            activities.add(ApiPlanActivity(
              id: activity['id'] ?? 'act_${i+1}_${activities.length + 1}',
              title: activity['title'] ?? activity['description'] ?? '未命名活动',
              description: activity['description'] ?? '',
              location: activity['location'] ?? '',
              address: activity['address'],
              startTime: activity['startTime'] ?? activity['time'] ?? '09:00',
              endTime: activity['endTime'] ?? _calculateEndTime(activity['startTime'] ?? activity['time'] ?? '09:00'),
              transportation: activity['transportation'] ?? '步行',
              durationMinutes: activity['durationMinutes'] is int ? activity['durationMinutes'] : null,
              type: activity['type'],
              estimatedCost: activity['estimatedCost'] is num 
                  ? (activity['estimatedCost'] as num).toDouble() 
                  : null,
              bookingInfo: activity['bookingInfo'],
              note: activity['note'],
              icon: activity['icon'],
            ));
            print('活动添加成功');
          } catch (e) {
            print('添加活动失败: ${e.toString()}');
            // 添加一个默认活动以避免崩溃
            activities.add(ApiPlanActivity(
              id: 'act_${i+1}_${activities.length + 1}',
              title: activity['title'] ?? '未命名活动',
              location: activity['location'] ?? '地点未定',
              startTime: '09:00',
              endTime: '11:00',
            ));
          }
        }
      } else {
        print('警告：第${i+1}天没有活动数据');
      }
      
      // 确保每天至少有一个活动
      if (activities.isEmpty) {
        print('添加默认活动，因为活动列表为空');
        activities.add(ApiPlanActivity(
          id: 'act_${i+1}_1',
          title: '参观景点',
          location: '${dayData['title'] ?? ''}景区',
          startTime: '09:00',
          endTime: '11:00',
        ));
      }
      
      try {
        planDays.add(ApiPlanDay(
          dayNumber: dayData['dayNumber'] ?? (i + 1),
          date: dayData['date'] != null && dayData['date'] != 'YYYY-MM-DD' 
              ? DateTime.tryParse(dayData['date']) ?? dayDate
              : dayDate,
          title: dayData['title'] ?? '第${i+1}天：探索之旅',
          description: dayData['description'] ?? '探索著名景点，体验当地文化',
          activities: activities,
          notes: dayData['notes'] ?? '享受美好的一天！',
        ));
        print('天数添加成功');
      } catch (e) {
        print('添加天数失败: ${e.toString()}');
      }
    }
    
    // 确保至少有一天行程
    if (planDays.isEmpty) {
      print('添加默认天数，因为planDays为空');
      DateTime defaultDate = startDate;
      planDays.add(ApiPlanDay(
        dayNumber: 1,
        date: defaultDate,
        title: '第1天：探索之旅',
        description: '开始您的精彩旅程',
        activities: [
          ApiPlanActivity(
            id: 'act_1_1',
            title: '参观景点',
            location: '主要景区',
            startTime: '09:00',
            endTime: '11:00',
          )
        ],
        notes: '默认生成的行程，请编辑完善',
      ));
    }
    
    return planDays;
  }

  // 计算活动的结束时间（简单实现：开始时间后2小时）
  String _calculateEndTime(String startTime) {
    try {
      // 解析时间字符串 "HH:MM"
      List<String> parts = startTime.split(':');
      if (parts.length != 2) return ''; // 格式不正确，返回空
      
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      
      // 增加2小时
      hour += 2;
      if (hour >= 24) hour -= 24; // 处理跨天情况
      
      // 格式化返回
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return ''; // 出错时返回空
    }
  }

  // 构建行程概要信息
  String _buildTripSummary(Map<String, dynamic> tripData) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('好的，为您规划${tripData['destination'] ?? '目的地'}行程如下：');
    buffer.writeln();
    
    // 添加行程名称
    buffer.writeln('📍 ${tripData['name'] ?? 'AI行程规划'}');
    
    // 添加标签
    if (tripData['tags'] != null && tripData['tags'] is List && (tripData['tags'] as List).isNotEmpty) {
      buffer.writeln('🏷️ 标签：${(tripData['tags'] as List).join('、')}');
    }
    
    // 添加天数
    if (tripData['days'] != null && tripData['days'] is List) {
      final days = tripData['days'] as List;
      buffer.writeln('⏱️ 行程天数：${days.length}天');
      buffer.writeln();
      buffer.writeln('📋 行程概览：');
      
      // 显示每天的主要安排
      for (int i = 0; i < days.length && i < 3; i++) { // 只显示前3天
        final day = days[i] as Map<String, dynamic>;
        buffer.writeln();
        buffer.writeln('📆 ${day['title'] ?? '第${day['dayNumber'] ?? (i+1)}天'}');
        
        if (day['activities'] != null && day['activities'] is List) {
          final activities = day['activities'] as List;
          for (int j = 0; j < activities.length && j < 3; j++) { // 每天只显示前3个活动
            final activity = activities[j] as Map<String, dynamic>;
            buffer.writeln('• ${activity['time'] ?? '时间未定'} ${activity['description'] ?? '活动'} @ ${activity['location'] ?? '地点未定'}');
          }
          
          if (activities.length > 3) {
            buffer.writeln('• ... 等${activities.length - 3}项活动');
          }
        }
      }
      
      if (days.length > 3) {
        buffer.writeln('\n... 等${days.length - 3}天行程');
      }
    }
    
    // 添加建议
    buffer.writeln();
    buffer.writeln('这个方案您觉得怎么样？');
    
    return buffer.toString();
  }

  // 从历史消息中找出最近提到的目的地
  String _findDestinationFromHistory() {
    // 常见旅游目的地列表
    final List<String> knownDestinations = [
      '北京', '上海', '广州', '深圳', '成都', '重庆', '西安', '杭州', 
      '南京', '武汉', '苏州', '天津', '青岛', '大连', '宁波', '厦门',
      '长沙', '福州', '济南', '合肥', '贵阳', '昆明', '南宁', '三亚',
      '海口', '哈尔滨', '长春', '沈阳', '兰州', '西宁', '太原', '石家庄',
      '郑州', '洛阳', '拉萨', '丽江', '大理', '桂林', '张家界', '九寨沟',
      '黄山', '泰山', '华山', '敦煌', '香格里拉', '乌镇', '凤凰古城',
      '西双版纳', '威海', '烟台', '珠海', '汕头', '中山', '日照'
    ];
    
    // 倒序遍历消息历史，查找最近提到的旅游目的地
    for (int i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      final text = msg.text.toLowerCase();
      
      // 查找文本中是否包含已知目的地
      for (String destination in knownDestinations) {
        if (text.contains(destination.toLowerCase())) {
          return destination;
        }
      }
      
      // 检查特定模式，如"去XX旅游"、"XX旅行"等
      final RegExp destRegExp = RegExp(r'去([\u4e00-\u9fa5]{2,8})旅游');
      final RegExp destRegExp2 = RegExp(r'([\u4e00-\u9fa5]{2,8})之旅');
      
      final matches = destRegExp.allMatches(text);
      if (matches.isNotEmpty) {
        final match = matches.first;
        if (match.groupCount >= 1) {
          return match.group(1) ?? '';
        }
      }
      
      final matches2 = destRegExp2.allMatches(text);
      if (matches2.isNotEmpty) {
        final match = matches2.first;
        if (match.groupCount >= 1) {
          return match.group(1) ?? '';
        }
      }
    }
    
    return ''; // 找不到目的地
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI智能规划'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _isProcessingAiPlan ? const LinearProgressIndicator() : Container(),
          const Divider(height: 1.0),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIPageChatMessage message) {
    final isUserMessage = message.isUserMessage;
    
    // 调试信息 - 在消息中查找关键内容
    if (!isUserMessage) {
      print("AI消息内容检查: ${message.text.contains('行程')} ${message.text.contains('概览')} ${_aiGeneratedTripData != null}");
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUserMessage) 
            const CircleAvatar(
              child: Text('AI'),
              backgroundColor: Colors.blue,
            ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
          Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUserMessage ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                // 检查AI消息是否包含行程信息
                if (!isUserMessage && !message.isUserMessage && 
                    (message.text.contains('行程') || message.text.contains('天行程') || message.text.contains('旅游')) && 
                    !message.text.contains('错误') && 
                    !message.text.contains('正在'))
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        print('采用方案按钮被点击');
                        // 如果点击时没有行程数据，先尝试检查一些可能的条件
                        if (_aiGeneratedTripData == null) {
                          print('警告：采用方案时_aiGeneratedTripData为空');
                          // 如果AI消息包含行程介绍等内容，表明可能已有方案
                          if (message.text.contains('行程概览') || 
                              message.text.contains('天行程') || 
                              message.text.contains('活动：')) {
                            // 尝试从消息中提取的行程信息创建一个默认行程
                            _createDefaultTripFromMessage(message.text);
                          }
                        }
                        _handleAdoptTripPlan();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('采用此方案'),
                    ),
                  ),
                if (message.hasSuggestions && message.suggestions != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: isUserMessage ? WrapAlignment.end : WrapAlignment.start,
                      children: message.suggestions!.map((suggestion) {
                        return InkWell(
                          onTap: () {
                            _textController.text = suggestion;
                            _handleSubmitted(suggestion);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(suggestion),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          if (isUserMessage) 
            const CircleAvatar(
              child: Text('用户'),
              backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
          Expanded(
              child: TextField(
                controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration(hintText: '请输入您的行程需求...'),
            ),
                ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                _handleSubmitted(_textController.text);
              }
            },
            ),
          ],
      ),
    );
  }

  // 处理建议被选中时的逻辑
  Future<void> _handleSuggestionSelected(String suggestion) async {
    // 将建议作为用户输入发送
    _handleSubmitted(suggestion);
  }
  
  // 处理手动点击"采用方案"按钮的逻辑
  Future<void> _handleAdoptTripPlan() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    // 查找最近一个非用户消息作为AI生成的行程
    String? aiGeneratedTripText;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUserMessage) {
        aiGeneratedTripText = _messages[i].text;
        break;
      }
    }
    
    // 如果没有找到AI生成文本，或者没有解析出行程方案
    if (aiGeneratedTripText == null) {
      messenger.showSnackBar(const SnackBar(content: Text('没有可用的行程方案，请先生成行程')));
      return;
    }
    
    setState(() { _isProcessingAiPlan = true; });
    print('开始采用AI生成方案流程');
    
    // 在界面上显示处理消息
    setState(() {
      _messages.add(AIPageChatMessage(
        text: '正在处理并保存您的行程，请稍候...',
        isUserMessage: false,
      ));
    });
    
    try {
      // 使用新增的方法直接从AI文本创建用户行程
      final ApiUserTrip createdUserTrip = await _apiService.createUserTripFromAiGenerated(aiGeneratedTripText);

      print('用户行程创建成功, ID: ${createdUserTrip.id}, 天数: ${createdUserTrip.days.length}');
      print("AI生成的行程数据: $aiGeneratedTripText");

      // 确认创建的天数
      String daysInfo = '';
      if (createdUserTrip.days.isNotEmpty) {
        daysInfo = '已创建 ${createdUserTrip.days.length} 天行程';
      }

      // 设置处理完成
      setState(() { 
        _isProcessingAiPlan = false; 
        
        // 移除之前的处理消息
        if (_messages.last.text.contains('正在处理并保存')) {
          _messages.removeLast();
        }
        
        // 添加成功消息
        _messages.add(AIPageChatMessage(
          text: '您的行程已创建成功！$daysInfo。现在将进入编辑模式，您可以进一步调整行程细节。',
          isUserMessage: false
        ));
      });

      // 给用户一个反馈
      messenger.showSnackBar(SnackBar(
        content: Text('行程已成功创建！$daysInfo'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ));
      
      // 短暂延迟以确保用户能看到成功消息
      await Future.delayed(const Duration(seconds: 1));
      
      // 使用 MaterialPageRoute 导航到行程详情页
      if (mounted) { // 检查widget是否还挂载在树上
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => TripDetailPage(userTripId: createdUserTrip.id),
          ),
        );
      }
    } catch (e) {
      setState(() { _isProcessingAiPlan = false; });
      print('采用方案失败: $e');
      
      // 移除之前的处理消息
      if (_messages.last.text.contains('正在处理并保存')) {
        _messages.removeLast();
      }
      
      messenger.showSnackBar(SnackBar(
        content: Text('创建行程失败: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
      
      // 添加一条错误消息
      setState(() {
        _messages.add(AIPageChatMessage(
          text: '抱歉，创建行程时出现了问题，请重试。错误信息: ${e.toString()}',
          isUserMessage: false,
        ));
      });
    }
  }

  // 从消息文本尝试创建一个基础行程
  void _createDefaultTripFromMessage(String messageText) {
    print('尝试从消息创建默认行程数据');
    
    // 尝试提取目的地
    String destination = '';
    final destRegex = RegExp(r'([\u4e00-\u9fa5]{2,4})行程');
    final destMatch = destRegex.firstMatch(messageText);
    if (destMatch != null && destMatch.groupCount >= 1) {
      destination = destMatch.group(1) ?? '';
    }
    
    // 如果没找到，尝试其他模式
    if (destination.isEmpty) {
      final commonCities = ['北京', '上海', '广州', '深圳', '成都', '重庆', '西安', '杭州', '南京', '武汉', '兰州', '三亚'];
      for (final city in commonCities) {
        if (messageText.contains(city)) {
          destination = city;
          break;
        }
      }
    }
    
    // 如果仍然没有目的地，使用默认值
    if (destination.isEmpty) {
      destination = '未知目的地';
    }
    
    // 创建一个临时行程数据
    _aiGeneratedTripData = {
      'name': '$destination行程',
      'destination': destination,
      'tags': ['AI生成'],
      'days': [
        {
          'dayNumber': 1,
          'title': '第1天：$destination探索之旅',
          'description': '探索$destination著名景点',
          'activities': [
            {
              'id': 'act1_1',
              'title': '景点参观',
              'description': '参观$destination著名景点',
              'location': '$destination景区',
              'startTime': '09:00',
              'endTime': '11:00'
            }
          ]
        }
      ]
    };
    
    // 转换为ApiTripPlan对象
    _convertAiDataToTripPlan(_aiGeneratedTripData!);
    print('已创建默认行程数据：${_aiGeneratedTripData!['name']}');
  }
}
// lib/ai/presentation/pages/ai_planner_page.dart
import 'package:flutter/material.dart';
// *** 修改点：导入新的 trip_detail_page.dart ***
import '../../../trips/presentation/viewmodels/trip_detail_viewmodel.dart'; // 确保路径正确
import '../../../trips/presentation/pages/trip_detail_page.dart'; // 确保路径正确
import 'dart:math'; // 用于生成随机ID (如果需要为新行程生成ID)


// ChatMessage 类定义保持不变
class ChatMessage {
  final String text;
  final bool isUserMessage;
  final bool hasSuggestions;
  final List<String>? suggestions;

  ChatMessage({
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
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addInitialAiMessage();
  }

  void _addInitialAiMessage() {
    setState(() {
      _messages.add(ChatMessage(
          text: '您好！我是您的AI旅行助手“途乐乐”，想去哪里？可以告诉我您的目的地、预算、兴趣和时间，我会为您规划行程。',
          isUserMessage: false,
          hasSuggestions: true,
          suggestions: ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅', '推荐欧洲10日游高性价比路线']
      ));
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true));
      _addAiResponse(text);
    });
    _scrollToBottom();
  }

  void _addAiResponse(String userMessage) {
    String aiTextResponse;
    bool hasSuggestions = false;
    List<String>? suggestions;
    bool showPlanButtons = false;

    // 模拟的行程数据，当AI“生成”方案时会用到
    Map<String, dynamic> mockTripDataForEditor = {
      'name': 'AI规划的行程', // 默认名称，可以从对话中提取
      'destination': '未知', // 可以从对话中提取
      'tags': <String>[], // 可以从对话中提取
      'days': [
        // AI应该填充更具体的每日活动
        {
          'dayNumber': 1,
          'date': DateTime.now(),
          'title': '${DateTime.now().month}月${DateTime.now().day}日 (AI规划)',
          'activities': [
            {'id': 'ai_act1_${Random().nextInt(100)}', 'time': '上午', 'description': 'AI推荐活动1', 'location': 'AI推荐地点1'},
            {'id': 'ai_act2_${Random().nextInt(100)}', 'time': '下午', 'description': 'AI推荐活动2', 'location': 'AI推荐地点2'},
          ],
          'notes': '这是AI为您初步规划的行程，您可以在编辑页面进行调整。'
        }
      ]
    };

    if (userMessage.contains('三亚') && userMessage.contains('亲子')) {
      aiTextResponse = '好的，为您规划三亚5日亲子度假推荐：\n'
          ' • 住宿: 三亚海棠湾喜来登度假酒店(亲子主题房)\n'
          ' • 必玩景点: 亚龙湾沙滩、天涯海角、蜈支洲岛\n'
          ' • 特色体验: 亲子潜水、沙滩城堡建造、海洋馆\n'
          ' • 预算分配: 住宿¥7000, 餐饮¥3000, 景点及体验¥4000, 交通¥1000\n\n'
          '这个方案您觉得怎么样？';
      hasSuggestions = true;
      suggestions = ['看起来不错，详细安排一下每天的行程', '修改预算', '换个酒店推荐'];
      showPlanButtons = true;
      // 更新模拟数据
      mockTripDataForEditor['name'] = 'AI规划的三亚亲子游';
      mockTripDataForEditor['destination'] = '三亚';
      (mockTripDataForEditor['tags'] as List<String>).addAll(['亲子', '海岛度假']);
      // 可以更细化mockTripDataForEditor['days']的内容
      mockTripDataForEditor['days'] = [
        {
          'dayNumber': 1, 'date': DateTime.now(), 'title': '抵达与海滩',
          'activities': [
            {'id': 'sanya_act1_${Random().nextInt(100)}', 'time': '09:00', 'description': '抵达三亚，前往酒店'},
            {'id': 'sanya_act2_${Random().nextInt(100)}', 'time': '14:00', 'description': '亚龙湾沙滩'},
          ], 'notes': '享受阳光沙滩！'
        },
        {
          'dayNumber': 2, 'date': DateTime.now().add(const Duration(days:1)), 'title': '海岛探索',
          'activities': [
            {'id': 'sanya_act3_${Random().nextInt(100)}', 'time': '10:00', 'description': '蜈支洲岛一日游'},
            {'id': 'sanya_act4_${Random().nextInt(100)}', 'time': '18:00', 'description': '品尝当地海鲜'},
          ], 'notes': '注意防晒和补水。'
        }
        // 可以按需添加更多天数
      ];


    } else if (userMessage.contains('详细安排') || userMessage.contains('采用方案')) { // 包含采用方案的逻辑
      aiTextResponse = '好的，我这就为您生成详细的行程计划，您可以稍后在编辑页面进行调整。';

      final String newTripId = 'ai_trip_${DateTime.now().millisecondsSinceEpoch}';

      // 模拟用户确认后，准备跳转到行程详情页的编辑模式
      Future.delayed(const Duration(milliseconds: 500), () { // 短暂延迟模拟AI处理
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => TripDetailPage(
                tripId: newTripId, // 传递新生成的ID
                initialMode: TripMode.edit, // 以编辑模式打开
                newTripInitialData: mockTripDataForEditor, // 传递AI生成的初始数据
              )
          ),
        );
      });

    } else if (userMessage.toLowerCase().contains('hello') || userMessage.toLowerCase().contains('你好')) {
      aiTextResponse = '您好！有什么可以帮您规划的吗？';
      hasSuggestions = true;
      suggestions = ['我想去云南', '国内游推荐', '出境游有啥好玩的'];
    } else {
      aiTextResponse = '正在理解您说的“$userMessage”... 我还在学习中，您可以尝试换一种问法，或者直接告诉我目的地、天数和偏好。';
      hasSuggestions = true;
      suggestions = ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅'];
    }

    setState(() {
      _messages.add(ChatMessage(
        text: aiTextResponse,
        isUserMessage: false,
        hasSuggestions: hasSuggestions,
        suggestions: suggestions,
      ));
      if (showPlanButtons) {
        _messages.add(ChatMessage(text: "_PLAN_BUTTONS_", isUserMessage: false));
      }
    });
  }

  void _scrollToBottom() {
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

  Widget _buildMessage(ChatMessage message) {
    final align = message.isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = message.isUserMessage ? Theme.of(context).primaryColor : Colors.white;
    final textColor = message.isUserMessage ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final radius = message.isUserMessage
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    )
        : const BorderRadius.only(
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    if (message.text == "_PLAN_BUTTONS_") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end, // 按钮也靠右，因为是AI回复后的操作
          children: [
            TextButton(
              onPressed: () {
                _handleSubmitted("采用方案"); // 触发采用方案的逻辑
              },
              child: const Text('采用方案'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                _handleSubmitted("我想修改方案");
              },
              child: const Text('修改方案'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(message.text, style: TextStyle(color: textColor, fontSize: 16)),
        ),
        if (message.hasSuggestions && message.suggestions != null && message.suggestions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: message.isUserMessage ? WrapAlignment.end : WrapAlignment.start,
              children: message.suggestions!.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () {
                    _handleSubmitted(suggestion);
                  },
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5))
                  ),
                );
              }).toList(),
            ),
          )
      ],
    );
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
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).hintColor), // 使用主题强调色
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
            color: Colors.white, // 输入框背景白色
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
        ),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: '请输入您的需求...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16),
                minLines: 1,
                maxLines: 5, // 允许多行输入
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor), // 发送按钮用主题色
                  onPressed: () => _handleSubmitted(_textController.text)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
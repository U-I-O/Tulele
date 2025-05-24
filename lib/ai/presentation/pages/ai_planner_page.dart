// lib/ai_planner_page.dart (新建)
import 'package:flutter/material.dart';
import '../trips/itinerary_editor_page.dart'; // 引入行程编辑页面

// 模拟消息模型
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
      // 模拟AI回复
      _addAiResponse(text);
    });
    _scrollToBottom();
  }

  void _addAiResponse(String userMessage) {
    // 简单的模拟AI回复逻辑
    String aiTextResponse;
    bool hasSuggestions = false;
    List<String>? suggestions;
    bool showPlanButtons = false;

    if (userMessage.contains('三亚') && userMessage.contains('亲子')) {
      aiTextResponse = '好的，为您规划三亚5日亲子度假推荐：\n'
          ' • 住宿: 三亚海棠湾喜来登度假酒店(亲子主题房)\n'
          ' • 必玩景点: 亚龙湾沙滩、天涯海角、蜈支洲岛\n'
          ' • 特色体验: 亲子潜水、沙滩城堡建造、海洋馆\n'
          ' • 预算分配: 住宿¥7000, 餐饮¥3000, 景点及体验¥4000, 交通¥1000\n\n'
          '这个方案您觉得怎么样？';
      hasSuggestions = true;
      suggestions = ['看起来不错，详细安排一下每天的行程', '修改预算', '换个酒店推荐'];
      showPlanButtons = true; // 显示“采用方案”和“修改方案”
    } else if (userMessage.contains('详细安排')) {
      aiTextResponse = '好的，我这就为您详细规划每一天的行程安排... (此处将生成详细日程)';
      // 实际应用中，这里会生成更详细的日程数据
      // 为了演示，我们直接导航到编辑页，并传递一个模拟的行程名称
      Future.delayed(const Duration(seconds: 1), () {
        final mockTripData = {
          'name': 'AI规划的三亚亲子游',
          // 其他信息可以从之前的对话中提取或让用户在编辑页补充
          'destination': '三亚',
          'tags': ['亲子', '海岛度假'],
          'days': [
            {
              'dayNumber': 1, 'date': DateTime.now(), 'title': '${DateTime.now().month}月${DateTime.now().day}日, 星期X',
              'activities': [
                {'time': '09:00', 'description': '抵达三亚，前往酒店'},
                {'time': '14:00', 'description': '亚龙湾沙滩'},
              ]
            },
            {
              'dayNumber': 2, 'date': DateTime.now().add(const Duration(days:1)), 'title': '${DateTime.now().add(const Duration(days:1)).month}月${DateTime.now().add(const Duration(days:1)).day}日, 星期Y',
              'activities': [
                {'time': '10:00', 'description': '蜈支洲岛'},
                {'time': '18:00', 'description': '海鲜晚餐'},
              ]
            }
          ]
        };
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ItineraryEditorPage(tripData: mockTripData)),
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
        _messages.add(ChatMessage(text: "_PLAN_BUTTONS_", isUserMessage: false)); // 特殊标记用于显示按钮
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                // 导航到编辑页面，并传递AI生成的初步方案
                // 此处为模拟，实际应从AI获取更完整的方案数据
                final mockTripData = {
                  'name': 'AI规划的三亚亲子游',
                  'destination': '三亚',
                  'tags': ['亲子', '海岛度假'],
                  // ... 更多AI生成的行程数据
                  'days': [
                    {
                      'dayNumber': 1, 'date': DateTime.now(), 'title': '${DateTime.now().month}月${DateTime.now().day}日, 星期X',
                      'activities': [
                        {'time': '09:00', 'description': '抵达三亚，前往酒店'},
                        {'time': '14:00', 'description': '亚龙湾沙滩'},
                      ]
                    },
                    // ...更多天数
                  ]
                };
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ItineraryEditorPage(tripData: mockTripData)),
                );
              },
              child: const Text('采用方案'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                // 触发修改逻辑，比如让用户重新输入或选择修改点
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
              alignment: WrapAlignment.start, // AI建议靠左
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
      data: IconThemeData(color: Theme.of(context).hintColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
            color: Colors.white,
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
                maxLines: 5,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
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
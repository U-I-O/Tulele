import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewAiPlannerPage extends StatefulWidget {
  const NewAiPlannerPage({super.key});

  @override
  State<NewAiPlannerPage> createState() => _NewAiPlannerPageState();
}

class _NewAiPlannerPageState extends State<NewAiPlannerPage> {
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
          text: '欢迎使用新的AI旅行助手！请告诉我您的目的地、预算、兴趣和时间，我会为您规划行程。',
          isUserMessage: false,
          hasSuggestions: true,
          suggestions: ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅', '推荐欧洲10日游高性价比路线']));
    });
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true));
    });
    _scrollToBottom();

    final response = await http.post(
      Uri.parse('https://api.deepseek.com/v1/planner'),
      headers: {'Authorization': 'Bearer xXXXXXXXXXXXXXXXXXX'},
      body: json.encode({'query': text}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _addAiResponse(data['response']);
    } else {
      _addAiResponse('抱歉，我无法处理您的请求。请稍后再试。');
    }
  }

  void _addAiResponse(String aiTextResponse) {
    setState(() {
      _messages.add(ChatMessage(
        text: aiTextResponse,
        isUserMessage: false,
        hasSuggestions: false,
      ));
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新AI智能规划'),
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
            ]),
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

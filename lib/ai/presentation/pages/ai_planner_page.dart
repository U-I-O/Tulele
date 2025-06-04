// lib/ai/presentation/pages/ai_planner_page.dart
import 'package:flutter/material.dart';
// *** 修改点：导入新的 trip_detail_page.dart ***
import '../../../trips/presentation/pages/trip_detail_page.dart'; // 确保路径正确
import 'dart:math'; // 用于生成随机ID (如果需要为新行程生成ID)
import '../../domain/entities/chat_message.dart';
import '../viewmodels/ai_chat_viewmodel.dart';
import '../../data/datasources/deepseek_api.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/generate_trip_plan_usecase.dart';
import '../../domain/usecases/modify_trip_plan_usecase.dart';
import 'dart:convert';
import '../../../core/di/service_locator.dart';


class AiPlannerPage extends StatefulWidget {
  const AiPlannerPage({super.key});

  @override
  State<AiPlannerPage> createState() => _AiPlannerPageState();
}

class _AiPlannerPageState extends State<AiPlannerPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AiChatViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    
    // 从依赖注入获取ViewModel
    _viewModel = serviceLocator<AiChatViewModel>();
    
    // 监听ViewModel的变化以更新UI
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    
    // 发送消息到ViewModel
    _viewModel.sendMessage(text).then((_) {
      _scrollToBottom();
    });
  }

  void _adoptCurrentPlan() {
    final tripPlan = _viewModel.adoptCurrentPlan();
    if (tripPlan != null) {
      // 创建新的行程ID
      final String newTripId = 'ai_trip_${DateTime.now().millisecondsSinceEpoch}';
      
      // 处理日期格式 - 如果日期是字符串格式，转换为DateTime对象
      Map<String, dynamic> processedPlan = Map.from(tripPlan);
      if (processedPlan['days'] != null) {
        List<Map<String, dynamic>> processedDays = [];
        for (var day in processedPlan['days']) {
          Map<String, dynamic> processedDay = Map.from(day);
          // 如果日期是字符串，转换为DateTime
          if (day['date'] is String) {
            try {
              processedDay['date'] = DateTime.parse(day['date']);
            } catch (e) {
              // 如果解析失败，使用当前日期加上day number的偏移
              processedDay['date'] = DateTime.now().add(Duration(days: day['dayNumber'] - 1));
            }
          }
          processedDays.add(processedDay);
        }
        processedPlan['days'] = processedDays;
      }
      
      // 导航到详情页，以编辑模式打开
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TripDetailPage(
            tripId: newTripId,
            initialMode: TripMode.edit,
            newTripInitialData: processedPlan,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法创建行程，请重试')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI智能规划'),
        centerTitle: true,
        actions: [
          // 添加重置按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('重置对话'),
                  content: const Text('确定要清空当前对话记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _viewModel.reset();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _viewModel.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _viewModel.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_viewModel.messages[index]);
                    },
                  ),
          ),
          // 加载状态提示，显示更细粒度的加载信息
          if (_viewModel.isLoading) 
            Column(
              children: [
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
                if (_viewModel.loadingStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _viewModel.loadingStatus,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '开始与AI助手对话',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '询问旅游目的地、规划行程或寻找旅行灵感',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildQuickSuggestions(),
        ],
      ),
    );
  }
  
  // 添加快速提示按钮
  Widget _buildQuickSuggestions() {
    return Column(
      children: [
        Text(
          '试试这些：',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildSuggestionChip('帮我规划北京周末文化之旅', Icons.history_edu),
            _buildSuggestionChip('三亚5日游，亲子游', Icons.beach_access),
            _buildSuggestionChip('上海3天购物美食游', Icons.shopping_bag),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSuggestionChip(String text, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Theme.of(context).primaryColor),
      label: Text(text),
      labelStyle: TextStyle(color: Theme.of(context).primaryColor),
      backgroundColor: Colors.grey[100],
      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      onPressed: () => _handleSubmitted(text),
    );
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
          
    // 处理按钮消息类型
    if (message.type == ChatMessageType.buttons) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _adoptCurrentPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('采用方案'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                _handleSubmitted("我想修改这个方案");
              },
              child: const Text('修改方案'),
            ),
          ],
        ),
      );
    }
    
    // 处理行程建议消息类型
    if (message.type == ChatMessageType.planSuggestion) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 行程头部
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.map, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "行程规划",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 行程内容
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            
            // 建议按钮
            if (message.suggestions != null && message.suggestions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
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
                          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5))),
                    );
                  }).toList(),
                ),
              ),
            
            // 底部操作按钮区域
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('编辑'),
                    onPressed: () {
                      _adoptCurrentPlan();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(Icons.check_circle, size: 18, color: Theme.of(context).primaryColor),
                    label: Text('采用方案', style: TextStyle(color: Theme.of(context).primaryColor)),
                    onPressed: _adoptCurrentPlan,
                  ),
                ],
              ),
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
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Text(
            message.content,
            style: TextStyle(color: textColor, fontSize: 16),
          ),
        ),
        if (message.suggestions != null && message.suggestions!.isNotEmpty)
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
                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5))),
                );
              }).toList(),
            ),
          )
      ],
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
                  hintText: '请输入您的旅游问题或需求...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16),
                minLines: 1,
                maxLines: 5,
                enabled: !_viewModel.isLoading, // 加载时禁用输入
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: _viewModel.isLoading
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
                onPressed: _viewModel.isLoading
                    ? null
                    : () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
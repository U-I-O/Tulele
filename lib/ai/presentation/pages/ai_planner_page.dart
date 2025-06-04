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

  final ApiService _apiService = ApiService(); // 新增 ApiService 实例
  bool _isProcessingAiPlan = false;            // 新增 (防止重复处理)

  // 用于暂存AI生成的计划，以便用户确认后创建
  ApiTripPlan _currentAiGeneratedPlan = ApiTripPlan(
    name: 'AI待规划行程',
    tags: [],
    days: [],
    startDate: DateTime.now(),
    endDate: DateTime.now(),
  );


  @override
  void initState() {
    super.initState();
    _addInitialAiMessage();
  }

  void _addInitialAiMessage() {
    // 确保 widget 仍然挂载
    if (!mounted) return;
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

    // 确保 widget 仍然挂载
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true));
    });
    _addAiResponse(text); // 调用异步方法
    _scrollToBottom();
  }

  void _addAiResponse(String userMessage) async {
    if (_isProcessingAiPlan) return;

    String aiTextResponse;
    bool hasSuggestions = false;
    List<String>? suggestions;
    bool showPlanButtons = false;

    // 模拟AI生成方案的示例
    if (userMessage.contains('三亚') && userMessage.contains('亲子')) {
      aiTextResponse = '好的，为您规划三亚5日亲子度假推荐：\n'
          ' • 住宿: 三亚海棠湾亚特兰蒂斯酒店(海景房)\n' // 更改一个酒店示例
          ' • 必玩景点: 亚特兰蒂斯水世界、蜈支洲岛、南山文化旅游区\n'
          ' • 特色体验: 海豚互动、免税店购物\n'
          ' • 预算分配: 住宿¥8000, 餐饮¥3500, 景点及体验¥5000, 交通¥1500\n\n'
          '这个方案您觉得怎么样？';
      hasSuggestions = true;
      suggestions = ['看起来不错，采用这个方案并查看详情', '预算太高了，能调整吗？', '换个时间可以吗？'];
      showPlanButtons = true;

      // 更新 _currentAiGeneratedPlan 以匹配AI的回复 (使用新设计的 TripPlan 字段)
      DateTime aiStartDate = DateTime.now().add(const Duration(days: 30)); // 假设一个月后出发
      DateTime aiEndDate = aiStartDate.add(const Duration(days: 4));    // 5天4晚

      _currentAiGeneratedPlan = ApiTripPlan(
        // id: null, // ID由后端生成
        name: 'AI规划的三亚5日亲子豪华游', // 对应 TripPlan.name
        // creatorId 在调用 createNewTripPlan 前设置
        // creatorName 由后端填充或从 AuthUtils 获取
        origin: '用户当前城市', // 对应 TripPlan.origin (TODO: 实际应获取)
        destination: '海南三亚',  // 对应 TripPlan.destination
        startDate: aiStartDate, // 对应 TripPlan.startDate
        endDate: aiEndDate,     // 对应 TripPlan.endDate
        durationDays: aiEndDate.difference(aiStartDate).inDays + 1, // 对应 TripPlan.duration_days
        tags: ['亲子', '海岛', '豪华体验', 'AI生成'], // 对应 TripPlan.tags
        description: 'AI为您精心策划的三亚5日亲子豪华度假之旅，包含亚特兰蒂斯住宿、水世界畅玩及热门景点。', // 对应 TripPlan.description
        coverImage: 'https://images.unsplash.com/photo-1610045436880-c52903mba3a1?auto=format&fit=crop&w=800&q=60', // 示例封面
        days: [ // 对应 TripPlan.days
          ApiPlanDay(
            dayNumber: 1,
            title: "抵达三亚，入住亚特兰蒂斯", // 对应 TripPlan.days.title
            date: aiStartDate, // 对应 TripPlan.days.date (可选，如果 daily_date 也需要)
            description: "开启梦幻之旅的第一天。", // 对应 TripPlan.days.description
            activities: [ // 对应 TripPlan.days.activities
              ApiPlanActivity(
                  // activity_id: null, // 模板活动的ID，后端生成或不在此阶段关心
                  title: '抵达三亚，专车接送至亚特兰蒂斯酒店',
                  location: '亚特兰蒂斯酒店', // 对应 location_name
                  startTime: '14:00',
                  type: 'transportation' // 对应 TripPlan.days.activities.type
              ),
              ApiPlanActivity(title: '酒店办理入住，稍作休息', location: '亚特兰蒂斯酒店', startTime: '15:00', type: 'hotel'),
              ApiPlanActivity(title: '失落的空间水族馆参观', location: '亚特兰蒂斯酒店内', startTime: '16:30', durationMinutes: 90, type: 'sightseeing')
            ],
            notes: '首日建议轻松安排，熟悉酒店环境。' // 对应 TripPlan.days.daily_notes
          ),
          ApiPlanDay(dayNumber: 2, title: "水世界狂欢", date: aiStartDate.add(const Duration(days: 1)), activities: [
            ApiPlanActivity(title: '亚特兰蒂斯水世界全天畅玩', location: '亚特兰蒂斯水世界', startTime: '10:00', endTime: '18:00', type: 'amusement_park')
          ]),
          // ... (可以继续添加更多天的详细安排) ...
        ],
        platformPrice: null, // 初始创建时，平台价格待定
        averageRating: null,
        reviewCount: 0,
        salesVolume: 0,
        usageCount: 0,
        // estimatedCostRange: "15000-20000元/家庭", // 如果AI能预估
        // suitability: ["家庭亲子", "高端度假"],
        // highlights: ["亚特兰蒂斯住宿", "水世界无限畅玩"],
        isFeaturedOnMarket: false, // 默认不精选
        // version: 1
      );

    } else if (userMessage.contains('采用这个方案并查看详情') || userMessage.contains('详细安排') || userMessage.contains('采用方案')) {
      if (!mounted) return;
      setState(() { _isProcessingAiPlan = true; });
      if (mounted) { // 显示处理中消息
        setState(() {
          _messages.add(ChatMessage(text: '好的，正在为您创建详细的行程方案...', isUserMessage: false));
        });
        _scrollToBottom();
      }

      final messenger = ScaffoldMessenger.of(context);

      try {
        final currentUserId = await AuthUtils.getCurrentUserId();
        if (currentUserId == null) {
          throw Exception("用户未登录，无法创建行程。");
        }
        // final String currentUsername = await AuthUtils.getCurrentUsername() ?? "途乐乐用户"; // 尝试获取真实用户名
        // final String? currentUserAvatar = await AuthUtils.getCurrentUserAvatar();

        // 1. 创建 TripPlan (使用已填充的 _currentAiGeneratedPlan)
        _currentAiGeneratedPlan.creatorId = currentUserId; // AI生成的模板计划，创建者可以是当前用户或系统账户
                                                        // 如果归属用户，则用户可以在“我的模板”中管理它
                                                        // 如果归属系统，则 currentUserId 应为 system_admin_id

        final ApiTripPlan createdTripPlan = await _apiService.createNewTripPlan(_currentAiGeneratedPlan);
        if (!mounted) { setState(() { _isProcessingAiPlan = false; }); return; }

        if (createdTripPlan.id == null) {
          throw Exception("后台创建旅行计划模板失败，未返回计划ID。");
        }

        // 2. 准备创建 UserTrip 的数据 (参照新的 userTrips 字段设计)
        final newUserTripPayload = {
          "plan_id": createdTripPlan.id!, // **核心关联**
          "creator_id": currentUserId,     // **UserTrip的创建者是当前用户**
          // "creator_name": currentUsername, // 后端应根据 creator_id 自动填充
          // "creator_avatar": currentUserAvatar, // 后端应根据 creator_id 自动填充
          "user_trip_name_override": createdTripPlan.name, // 用户可覆盖的名称，初始与模板名一致

          // UserTrip 自身的行程核心信息 (从采纳的 TripPlan 复制过来作为初始值)
          "origin": createdTripPlan.origin,
          "destination": createdTripPlan.destination,
          "startDate": createdTripPlan.startDate?.toIso8601String().substring(0,10),
          "endDate": createdTripPlan.endDate?.toIso8601String().substring(0,10),
          "tags": createdTripPlan.tags,
          "description": createdTripPlan.description, // UserTrip 实例的描述
          "coverImage": createdTripPlan.coverImage,   // UserTrip 实例的封面图 (初始可与模板一致)
          
          // UserTrip 的 days 结构 (从 TripPlan.days 转换)
          "days": createdTripPlan.days.map((planDay) {
            return {
              "day_number": planDay.dayNumber,
              "date": planDay.date?.toIso8601String().substring(0,10), // 实际日期
              "title": planDay.title,               // 当日主题 (用户可改)
              "description": planDay.description,   // 当日描述 (用户可改)
              "activities": planDay.activities.map((planActivity) {
                return {
                  // "user_activity_id": null, // 由后端生成
                  "original_plan_activity_id": planActivity.id, // 引用模板活动的 activity_id
                  "title": planActivity.title,
                  "location_name": planActivity.location, // 对应 userTrips.days.activities.location_name
                  "address": null, // 可选
                  "coordinates": null, // 可选
                  "start_time": planActivity.startTime,
                  "end_time": planActivity.endTime,
                  "duration_minutes": planActivity.durationMinutes,
                  "type": planActivity.type,
                  "actual_cost": null, // 初始无实际花费
                  "booking_info": null,
                  "user_activity_notes": planActivity.note, // 模板备注作为初始用户备注
                  "user_status": "todo", // 用户感知的活动状态
                  "icon": planActivity.icon,
                };
              }).toList(),
              "user_daily_notes": planDay.notes, // 模板每日备注作为用户每日笔记初始值
            };
          }).toList(),
          
          "members": [{"userId": currentUserId, "role": "owner" /* , "joined_at": DateTime.now().toIso8601String() -> 由后端处理更佳 */}],
          "messages": [],
          "tickets": [],
          "user_notes": [], // 行程级用户笔记
          "publish_status": "draft", // 新创建的 UserTrip 默认为草稿
          "travel_status": "planning", // 默认为计划中
          // "user_personal_rating": null, // 初始化时为空
          // "user_personal_review": null, // 初始化时为空
          // "submission_notes_to_admin": null,
          // "admin_feedback_on_review": null,
        };

        // 3. 调用API创建 UserTrip
        final ApiUserTrip createdUserTrip = await _apiService.createUserTrip(newUserTripPayload);
        if (!mounted) { setState(() { _isProcessingAiPlan = false; }); return; }

        if (mounted) setState(() { _isProcessingAiPlan = false; });
        
        messenger.showSnackBar(
          SnackBar(content: Text('行程 "${createdUserTrip.userTripNameOverride}" 已创建！正在跳转...'), backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(seconds: 1));

        // 4. 导航到 TripDetailPage
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => TripDetailPage(
                userTripId: createdUserTrip.id,
              )
          ),
        );
        return;

      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.length > 150) { // 避免SnackBar过长
            errorMessage = "${errorMessage.substring(0,147)}...";
          }
          messenger.showSnackBar(
            SnackBar(content: Text('创建行程时遇到问题: $errorMessage', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
          );
          setState(() { _isProcessingAiPlan = false; });
        }
        return; // 确保出错时也返回
      }
    } else if (userMessage.toLowerCase().contains('hello') || userMessage.toLowerCase().contains('你好')) {
      aiTextResponse = '您好！有什么可以帮您规划的吗？';
      hasSuggestions = true;
      suggestions = ['我想去云南', '国内游推荐', '出境游有啥好玩的'];
    } else {
      aiTextResponse = '正在努力理解您的需求：“$userMessage”... \n我还在学习中，您可以尝试换一种问法，或者明确告诉我您的目的地、出行天数、预算和旅行偏好（比如：亲子、美食、探险等）。';
      hasSuggestions = true;
      suggestions = ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅', '我下周有3天假期，预算3000，想去个安静的地方放松'];
    }

    // 确保 widget 仍然挂载
    if (!mounted) return;
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
    _scrollToBottom();
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
              onPressed: _isProcessingAiPlan ? null : () { // 处理中则禁用按钮
                _handleSubmitted("采用这个方案并查看详情"); // 触发采用方案的逻辑
              },
              child: _isProcessingAiPlan && (_messages.last.text.contains("正在为您创建")) 
                   ? const SizedBox(height:12, width:12, child: CircularProgressIndicator(strokeWidth: 2,))
                   : const Text('采用方案'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _isProcessingAiPlan ? null : () {
                _handleSubmitted("我想修改一下方案"); // 用户想继续对话调整
              },
              child: const Text('修改需求'),
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
                  onPressed: _isProcessingAiPlan ? null : () { // 处理中则禁用建议按钮
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
                onSubmitted: _isProcessingAiPlan ? null : _handleSubmitted, // 处理中则禁用提交
                decoration: const InputDecoration.collapsed(
                  hintText: '请输入您的需求...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16),
                minLines: 1,
                maxLines: 5,
                enabled: !_isProcessingAiPlan, // 处理中则禁用输入框
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  icon: Icon(Icons.send, color: _isProcessingAiPlan ? Colors.grey : Theme.of(context).primaryColor),
                  onPressed: _isProcessingAiPlan ? null : () => _handleSubmitted(_textController.text)),
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
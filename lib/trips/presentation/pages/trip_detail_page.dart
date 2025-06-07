// lib/trips/presentation/pages/trip_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math'; // For random ID generation - 现在活动ID由后端处理或用时间戳做临时ID
import 'package:qr_flutter/qr_flutter.dart'; // 添加二维码生成库
import 'package:share_plus/share_plus.dart'; // 添加分享功能库
import 'package:flutter/services.dart'; // 用于复制到剪贴板

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 确保已配置
import '../../../../main.dart'; // For flutterLocalNotificationsPlugin

//通知服务智慧旅游模式
import '../../services/trip_notification_service.dart';
import '../../services/trip_location_service.dart'; // 如果实现了位置服务


// 核心服务和模型
import '../../../core/services/api_service.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/models/api_trip_plan_model.dart';
import '../../../core/enums/trip_enums.dart';

// 新增：行程分享服务
import '../../services/trip_sharing_service.dart';

// Widgets
import '../widgets/activity_card_widget.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/ticket_view_widget.dart';
import 'activity_edit_page.dart';
import 'trip_plan_edit_page.dart';


// 服务实例
final TripNotificationService _tripNotificationService = TripNotificationService();
final TripLocationService _tripLocationService = TripLocationService(); // 如果实现了位置服务


class TripDetailPage extends StatefulWidget {
  final String userTripId; // <--- 修改：接收 UserTrip ID

  const TripDetailPage({
    super.key,
    required this.userTripId, // <--- 修改：必需参数
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  // 新增：行程分享服务
  late final TripSharingService _sharingService = TripSharingService(apiService: _apiService);
  
  ApiUserTrip? _userTripData;
  bool _isLoading = true;
  String? _loadingError;

  late TripMode _currentMode = TripMode.view; // 默认视图模式
  int _selectedDayIndex = -1;

  final PageController _mainContentPageController = PageController(initialPage: 0);
  int _currentMainViewIndex = 0; // 0: Itinerary, 1: Map, 2: Tickets

  bool _isAiChatExpanded = false;
  final TextEditingController _aiTextController = TextEditingController();
  final FocusNode _aiFocusNode = FocusNode();

  // 编辑用的控制器
  final TextEditingController _editableTripNameController = TextEditingController();
  final TextEditingController _editableCoverImageController = TextEditingController();
  final TextEditingController _editableDescriptionController = TextEditingController();
  final TextEditingController _editableOriginController = TextEditingController();
  final TextEditingController _editableDestinationController = TextEditingController();
  DateTime? _editableStartDate;
  DateTime? _editableEndDate;
  Set<String> _editableTags = {};
  // 注意：每日行程和活动的编辑是直接修改 _userTripData.days 中的对象，然后通过 _saveChanges 统一保存

  // 用于跟踪活动的前端UI状态 (如果需要独立于后端模型管理)
  Map<String, ActivityStatus> _activityUiStatus = {};

  // 新增：用于滚动定位和折叠
  final ScrollController _itineraryScrollController = ScrollController();
  List<GlobalKey> _daySectionKeys = [];
  // 用于跟踪每日行程的展开状态，key 是 dayIndex
  Map<int, bool> _isDayExpanded = {};

  // New field to track flashing day index
  int _flashingDayIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadUserTripDetails();
    _mainContentPageController.addListener(_onMainContentViewChanged);
  }

  void _onMainContentViewChanged() {
    if (!mounted) return;
    final currentPage = _mainContentPageController.page?.round();
    if (currentPage != null && currentPage != _currentMainViewIndex) {
      setState(() {
        _currentMainViewIndex = currentPage;
      });
    }
  }

  // *** 新增/保持: _initializeDayKeysAndExpansion ***
  void _initializeDayKeysAndExpansion(int numberOfDays) {
    if (!mounted) return;
    _daySectionKeys = List.generate(numberOfDays, (_) => GlobalKey());
    Map<int, bool> newExpansionState = {};
    for (int i = 0; i < numberOfDays; i++) {
      // 保留已有的展开状态，新添加的默认为true
      newExpansionState[i] = _isDayExpanded[i] ?? true; 
    }
    _isDayExpanded = newExpansionState;
  }

  Future<void> _loadUserTripDetails({bool showLoadingIndicator = true}) async { // 微调: 调用 _initializeDayKeysAndExpansion
    if (!mounted) return;
    if (showLoadingIndicator) {
      setState(() { _isLoading = true; _loadingError = null; });
    }
    try {
      final userTrip = await _apiService.getUserTripById(widget.userTripId, populatePlan: true);
      if (!mounted) return;

      setState(() {
        _userTripData = userTrip;
        _updateEditableControllers(userTrip); 

        if (userTrip.travelStatus == 'traveling') {
          _currentMode = TripMode.travel;
        } else {
          _currentMode = TripMode.view;
        }
        _selectedDayIndex = (userTrip.days.isNotEmpty) ? 0 : -1;
        _initializeDayKeysAndExpansion(userTrip.days.length); // *** 调用初始化 ***
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingError = '加载行程详情失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateEditableControllers(ApiUserTrip userTrip) { // <--- 修改方法名为 _updateEditableControllers
    _editableTripNameController.text = userTrip.userTripNameOverride ?? userTrip.displayName;
    _editableCoverImageController.text = userTrip.coverImage ?? userTrip.planDetails?.coverImage ?? '';
    _editableDescriptionController.text = userTrip.description ?? userTrip.planDetails?.description ?? '';
    _editableOriginController.text = userTrip.origin ?? userTrip.planDetails?.origin ?? '';
    _editableDestinationController.text = userTrip.destination ?? userTrip.planDetails?.destination ?? '';
    _editableStartDate = userTrip.startDate ?? userTrip.planDetails?.startDate;
    _editableEndDate = userTrip.endDate ?? userTrip.planDetails?.endDate;
    _editableTags = Set<String>.from(userTrip.tags.isNotEmpty ? userTrip.tags : (userTrip.planDetails?.tags ?? []));
  }

  @override
  void dispose() {
    _mainContentPageController.removeListener(_onMainContentViewChanged);
    _mainContentPageController.dispose();
    _aiTextController.dispose();
    _aiFocusNode.dispose();
    _editableTripNameController.dispose();
    _editableCoverImageController.dispose();
    _editableDescriptionController.dispose();
    _editableOriginController.dispose();
    _editableDestinationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_userTripData == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在保存...'), duration: Duration(seconds: 2)));

    bool overallSuccess = true;

    // 1. 准备 UserTrip 特有字段的更新载荷
    Map<String, dynamic> userTripSpecificUpdates = {
      'user_trip_name_override': _editableTripNameController.text,
      'coverImage': _editableCoverImageController.text.isNotEmpty ? _editableCoverImageController.text : null,
      'origin': _editableOriginController.text,
      'destination': _editableDestinationController.text,
      'startDate': _editableStartDate?.toIso8601String().substring(0,10),
      'endDate': _editableEndDate?.toIso8601String().substring(0,10),
      'tags': _editableTags.toList(),
      'description': _editableDescriptionController.text,
      'days': _userTripData!.days.map((d) => d.toJson()).toList(),
    };

    // 2. 准备核心计划内容的更新 (days)
    // 无论是否有 planId，days 的更新都是针对 UserTrip 文档中实际的 days 数组
    // 后端服务在更新 UserTrip 时，如果它有关联的 planId，可以选择是否以及如何将这些 days 的更改同步回原始的 TripPlan
    // 或者，如果这里的编辑总是意味着 UserTrip 实例的 days 独立于 TripPlan 模板，那么只更新 UserTrip 的 days 即可。
    // 当前的设计是，如果 planId 存在，我们会尝试更新 TripPlan 的 days，同时也更新 UserTrip 的 days (作为副本)。
    List<ApiDayFromUserTrip> currentDaysDataForUserTrip = _userTripData!.days;
    userTripSpecificUpdates['days'] = currentDaysDataForUserTrip.map((d) => d.toJson()).toList();


    // 3. 如果存在 planId，尝试更新关联的 TripPlan
    if (_userTripData!.planId != null && _userTripData!.planId!.isNotEmpty) {
      String planNameForUpdate;
      if (_userTripData!.planDetails != null) {
          planNameForUpdate = _userTripData!.planDetails!.name; // TripPlan的名称通常不应通过编辑UserTrip来修改
      } else {
          // 如果 planDetails 未加载，这是一个问题。但我们仍需一个名称。
          // 使用 UserTrip 的 displayName (它可能来自 userTripNameOverride 或回退到 planDetails.name)
          planNameForUpdate = _userTripData!.displayName;
      }

      final planToUpdate = ApiTripPlan( // 构造一个 ApiTripPlan 对象用于更新
        id: _userTripData!.planId!,
        name: planNameForUpdate, // 通常是 planDetails.name
        origin: _editableOriginController.text, // 这些字段也应更新到 TripPlan
        destination: _editableDestinationController.text,
        startDate: _editableStartDate,
        endDate: _editableEndDate,
        durationDays: (_editableStartDate != null && _editableEndDate != null)
            ? _editableEndDate!.difference(_editableStartDate!).inDays + 1
            : _userTripData!.planDetails?.durationDays,
        tags: _editableTags.toList(),
        description: _editableDescriptionController.text,
        coverImage: _editableCoverImageController.text.isNotEmpty ? _editableCoverImageController.text : null,
        
        days: currentDaysDataForUserTrip.map((utDay) => ApiPlanDay( // 将用户编辑的 days 转为 ApiPlanDay 结构
            dayNumber: utDay.dayNumber,
            date: utDay.date,
            title: utDay.title,
            description: utDay.description,
            activities: utDay.activities.map((utAct) => ApiPlanActivity(
                id: utAct.id?.startsWith('temp_') == true ? null : utAct.id,
                title: utAct.title,
                description: utAct.description,
                location: utAct.location, // 对应 ApiPlanActivity.location (数据库中是 location_name)
                address: utAct.address,
                startTime: utAct.startTime,
                endTime: utAct.endTime,
                durationMinutes: utAct.durationMinutes,
                type: utAct.type,
                estimatedCost: utAct.actualCost, // 模板中是 estimated_cost
                bookingInfo: utAct.bookingInfo,
                note: utAct.note, // 对应 activity_notes
                icon: utAct.icon,
                transportation: utAct.transportation
            )).toList(),
            notes: utDay.notes // 对应 daily_notes
        )).toList(),
        
        // 从加载的 planDetails 继承其他不在此处编辑的市场属性
        creatorId: _userTripData!.planDetails?.creatorId,
        isFeaturedOnMarket: _userTripData!.planDetails?.isFeaturedOnMarket,
        platformPrice: _userTripData!.planDetails?.platformPrice,
        averageRating: _userTripData!.planDetails?.averageRating,
        reviewCount: _userTripData!.planDetails?.reviewCount,
        salesVolume: _userTripData!.planDetails?.salesVolume,
        usageCount: _userTripData!.planDetails?.usageCount,
        version: _userTripData!.planDetails?.version, // 可以考虑版本+1
        estimatedCostRange: _userTripData!.planDetails?.estimatedCostRange,
        suitability: _userTripData!.planDetails?.suitability,
        highlights: _userTripData!.planDetails?.highlights,
      );

      try {
        final updatedPlan = await _apiService.updateTripPlanDetails(_userTripData!.planId!, planToUpdate);
        if (mounted && _userTripData != null) {
          _userTripData!.planDetails = updatedPlan; // 使用API返回的更新后的模板信息更新本地
        }
      } catch (e) {
        print("Error updating TripPlan in _saveChanges: $e");
        overallSuccess = false;
        // 在实际应用中，你可能想在这里给用户更具体的错误提示
        messenger.showSnackBar(SnackBar(content: Text('保存计划模板失败: ${e.toString().substring(0,min(e.toString().length,100))}'), backgroundColor: Colors.red,));
      }
    }
    // 如果没有 planId，planRelatedUpdatesForUserTrip 的逻辑已合并到 userTripSpecificUpdates 的 days 部分
    // (因为 UserTrip 本身会存储这些核心规划信息)

    // 4. 总是尝试更新 UserTrip 实例
    if (overallSuccess) { // 只有当 TripPlan 更新成功 (或不需要更新 TripPlan) 时才继续更新 UserTrip
      try {
        // ApiService 的 updateUserTrip 方法返回更新后的 ApiUserTrip 对象
        final updatedUserTrip = await _apiService.updateUserTrip(widget.userTripId, userTripSpecificUpdates);
        if (mounted) {
          _userTripData = updatedUserTrip; // *** 使用后端返回的最新数据更新本地状态 ***
          _updateEditableControllers(updatedUserTrip); // 同步编辑控制器
        }
      } catch (e) {
        print("Error updating UserTrip in _saveChanges: $e");
        overallSuccess = false;
        messenger.showSnackBar(SnackBar(content: Text('保存用户行程失败: ${e.toString().substring(0,min(e.toString().length,100))}'), backgroundColor: Colors.red,));
      }
    }

    if (!mounted) return;
    messenger.removeCurrentSnackBar();
    if (overallSuccess) {
      messenger.showSnackBar(const SnackBar(content: Text('行程已保存成功！'), backgroundColor: Colors.green,));
      setState(() {
        _currentMode = TripMode.view; // *** 切换到浏览模式 ***
        _isAiChatExpanded = false;
      });
      // 可以选择在切换模式后不立即重新加载，因为上面已经用API返回的数据更新了 _userTripData
      // await _loadUserTripDetails(showLoadingIndicator: false); 
      // *** 不再调用 Navigator.pop(true) ***
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('部分或全部保存失败，请检查网络并重试。'), backgroundColor: Colors.red,));
    }
  }

  // *** Fixed: _scrollToDay with improved and reliable scrolling ***
  void _scrollToDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _daySectionKeys.length || !mounted) return;
    
      final key = _daySectionKeys[dayIndex];
    
    // Update selected day index and ensure expansion
    setState(() {
      _selectedDayIndex = dayIndex;
      _isDayExpanded[dayIndex] = true;
    });

    // Use a longer delay to ensure state updates are applied completely
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      
      // Find the context associated with the key
      final context = key.currentContext;
      if (context == null) {
        print('警告: 未找到日期 ${dayIndex + 1} 的视图');
        return;
      }
      
      // Method 1: Use direct scroll controller positioning
      try {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        
        // Calculate the current scroll position
        final double currentScrollOffset = _itineraryScrollController.offset;
        
        // Calculate target position - account for top bar, day tabs, and add some padding
        // This positions the day with some space at the top for better visibility
        final topPadding = MediaQuery.of(context).padding.top; // Status bar height
        final appBarHeight = 56.0; // Approximate app bar height
        final tabsHeight = 120.0; // Approximate height of all headers (date capsule + bottom switcher)
        final extraPadding = 12.0; // Extra space for comfort
        
        // Target position: global position minus fixed headers and current scroll
        final targetOffset = position.dy - (topPadding + appBarHeight + tabsHeight + extraPadding);
        
        print('滚动到第 ${dayIndex + 1} 天: 位置 $targetOffset (从 $currentScrollOffset)');
        
        _itineraryScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      } catch (e) {
        print('方法1滚动失败: $e');
        
        // Method 2: Fallback to Scrollable.ensureVisible
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          alignment: 0.0, // Align to top
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      }
      
      // Visual feedback animation
      _flashDaySection(dayIndex);
    });
  }
  
  // New method to provide visual feedback when scrolling to a section
  void _flashDaySection(int dayIndex) {
    if (!mounted) return;
    
    // This will be used by the _ActivityDaySection to show a highlight animation
    setState(() {
      _flashingDayIndex = dayIndex;
    });
    
    // Reset the flashing state after animation completes
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _flashingDayIndex = -1;
        });
      }
    });
  }

  void _addDay() {
    if (_userTripData == null || !mounted) return;

    DateTime newDate;
    int newDayNumber;
    if (_userTripData!.days.isEmpty) {
      newDate = _editableStartDate ?? DateTime.now();
      newDayNumber = 1;
    } else {
      final lastDay = _userTripData!.days.last;
      newDate = (lastDay.date ?? _editableEndDate ?? DateTime.now()).add(const Duration(days: 1));
      newDayNumber = (lastDay.dayNumber ?? _userTripData!.days.length) + 1;
    }

    final newDay = ApiDayFromUserTrip(
        dayNumber: newDayNumber,
        date: newDate,
        activities: [],
        notes: '');

    setState(() {
      _userTripData!.days.add(newDay);
      _initializeDayKeysAndExpansion(_userTripData!.days.length); // *** 重新初始化keys和展开状态 ***
      _selectedDayIndex = _userTripData!.days.length - 1; 
      _isDayExpanded[_selectedDayIndex] = true; // *** 新增的天默认展开 ***

      if (_mainContentPageController.hasClients && _currentMainViewIndex != 0) {
        _mainContentPageController.jumpToPage(0); 
      }
      WidgetsBinding.instance.addPostFrameCallback((_) { // *** 延迟滚动 ***
        _scrollToDay(_selectedDayIndex);
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新日期已添加 (本地)，请记得保存计划')));
  }

  void _addActivityToCurrentDay(int dayIndex) async {
    if (_userTripData == null || dayIndex < 0 || dayIndex >= _userTripData!.days.length || !mounted) { /* ... */ return; }
    final currentDay = _userTripData!.days[dayIndex];

    final ApiActivityFromUserTrip? newActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityEditPage(
          dayDate: currentDay.date ?? _userTripData?.startDate,
          destinationCity: _userTripData?.destination, // *** 新增：传递目的地城市 ***
        ),
      ),
    );

    if (newActivity != null && mounted) {
      setState(() {
        // 为新活动生成一个临时的前端ID，如果后端不处理的话
        final activityToAdd = newActivity.id == null 
                              ? newActivity.copyWith(id: 'temp_${DateTime.now().millisecondsSinceEpoch}') 
                              : newActivity;
        currentDay.activities.add(activityToAdd);
        _isDayExpanded[dayIndex] = true;
      });
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新活动已在本地添加，请点击顶部"保存计划"以同步。')));
    }
  }

  void _editActivity(ApiDayFromUserTrip day, ApiActivityFromUserTrip activity, int activityIndex) async {
    if (_userTripData == null || !mounted) return;

    final ApiActivityFromUserTrip? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityEditPage(
          initialActivity: activity, 
          dayDate: day.date ?? _userTripData?.startDate,
          destinationCity: _userTripData?.destination, // *** 新增：传递目的地城市 ***
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        day.activities[activityIndex] = result; // 用编辑后的活动替换
      });
      // 提示用户需要保存整个行程
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('活动已在本地更新，请点击顶部"保存计划"以同步到服务器。')));
    }
  }

  void _navigateToTripPlanEditPage() async {
    if (_userTripData == null || !mounted) return;

    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripPlanEditPage(userTrip: _userTripData!)),
    );

    if (result == true && mounted) { // If TripPlanEditPage indicates changes were saved
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('计划详情已更新。正在刷新...')));
      await _loadUserTripDetails(showLoadingIndicator: true); // Reload data to reflect changes
    } else if (result == "DELETE_PLAN" && mounted) {
      // This case is handled if _deleteCurrentTripPlan is called from TripPlanEditPage
      // If deletion is confirmed and popped from TripPlanEditPage, TripDetailPage should react.
      // Usually, if deleted, TripDetailPage itself should be popped.
      // For now, _deleteCurrentTripPlan in TripDetailPage handles the pop after successful API call.
      // If DELETE_PLAN is popped from TripPlanEditPage, it means it was successful there.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程计划已删除。'), backgroundColor: Colors.green,));
      Navigator.of(context).pop(true); // Pop TripDetailPage as well
    }
  }

  // 新增: 删除行程计划的逻辑
  void _deleteCurrentTripPlan() async {
      // 确认弹窗已在 TripPlanEditPage 处理，这里直接执行删除
      if (_userTripData == null || !mounted) return;
      
      final messenger = ScaffoldMessenger.of(context);
      try {
        bool success = await _apiService.deleteUserTrip(_userTripData!.id);
        if (success && mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('行程计划已删除'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true); // 返回上一页，并告知已删除
        } else if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('删除失败，请重试'), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('删除操作出错: $e'), backgroundColor: Colors.red));
        }
      }
  }
  
  // 新增: 删除单个活动的逻辑 (在 _ActivityDaySection 中调用)
  void _deleteActivity(ApiDayFromUserTrip day, ApiActivityFromUserTrip activity) async {
    final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text('删除活动'),
              content: Text('确定要删除活动 " ${activity.title} " 吗？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
              ],
            ));
    if (confirmDelete == true && mounted) {
      setState(() {
        day.activities.remove(activity);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('活动已在本地删除，请记得保存计划。')));
    }
  }

  // 新增: 发布行程的逻辑
  Future<void> _publishTrip() async {
    if (_userTripData == null || !mounted) return;
    if (_userTripData!.publishStatus == 'published') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('此行程已经发布过了。')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在发布行程...')));

    try {
      // 准备更新的载荷，只包含 publish_status
      Map<String, dynamic> updatePayload = {
        'publish_status': 'published',
        // 如果发布时需要填写“给管理员的提交说明”，可以在这里弹窗获取
        // 'submission_notes_to_admin': '用户提交发布的行程' 
      };

      final updatedUserTrip = await _apiService.updateUserTrip(widget.userTripId, updatePayload);
      
      if (mounted) {
        setState(() {
          _userTripData = updatedUserTrip; // 更新本地数据
          // _currentMode = TripMode.view; // 发布后通常返回查看模式，如果当前是编辑模式的话
        });
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('行程发布成功！'), backgroundColor: Colors.green));
        // 可以在这里考虑是否需要重新加载数据或仅更新UI
        // await _loadUserTripDetails(showLoadingIndicator: false); 
      }
    } catch (e) {
      if (mounted) {
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(SnackBar(
          content: Text('发布行程失败: ${e.toString().substring(0, min(e.toString().length, 100))}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  //活动状态的前端管理逻辑
  void _handleActivityStatusChange(String activityId, ActivityStatus newStatus) {
    if (!mounted) return;
    setState(() {
      _activityUiStatus[activityId] = newStatus;

      if (newStatus == ActivityStatus.completed) {
        // 如果一个活动标记为完成，尝试将下一个pending的活动设为ongoing
        if (_userTripData != null && _selectedDayIndex != -1) {
          final currentDayActivities = _userTripData!.days[_selectedDayIndex].activities;
          int completedActivityInternalIndex = currentDayActivities.indexWhere((act) => act.id == activityId);

          // 清除其他可能存在的 ongoing 状态
          _activityUiStatus.updateAll((key, value) => value == ActivityStatus.ongoing ? ActivityStatus.pending : value);

          bool nextOngoingFound = false;
          for (int i = completedActivityInternalIndex + 1; i < currentDayActivities.length; i++) {
            if (_activityUiStatus[currentDayActivities[i].id!] == ActivityStatus.pending || _activityUiStatus[currentDayActivities[i].id!] == null) {
              _activityUiStatus[currentDayActivities[i].id!] = ActivityStatus.ongoing;
              nextOngoingFound = true;
              break;
            }
          }
          // 如果后面没有pending的，则从头找第一个pending的设为ongoing
          if (!nextOngoingFound) {
            for (int i = 0; i < currentDayActivities.length; i++) {
               if (i != completedActivityInternalIndex && (_activityUiStatus[currentDayActivities[i].id!] == ActivityStatus.pending || _activityUiStatus[currentDayActivities[i].id!] == null) ) {
                 _activityUiStatus[currentDayActivities[i].id!] = ActivityStatus.ongoing;
                 break;
               }
            }
          }
        }
      } else if (newStatus == ActivityStatus.ongoing) {
        // 如果一个活动被设为 ongoing，确保其他活动不是 ongoing
         _activityUiStatus.forEach((key, value) {
            if (key != activityId && value == ActivityStatus.ongoing) {
                _activityUiStatus[key] = ActivityStatus.pending;
            }
         });
      }
    });
    // 注意：这个前端状态的改变不会直接保存到后端，除非你有特定API来同步这个状态
    // 或者，这个状态仅用于UI展示，实际的"完成"可能通过其他方式记录
  }

  List<ApiTicket> _getTicketsForCurrentDay(DateTime? currentDate) {
    if (_userTripData == null || currentDate == null) return [];
    return _userTripData!.tickets.where((ticket) {
      if (ticket.date == null || ticket.date!.isEmpty) return false;
      try {
        // 假设 ticket.date 是 "YYYY-MM-DD" 格式
        final ticketDate = DateTime.parse(ticket.date!);
        return ticketDate.year == currentDate.year &&
               ticketDate.month == currentDate.month &&
               ticketDate.day == currentDate.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }
  // 在_buildAppBar方法之前添加分享功能相关方法
  void _showShareOptions() {
    if (_userTripData == null) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildShareOptionsSheet(),
    );
  }
 Widget _buildShareOptionsSheet() {
    String tripName = _userTripData?.displayName ?? '行程计划';
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '团队编辑与分享',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 添加团队编辑专区
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '邀请好友一起编辑',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                  ),
                  title: const Text('邀请成员'),
                  subtitle: const Text('让朋友加入并一起编辑行程'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).primaryColor),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToMemberInvitePage();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '分享方式',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                icon: Icons.qr_code,
                label: '二维码分享',
                onTap: () {
                  Navigator.pop(context);
                  _shareWithQrCode();
                },
              ),
              _buildShareOption(
                icon: Icons.link,
                label: '复制链接',
                onTap: () {
                  _copyShareLink();
                  Navigator.pop(context);
                },
              ),
              _buildShareOption(
                icon: Icons.share,
                label: '系统分享',
                onTap: () {
                  _shareWithSystemShare();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 使用服务分享行程
  Future<void> _shareWithSystemShare() async {
    if (_userTripData == null) return;
    
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在准备分享链接...')));
    
    try {
      await _sharingService.shareLink(
        tripId: widget.userTripId,
        tripName: _userTripData!.displayName,
        context: context,
      );
    } catch (e) {
      String errorMsg = '分享失败';
      if (e.toString().contains('用户未登录')) {
        errorMsg = '分享失败: 登录状态异常，请尝试重新登录';
      } else {
        errorMsg = '分享失败: ${e.toString()}';
      }
      messenger.showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ));
    }
  }
  
  // 使用服务复制行程分享链接
  Future<void> _copyShareLink() async {
    if (_userTripData == null) return;
    
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在生成链接...')));
    
    try {
      await _sharingService.copyShareLink(
        tripId: widget.userTripId,
        tripName: _userTripData!.displayName,
        context: context,
      );
    } catch (e) {
      String errorMsg = '复制链接失败';
      if (e.toString().contains('用户未登录')) {
        errorMsg = '复制链接失败: 登录状态异常，请尝试重新登录';
      } else {
        errorMsg = '复制链接失败: ${e.toString()}';
      }
      messenger.showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ));
    }
  }
  
  // 使用服务生成和分享二维码
  Future<void> _shareWithQrCode() async {
    if (_userTripData == null) return;
    
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在生成二维码...')));
    
    try {
      await _sharingService.shareQrCode(
        tripId: widget.userTripId,
        tripName: _userTripData!.displayName,
        context: context,
      );
    } catch (e) {
      String errorMsg = '生成二维码失败';
      if (e.toString().contains('用户未登录')) {
        errorMsg = '生成二维码失败: 登录状态异常，请尝试重新登录';
      } else {
        errorMsg = '生成二维码失败: ${e.toString()}';
      }
      messenger.showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ));
    }
  }
  
  void _navigateToMemberInvitePage() {
    if (_userTripData == null) return;
    
    // 显示临时邀请对话框，直到成员邀请页面开发完成
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀请成员加入'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('邀请好友一起编辑"${_userTripData!.displayName}"行程'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('复制邀请链接'),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _copyShareLink();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code),
                    label: const Text('生成邀请二维码'),
                    onPressed: () {
                      Navigator.pop(context);
                      _shareWithQrCode();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '注意: 被邀请的成员将获得编辑该行程的权限',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 保留原有的_buildShareOption方法
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  
  // 修改_buildAppBar方法，添加分享按钮
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: BackButton(color: Colors.white),
      actions: [
        // 添加分享按钮
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _showShareOptions,
        ),
        IconButton(
          icon: Icon(_currentMode == TripMode.edit ? 
                    Icons.check : 
                    _currentMode == TripMode.travel ? 
                      Icons.edit_location_alt : Icons.edit,
            color: Colors.white),
          onPressed: _currentMode == TripMode.edit ? _saveChanges : _toggleEditMode,
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除行程'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') _confirmDeleteTrip();
          },
        ),
      ],
      elevation: 0,
      // Rest of the AppBar properties remain the same
    );
  }


  Widget _buildCoverAndTitleSectionWidget(BuildContext context) {
    if (_userTripData == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    final String? displayName = _userTripData!.displayName;
    final String? coverImageUrl = _userTripData!.coverImage ?? _userTripData!.planDetails?.coverImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: (_currentMode == TripMode.edit || _currentMode == TripMode.view)
              ? _navigateToTripPlanEditPage // Navigate to full edit page in both modes
              : null,
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: coverImageUrl != null && coverImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(coverImageUrl), // 使用从 _userTripData 获取的封面
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                          )
                        : const DecorationImage( // 默认封面
                            image: AssetImage('assets/images/default_cover.png'), // 确保图片路径正确
                            fit: BoxFit.cover,
                            colorFilter: const ColorFilter.mode(Color.fromRGBO(0, 0, 0, 0.2), BlendMode.darken),
                          )),
              ),
              if (_currentMode == TripMode.edit)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20)),
                ),
              Container( // 渐变遮罩
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  displayName ?? '未命名行程', // 使用从 _userTripData 获取的名称，如果为空则显示默认值
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1, 1))],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // 根据当前模式显示不同的操作按钮
        if (_currentMode == TripMode.view) _buildViewModeActionButtonsStyled(),
        if (_currentMode == TripMode.edit) _buildEditModeActionButtonsStyled(),
        if (_currentMode == TripMode.travel) _buildTravelModeHeaderInfoStyled(),
        // 新增：显示成员头像
        if (_userTripData!.members.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // 现有的成员头像列表
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _userTripData!.members.length,
                      itemBuilder: (context, index) {
                      final member = _userTripData!.members[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0, top:4, bottom:4),
                          child: CircleAvatar(
                            radius: 18, // 调整头像大小
                            backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                                ? NetworkImage(member.avatarUrl!)
                                : null,
                            child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                                ? Text(member.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 14))
                                : null,
                              ),
                            );
                    },
                  ),
                ),
                
              ),
              IconButton(
                  icon: const Icon(Icons.map_outlined, size: 22),
                  onPressed: () => _navigateToMapPage(),
                  tooltip: '查看地图',
                ),

            ],
          ),
        ),
      ],
    );
  }

  void _editTripNameAndCoverDialog() async { // 重命名
    if (_userTripData == null || !mounted) return;

    // 使用 _editable... 控制器，它们已在 _updateEditableControllers 中被初始化
    // _editableTripNameController, _editableCoverImageController, etc.

    final result = await showDialog<bool>( // 返回 bool 表示是否需要保存
        context: context,
        builder: (context) {
          String? tempDialogCoverUrl = _editableCoverImageController.text; // 用于图片预览
          return AlertDialog(
            title: const Text("编辑行程信息"),
            content: StatefulBuilder( // 用于更新图片预览
                builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _editableTripNameController, decoration: const InputDecoration(labelText: "行程名称 (您的自定义名称)"),),
                    const SizedBox(height: 16),
                    Text("封面图片URL (可选):", style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _editableCoverImageController,
                      decoration: const InputDecoration(hintText: "粘贴图片URL或留空"),
                      onChanged: (value) { setStateDialog(() { tempDialogCoverUrl = value.isNotEmpty ? value : null; }); },
                    ),
                    if (tempDialogCoverUrl != null && tempDialogCoverUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            tempDialogCoverUrl!,
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 60,
                              color: Colors.grey[200],
                              child: Center(
                                child: Text(
                                  "图片预览失败",
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 12)
                                )
                              )
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(controller: _editableOriginController, decoration: const InputDecoration(labelText: "出发地"),),
                    const SizedBox(height: 8),
                    TextField(controller: _editableDestinationController, decoration: const InputDecoration(labelText: "目的地"),),
                    // TODO: 添加日期和标签的编辑UI (可以使用 _editableStartDate, _editableEndDate, _editableTags)
                  ],
                ),
              );
            }),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消")),
              ElevatedButton(onPressed: () { Navigator.pop(context, true); }, child: const Text("应用更改 (本地)"))
            ],
          );
        });

    if (result == true && mounted) {
      // 用户点击了"应用更改"，本地 _editable 控制器中的值已更新
      // 实际的保存操作将在用户点击顶部的"保存计划"按钮时通过 _saveChanges() 触发
      setState(() {
        // 你可以决定是否在这里用 _editable 控制器的值更新 _userTripData 的本地显示
        // 或者依赖于 _saveChanges 成功后再通过 _loadUserTripDetails 刷新
        _userTripData?.userTripNameOverride = _editableTripNameController.text;
        _userTripData?.coverImage = _editableCoverImageController.text.isNotEmpty ? _editableCoverImageController.text : null;
        _userTripData?.origin = _editableOriginController.text;
        _userTripData?.destination = _editableDestinationController.text;
        // ... 更新 _userTripData 的其他字段 ...
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更改已在本地应用，请点击"保存计划"进行最终保存。')));
    }
  }

  Widget _buildStyledButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onPressed, bool isPrimary = false}) {
    final ButtonStyle style = isPrimary
        ? ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    )
        : OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).primaryColor,
      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    );

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isPrimary ? Colors.white : Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isPrimary ? Colors.white : Theme.of(context).primaryColor)),
      ],
    );

    return isPrimary
        ? ElevatedButton(onPressed: onPressed, style: style, child: buttonChild)
        : OutlinedButton(onPressed: onPressed, style: style, child: buttonChild);
  }

  Widget _buildViewModeActionButtonsStyled() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(child: _buildStyledButton(context, label: '编辑计划', icon: Icons.edit_note_outlined, onPressed: () {
            if (!mounted || _userTripData == null) return;
            _updateEditableControllers(_userTripData!); // 进入编辑模式前，用当前数据填充控制器
            setState(() { _currentMode = TripMode.edit; });
          })),
          const SizedBox(width: 8),
          Expanded(child: _buildStyledButton(context, label: '团队编辑', icon: Icons.group_add, onPressed: _showShareOptions)),
          const SizedBox(width: 8),
          Expanded(child: _buildStyledButton(context, label: '开始旅行', icon: Icons.navigation_outlined, onPressed: () async {
            if(_userTripData == null || !mounted) return;
            final originalStatus = _userTripData!.travelStatus;
            setState(() { _userTripData!.travelStatus = 'traveling'; _currentMode = TripMode.travel;});

            try {
              final updatedTrip = await _apiService.updateUserTrip(widget.userTripId, {"travel_status": "traveling"});
              if (!mounted) return;

              // 激活旅行通知系统
              await _tripNotificationService.activateTripMode(widget.userTripId);
              // 启动位置跟踪
              if (_currentMode == TripMode.travel) {
                await _tripLocationService.startLocationTracking();
              }

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('旅行模式已开启！')));
              await _loadUserTripDetails(showLoadingIndicator: false);
            } catch (e) {
              if (!mounted) return;
              print("Error starting trip: $e");
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('开启旅行模式失败，请重试。')));
              setState(() { _userTripData!.travelStatus = originalStatus; _currentMode = TripMode.view;});
            }
          }, isPrimary: true)),
        ],
      ),
    );
  }

  Widget _buildEditModeActionButtonsStyled() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(icon: Icon(Icons.settings_backup_restore, color: Colors.grey[700]), tooltip: '重置编辑', onPressed: (){
             if(_userTripData != null && mounted) {
               _updateEditableControllers(_userTripData!); // 重置编辑控制器为原始数据
               setState((){}); // 刷新UI上绑定的编辑字段
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('编辑内容已重置为上次保存的状态')));
             }
          }),
          const SizedBox(width: 8),
          _buildStyledButton(context, label: '保存计划', icon: Icons.save_alt_outlined, onPressed: _saveChanges, isPrimary: true)
        ],
      ),
    );
  }

  Widget _buildTravelModeHeaderInfoStyled() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      color: Theme.of(context).primaryColor.withOpacity(0.03),
      child: Row(
        children: [
          Icon(Icons.explore_rounded, color: Theme.of(context).primaryColor, size: 22),
          const SizedBox(width: 8),
          Text("旅行模式", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).primaryColor)),
          const Spacer(),
          TextButton(
              onPressed: () async {
                if(_userTripData == null || !mounted) return;
                final originalStatus = _userTripData!.travelStatus;
                setState(() { _userTripData!.travelStatus = 'completed'; _currentMode = TripMode.view;});

                try {
                  final updatedTrip = await _apiService.updateUserTrip(widget.userTripId, {"travel_status": "completed"});
                  if (!mounted) return;

                  // 停用旅行通知系统
                  await _tripNotificationService.deactivateTripMode();
                  // 停止位置跟踪
                  _tripLocationService.stopLocationTracking();


                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('旅行已圆满结束！')));
                  await _loadUserTripDetails(showLoadingIndicator: false);
                } catch (e) {
                  if (!mounted) return;
                  print("Error completing trip: $e");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('结束旅行操作失败，请重试。')));
                  setState(() { _userTripData!.travelStatus = originalStatus; _currentMode = TripMode.travel;});
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: const Text("结束旅行")
          )
        ],
      ),
    );
  }

  Widget _buildDateCapsuleBarSliver() {
    if (_userTripData == null || (_userTripData!.days.isEmpty && _currentMode != TripMode.edit)) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final List<ApiDayFromUserTrip> days = _userTripData!.days;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 60.0,
        maxHeight: 60.0,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!))
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _currentMode == TripMode.edit ? days.length + 1 : days.length,
            itemBuilder: (context, index) {
              if (_currentMode == TripMode.edit && index == days.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ActionChip(
                    avatar: Icon(Icons.add, size: 18, color: Theme.of(context).primaryColor),
                    label: const Text('添加日期'),
                    onPressed: _addDay,
                    backgroundColor: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey[300]!)
                    ),
                  ),
                );
              }
              if (days.isEmpty || index >= days.length) return const SizedBox.shrink();

              final day = days[index];
              final isSelected = index == _selectedDayIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text('Day ${day.dayNumber ?? index + 1} (${day.date?.month ?? '?'}/${day.date?.day ?? '?'})'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      // Always make sure we're in the right view (itinerary)
                      if (_mainContentPageController.hasClients && _currentMainViewIndex != 0) {
                        _mainContentPageController.jumpToPage(0);
                      }
                      
                      // First expand the day and update selection state
                        setState(() {
                          _selectedDayIndex = index;
                        _isDayExpanded[index] = true; // Always expand the selected day
                      });
                      
                      // Ensure the day is expanded before scrolling
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Use a slight delay to ensure the UI has updated
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (!mounted) return;
                          _scrollToDay(index);
                        });
                      });
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  avatar: isSelected ? Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ) : null,
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: isSelected ? 14 : 13,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: isSelected ? 1 : 0,
                  pressElevation: 2,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300]!,
                        width: isSelected ? 1.5 : 1,
                      )
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentPageView() {
    if (_userTripData == null) {
      return const Center(child: Text("等待行程数据..."));
    }
    return PageView.builder(
      controller: _mainContentPageController,
      itemCount: 2, // 只有行程和票夹两个视图
      onPageChanged: (index) {
        if (mounted) setState(() { _currentMainViewIndex = index; });
      },
      itemBuilder: (context, index) {
        if (_currentMainViewIndex != index) {
          return const Center(child: CircularProgressIndicator());
        }
        
        switch (index) {
          case 0: // 行程视图
            return _buildItineraryView();
          case 1: // 票夹视图
            return _userTripData!.days.isNotEmpty && _selectedDayIndex != -1
                ? TicketViewWidget(tickets: _getTicketsForCurrentDay(_userTripData!.days[_selectedDayIndex].date))
                : const Center(child: Text("请先选择一个日期或添加票券以查看票夹"));
          default:
            return const SizedBox.shrink();
        }
      }
    );
  }

  //日程视图
  Widget _buildItineraryView() {
    if (_userTripData == null || _userTripData!.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _currentMode == TripMode.edit ? '请在上方日期栏点击"添加日期"以开始规划您的行程。' : '此行程当前没有日期安排。',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Optional: track scroll position to improve sync between tab and content
        return false;
      },
      child: ListView.builder(
      controller: _itineraryScrollController,
      padding: const EdgeInsets.all(16.0),
        physics: const ClampingScrollPhysics(),  // Better scroll behavior
      itemCount: _userTripData!.days.length,
      itemBuilder: (context, dayIndex) {
        final dayData = _userTripData!.days[dayIndex];
        return _ActivityDaySection(
          key: _daySectionKeys.isNotEmpty && dayIndex < _daySectionKeys.length ? _daySectionKeys[dayIndex] : GlobalKey(),
          dayData: dayData,
          dayIndex: dayIndex, 
          mode: _currentMode,
          isExpanded: _isDayExpanded[dayIndex] ?? true,
          onExpansionChanged: (expanded) {
            setState(() {
              _isDayExpanded[dayIndex] = expanded;
                if (expanded && _selectedDayIndex != dayIndex) {
                  _selectedDayIndex = dayIndex; // Update selected day when manually expanded
                }
            });
          },
          onEditActivity: (activity, activityIndex) {
            _editActivity(dayData, activity, activityIndex);
          },
          onAddActivity: () { 
            _addActivityToCurrentDay(dayIndex);
          },
          activityUiStatusMap: _activityUiStatus,
          onActivityStatusChange: _handleActivityStatusChange,
          onDeleteActivity: (activityToDelete) { 
            _deleteActivity(dayData, activityToDelete);
          },
        );
      },
      ),
    );
  }

  //修改底部导航栏，只显示行程和票夹
  Widget _buildBottomViewSwitcherBarSliver() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 50.0,
        maxHeight: 50.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomViewTab(BottomView.itinerary, Icons.article_outlined, '行程'),
              _buildBottomViewTab(BottomView.tickets, Icons.confirmation_number_outlined, '票夹'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomViewTab(BottomView view, IconData icon, String label) {
    final bool isSelected = _currentMainViewIndex == view.index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_currentMainViewIndex != view.index) {
            _mainContentPageController.animateToPage(
              view.index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[500], size: 22),
              // Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAiChat(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    bool shouldShowAiButton = (_currentMode == TripMode.edit || _currentMode == TripMode.travel);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      bottom: isKeyboardVisible
          ? MediaQuery.of(context).viewInsets.bottom + 10
          : (_isAiChatExpanded ? 10 : 20),
      left: _isAiChatExpanded ? 12 : null,
      right: _isAiChatExpanded ? 12 : 20,
      child: Material(
        color: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: shouldShowAiButton
              ? (_isAiChatExpanded
              ? _buildExpandedAiInput(context)
              : _buildCollapsedAiButton(context)
          )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildCollapsedAiButton(BuildContext context) {
    return FloatingActionButton(
      key: const ValueKey('collapsedAiButton'),
      onPressed: () {
        if (mounted) setState(() { _isAiChatExpanded = true; });
        WidgetsBinding.instance.addPostFrameCallback((_) => _aiFocusNode.requestFocus());
      },
      backgroundColor: Theme.of(context).colorScheme.secondary,
      elevation: 4.0,
      tooltip: 'AI助手',
      child: const Icon(Icons.luggage_rounded, color: Colors.white),
    );
  }

  Widget _buildExpandedAiInput(BuildContext context) {
    return Container(
      key: const ValueKey('expandedAiInput'),
      width: _isAiChatExpanded ? MediaQuery.of(context).size.width - 24 : 0,
      child: Material(
        elevation: 0.0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28.0),
                  border: Border.all(color: Colors.grey.shade200.withOpacity(0.7))
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey[600], size: 22),
                    onPressed: () {
                      if (mounted) setState(() { _isAiChatExpanded = false; });
                      _aiFocusNode.unfocus();
                    },
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _aiTextController,
                      focusNode: _aiFocusNode,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '与AI助手聊聊...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) => _sendAiMessage(text),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic_none_outlined, color: Theme.of(context).primaryColor),
                    tooltip: '语音输入',
                    onPressed: () { /* TODO */ },
                  ),
                  IconButton(
                    icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                    tooltip: '发送',
                    onPressed: () => _sendAiMessage(_aiTextController.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendAiMessage(String text) {
    if (text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送给AI: $text (待实现)')));
      _aiTextController.clear();
      _aiFocusNode.unfocus();
    }
  }

  void _navigateToMapPage() {
    if (_userTripData == null || _selectedDayIndex == -1 || 
        _selectedDayIndex >= _userTripData!.days.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个日期或添加活动以查看地图'))
      );
      return;
    }    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TripMapPage(
          userTripData: _userTripData!,
          selectedDayIndex: _selectedDayIndex,
        ),
      ),
    );
  }
  // 添加切换编辑模式的方法
  void _toggleEditMode() {
    // 如果当前处于查看模式，则切换到编辑模式
    if (_currentMode == TripMode.view || _currentMode == TripMode.travel) {
      setState(() {
        _currentMode = TripMode.edit;
      });
    }
    // 如果当前处于编辑模式，则在保存后会自动切换到查看模式
  }
  
  // 删除行程确认对话框
  void _confirmDeleteTrip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此行程吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteTrip();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  // 执行删除行程操作
  Future<void> _deleteTrip() async {
    if (_userTripData == null) return;
    
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在删除...')));
    
    try {
      final success = await _apiService.deleteUserTrip(widget.userTripId);
      if (!mounted) return;
      
      if (success) {
        messenger.showSnackBar(const SnackBar(content: Text('行程已删除')));
        // 导航回上一页
        Navigator.pop(context);
      } else {
        messenger.showSnackBar(const SnackBar(
          content: Text('删除失败，请重试'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('删除失败: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const Scaffold(body: Center(child: CircularProgressIndicator())); }
    if (_loadingError != null) { return Scaffold(body: Center(child: Text(_loadingError!))); }
    if (_userTripData == null) { return const Scaffold(body: Center(child: Text("无法加载行程数据。"))); }

    // 根据当前状态确定是否显示发布按钮及是否启用
    bool canPublish = _userTripData != null && 
                      _userTripData!.publishStatus != 'published' && 
                      _userTripData!.publishStatus != 'pending_review'; // 假设有待审核状态

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: _currentMode == TripMode.view ? 300.0 : 260.0,
                        floating: false,
                        pinned: true,
                        stretch: true,
                        backgroundColor: Colors.white,
                        elevation: 0,
                        automaticallyImplyLeading: true,
                        iconTheme: IconThemeData(color: Colors.grey[700]),
                        actions: [ 
                          // 发布按钮
                          if (_currentMode == TripMode.view || _currentMode == TripMode.edit) // 仅在查看或编辑模式下显示
                            Tooltip(
                              message: canPublish ? '发布行程' : '行程已发布或待审核',
                              child: IconButton(
                                icon: Icon(
                                  Icons.publish_outlined,
                                  color: canPublish ? Colors.grey[700] : Colors.grey[400], // 禁用时颜色变浅
                                ),
                                onPressed: canPublish ? _publishTrip : null, // 如果不能发布，则 onPressed 为 null
                              ),
                            ),
                          // 设置按钮
                          if (_currentMode == TripMode.view || _currentMode == TripMode.edit) // Show in view and edit modes
                            IconButton(
                              icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
                              tooltip: '编辑计划详情', // More descriptive tooltip
                              onPressed: _navigateToTripPlanEditPage,
                            ),
                          // 删除按钮
                          if (_currentMode == TripMode.view) // 通常在浏览模式下提供删除
                            _buildTestNotificationsButton(),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.grey[700]),
                              tooltip: '删除行程',
                              onPressed: _deleteCurrentTripPlan,
                            ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.pin,
                          background: _buildCoverAndTitleSectionWidget(context),
                        ),
                      ),
                      _buildBottomViewSwitcherBarSliver(),
                      _buildDateCapsuleBarSliver(),
                      SliverFillRemaining(
                        hasScrollBody: true, 
                        child: _buildMainContentPageView(), // PageView 现在包含可滚动的行程列表
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentMode == TripMode.edit || _currentMode == TripMode.travel)
              _buildFloatingAiChat(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestNotificationsButton() {
    if (_userTripData == null) return const SizedBox.shrink();
    
    return ElevatedButton.icon(
      icon: const Icon(Icons.notifications_active),
      label: const Text('模拟今日通知'),
      onPressed: () {
        _tripNotificationService.setTripData(_userTripData!);
        
        // 模拟整体通知序列
        _tripNotificationService.simulateDayNotifications();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开始模拟旅行通知...')),
        );
      },
    );
  }
} 


class _ActivityDaySection extends StatelessWidget {
  final ApiDayFromUserTrip dayData;
  final int dayIndex; 
  final TripMode mode;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Function(ApiActivityFromUserTrip, int) onEditActivity;
  final VoidCallback onAddActivity; 
  final Map<String, ActivityStatus> activityUiStatusMap; // 新增: 接收整个状态Map
  final Function(String activityId, ActivityStatus newStatus) onActivityStatusChange; // 新增: 状态变更回调
  final Function(ApiActivityFromUserTrip activity) onDeleteActivity;

  const _ActivityDaySection({
    super.key, 
    required this.dayData,
    required this.onDeleteActivity,
    required this.dayIndex, 
    required this.mode,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onEditActivity,
    required this.onAddActivity,
    required this.activityUiStatusMap,
    required this.onActivityStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    String dayTitle = '第 ${dayData.dayNumber ?? dayIndex + 1} 天';
    if (dayData.date != null) {
      dayTitle += ' (${dayData.date!.month}/${dayData.date!.day})';
    }

    // 提取主题或标题
    String dayTheme = "";
    if (dayData.title != null && dayData.title!.isNotEmpty) {
      final String title = dayData.title!;
      if (title.contains("：")) {
        dayTheme = title.split("：")[1].trim();
      } else if (title.contains(":")) {
        dayTheme = title.split(":")[1].trim();
      } else if (title.contains("-")) {
        dayTheme = title.split("-")[1].trim();
      } else {
        dayTheme = title;
      }
    }

    // 检查是否为当前选中的天数
    bool isCurrentSelectedDay = false;
    bool isFlashing = false;
    if (context.findAncestorStateOfType<_TripDetailPageState>() != null) {
      final state = context.findAncestorStateOfType<_TripDetailPageState>()!;
      isCurrentSelectedDay = state._selectedDayIndex == dayIndex;
      isFlashing = state._flashingDayIndex == dayIndex;
    }

    // 根据日期索引生成不同的主题颜色
    List<Color> dayColors = [
      Colors.blue.shade700,
      Colors.teal.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.green.shade700,
      Colors.red.shade700,
    ];
    
    final Color dayColor = dayColors[dayIndex % dayColors.length];
    final Color bgColor = isFlashing 
        ? dayColor.withOpacity(0.15)
        : isCurrentSelectedDay 
            ? dayColor.withOpacity(0.08) 
            : Colors.white;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFlashing 
            ? [BoxShadow(color: dayColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
            : isCurrentSelectedDay 
                ? [BoxShadow(color: dayColor.withOpacity(0.2), blurRadius: 4, spreadRadius: 1)]
                : [BoxShadow(color: Colors.grey.shade200, blurRadius: 2)],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 0, // 使用自定义阴影，所以卡片本身无阴影
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isFlashing 
                ? dayColor
                : isCurrentSelectedDay 
                    ? dayColor.withOpacity(0.5) 
                    : Colors.grey.shade200, 
            width: isFlashing ? 2.0 : isCurrentSelectedDay ? 1.5 : 1
          )
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                onExpansionChanged(!isExpanded);
                
                // Update the selected day in the parent state
                if (context.findAncestorStateOfType<_TripDetailPageState>() != null) {
                  final state = context.findAncestorStateOfType<_TripDetailPageState>()!;
                  state.setState(() {
                    state._selectedDayIndex = dayIndex;
                  });
                  // Trigger scroll to this day
                  state._scrollToDay(dayIndex);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isFlashing 
                      ? dayColor.withOpacity(0.2)
                      : isCurrentSelectedDay 
                          ? dayColor.withOpacity(0.1) 
                          : dayColor.withOpacity(0.05),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Row(
                    children: [
                      // 左侧竖条标记
                      Container(
                        width: 4,
                        height: 28,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: dayColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // 日期和主题
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 日期显示
                            Text(
                              dayTitle, 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: isFlashing 
                                    ? dayColor
                                    : isCurrentSelectedDay 
                                        ? dayColor
                                        : dayColor
                              )
                            ),
                            // 主题显示（如果有）
                            if (dayTheme.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  dayTheme,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // 右侧控件
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 当前选择标记
                          if (isCurrentSelectedDay)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFlashing ? dayColor : dayColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Text(
                                '当前选择', 
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                          // 展开/收起按钮
                          IconButton(
                            icon: Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                              color: isFlashing 
                                  ? dayColor
                                  : isCurrentSelectedDay 
                                      ? dayColor 
                                      : Colors.grey[700],
                              size: 28,
                            ),
                            onPressed: () => onExpansionChanged(!isExpanded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                // 内容区域的装饰
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期描述（如果有）
                      if (dayData.description != null && dayData.description!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: dayColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dayColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            dayData.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      
                      // 活动列表
                      _buildActivitiesListForDay(context),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesListForDay(BuildContext context) {
    final activities = dayData.activities;
    if (activities.isEmpty && mode != TripMode.edit) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('本日暂无活动安排', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column( 
      children: [
        for (int i = 0; i < activities.length; i++) ...[
          Row( // 将卡片和删除按钮包裹在Row中 (仅编辑模式)
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ActivityDisplayCard(
                  activity: activities[i],
                  mode: mode,
                  onEdit: () => onEditActivity(activities[i], i),
                  uiStatus: activities[i].id != null ? activityUiStatusMap[activities[i].id!] : null,
                  onStatusChange: mode == TripMode.travel 
                    ? (newStatus) {
                        if (activities[i].id != null) {
                          onActivityStatusChange(activities[i].id!, newStatus);
                        }
                      } 
                    : null,
                ),
              ),
              if (mode == TripMode.edit)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, left:0), // 调整与卡片对齐
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                    onPressed: () => onDeleteActivity(activities[i]),
                    tooltip: '删除此活动',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
          ),
          if (i < activities.length - 1)
            TransportConnector(
              transportationMode: activities[i+1].transportation, 
              durationMinutes: activities[i+1].durationMinutes, 
            ),
        ],
        if (mode == TripMode.edit)
          _AddActivityButton(onPressed: onAddActivity), 
      ],
    );
  }
}

// *** 新增/显著修改: _AddActivityButton (私有Widget) ***
class _AddActivityButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddActivityButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0), // 调整间距
      child: OutlinedButton.icon(
        icon: Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).primaryColor, size: 22),
        label: Text(
          '添加新活动',
          style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56), 
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.4), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.04),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// _SliverAppBarDelegate 辅助类保持不变
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({ required this.minHeight, required this.maxHeight, required this.child });
  final double minHeight;
  final double maxHeight;
  final Widget child;
  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => max(maxHeight, minHeight);
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
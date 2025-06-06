// lib/trips/presentation/pages/trip_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math'; // For random ID generation - 现在活动ID由后端处理或用时间戳做临时ID

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 确保已配置
import '../../../../main.dart'; // For flutterLocalNotificationsPlugin

// 核心服务和模型
import '../../../core/services/api_service.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/models/api_trip_plan_model.dart';
import '../../../core/enums/trip_enums.dart';

// Widgets
import '../widgets/activity_card_widget.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/ticket_view_widget.dart';
import 'activity_edit_page.dart';
import 'trip_plan_edit_page.dart';


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

  // *** 新增/保持: _scrollToDay ***
  void _scrollToDay(int dayIndex) {
    if (dayIndex >= 0 && dayIndex < _daySectionKeys.length) {
      final key = _daySectionKeys[dayIndex];
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.0, 
        );
      }
    }
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
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新活动已在本地添加，请点击顶部“保存计划”以同步。')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('活动已在本地更新，请点击顶部“保存计划”以同步到服务器。')));
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
              content: Text('确定要删除活动 “${activity.title}” 吗？'),
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
    // 或者，这个状态仅用于UI展示，实际的“完成”可能通过其他方式记录
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

  // --- 新增：显示行程开始通知的方法 ---
  Future<void> _showTripStartedNotification() async {
    if (_userTripData == null) return; // 确保数据已加载
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'trip_status_channel',
      '行程状态通知',
      channelDescription: '用于通知行程的开始、进行中和结束状态。',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('ok_action', '好的'),
        AndroidNotificationAction('cancel_action', '取消'),
      ],
    );
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'trip_started_category',
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // 通知的唯一 ID
      '旅行已开始', // 通知标题
      '您的“${_userTripData!.userTripNameOverride}”行程已正式进入旅行模式！', // 通知内容
      notificationDetails,
      payload: 'trip_started_payload_${_userTripData!.id}', // 点击通知时传递的数据
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // 调整垂直间距
            child: SizedBox(
              height: 40, // 调整高度以适应头像大小
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
                      Padding(padding: const EdgeInsets.only(top: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(tempDialogCoverUrl!, height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 60, color: Colors.grey[200], child: Center(child: Text("图片预览失败", style: TextStyle(color: Colors.red.shade700, fontSize: 12)))),),),),
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
      // 用户点击了“应用更改”，本地 _editable 控制器中的值已更新
      // 实际的保存操作将在用户点击顶部的“保存计划”按钮时通过 _saveChanges() 触发
      setState(() {
        // 你可以决定是否在这里用 _editable 控制器的值更新 _userTripData 的本地显示
        // 或者依赖于 _saveChanges 成功后再通过 _loadUserTripDetails 刷新
        _userTripData?.userTripNameOverride = _editableTripNameController.text;
        _userTripData?.coverImage = _editableCoverImageController.text.isNotEmpty ? _editableCoverImageController.text : null;
        _userTripData?.origin = _editableOriginController.text;
        _userTripData?.destination = _editableDestinationController.text;
        // ... 更新 _userTripData 的其他字段 ...
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更改已在本地应用，请点击“保存计划”进行最终保存。')));
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
          const SizedBox(width: 12),
          Expanded(child: _buildStyledButton(context, label: '开始旅行', icon: Icons.navigation_outlined, onPressed: () async {
            if(_userTripData == null || !mounted) return;
            final originalStatus = _userTripData!.travelStatus;
            setState(() { _userTripData!.travelStatus = 'traveling'; _currentMode = TripMode.travel;});

            try {
              final updatedTrip = await _apiService.updateUserTrip(widget.userTripId, {"travel_status": "traveling"});
              if (!mounted) return;
              // 如果需要使用 updatedTrip 更新本地 _userTripData，可以在这里操作
              // _userTripData = updatedTrip; // 或者部分更新
              await _showTripStartedNotification();
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
                      if(mounted) {
                        setState(() {
                          _selectedDayIndex = index;
                          if (!_isDayExpanded[index]!) { // *** 如果未展开则展开 ***
                            _isDayExpanded[index] = true;
                          }
                        });
                      }
                      if (_mainContentPageController.hasClients && _currentMainViewIndex != 0) {
                          _mainContentPageController.jumpToPage(0);
                      }
                      _scrollToDay(index); // *** 滚动到选中的天 ***
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.10),
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pressElevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.7) : Colors.grey[300]!)
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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

    return PageView(
      controller: _mainContentPageController,
      onPageChanged: (index) {
        if (mounted) setState(() { _currentMainViewIndex = index; });
      },
      children: <Widget>[
        _buildItineraryView(), // *** 使用新的行程视图方法 ***
        if (_userTripData!.days.isNotEmpty && _selectedDayIndex != -1 && _selectedDayIndex < _userTripData!.days.length)
            MapViewWidget(
                activities: _userTripData!.days[_selectedDayIndex].activities, 
                mode: _currentMode
            )
        else
            const Center(child: Text("请先选择一个日期或添加活动以查看地图")),

        if (_userTripData!.days.isNotEmpty && _selectedDayIndex != -1 && _selectedDayIndex < _userTripData!.days.length)
            TicketViewWidget(
                tickets: _getTicketsForCurrentDay(_userTripData!.days[_selectedDayIndex].date) 
            )
        else
            const Center(child: Text("请先选择一个日期或添加票券以查看票夹")),
      ],
    );
  }

  Widget _buildItineraryView() {
    if (_userTripData == null || _userTripData!.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _currentMode == TripMode.edit ? '请在上方日期栏点击“添加日期”以开始规划您的行程。' : '此行程当前没有日期安排。',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _itineraryScrollController,
      padding: const EdgeInsets.all(16.0),
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
          // *** 新增传递 onDeleteActivity 参数 ***
          onDeleteActivity: (activityToDelete) { 
            _deleteActivity(dayData, activityToDelete);
          },
        );
      },
    );
  }


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
              _buildBottomViewTab(BottomView.map, Icons.map_outlined, '地图'),
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
        if (mounted) { setState(() { _isAiChatExpanded = true; });}
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
    if (dayData.title != null && dayData.title!.isNotEmpty) {
      dayTitle += ' - ${dayData.title}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1)
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(dayTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.grey[700]),
              onPressed: () => onExpansionChanged(!isExpanded),
            ),
            onTap: () => onExpansionChanged(!isExpanded),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0), // 调整内边距
              child: _buildActivitiesListForDay(context),
            ),
        ],
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
                  onStatusChange: mode == TripMode.travel ? (newStatus) { /* ... */ } : null,
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
                    constraints: BoxConstraints(),
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
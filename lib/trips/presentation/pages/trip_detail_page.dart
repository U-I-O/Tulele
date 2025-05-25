// lib/trips/presentation/pages/trip_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math'; // For random ID generation (temp)

// *** 导入拆分出去的子组件 ***
import '../widgets/activity_card_widget.dart';
import '../widgets/note_view_widget.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/ticket_view_widget.dart';
// import '../widgets/ai_chat_fab_widget.dart'; // 如果也拆分了

// 模拟数据模型定义 (理想情况下，这些应该在 domain/entities 中，并由所有相关文件导入)
// 为了这个示例能独立运行，暂时在此处重复定义。请确保在您的项目中它们位于正确位置并只定义一次。
enum TripMode { view, edit, travel }
enum BottomView { notes, map, tickets }
enum ActivityStatus { pending, ongoing, completed }

class Activity {
  final String id;
  String time;
  String description;
  String? location;
  String? transportToNext;
  String? transportDuration;
  ActivityStatus status;

  Activity({
    required this.id,
    required this.time,
    required this.description,
    this.location,
    this.transportToNext,
    this.transportDuration,
    this.status = ActivityStatus.pending,
  });
}

class TripDay {
  final int dayNumber;
  final DateTime date;
  final List<Activity> activities;
  String notes;

  TripDay({
    required this.dayNumber,
    required this.date,
    required this.activities,
    this.notes = '',
  });
}

class Trip {
  final String id;
  String name;
  List<TripDay> days;

  Trip({required this.id, required this.name, required this.days});
}

class Ticket {
  final String id;
  final String type;
  final String name;
  final DateTime dateTime;
  final String details;

  Ticket({required this.id, required this.type, required this.name, required this.dateTime, required this.details});
}
// --- 数据模型定义结束 ---




class TripDetailPage extends StatefulWidget {
  final String tripId;
  final TripMode initialMode;
  final Map<String, dynamic>? newTripInitialData; // 用于接收新创建行程的初始数据

  const TripDetailPage({
    super.key,
    required this.tripId,
    this.initialMode = TripMode.view,
    this.newTripInitialData, // 新增参数
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> with TickerProviderStateMixin {
  late TripMode _currentMode;
  late Trip _tripData;
  late int _selectedDayIndex;
  
  final PageController _pageController = PageController(); // 初始化 PageController
  BottomView _currentBottomView = BottomView.notes;
  bool _showAiChat = false;

  // 修改为可变的 Map，以便添加新行程
  final Map<String, Trip> _sampleTrips = {
    '1': Trip(id: '1', name: '三亚海岛度假', days: [
      TripDay(dayNumber: 1, date: DateTime(2025, 6, 1), activities: [
        Activity(id: 'a1', time: '09:00 - 12:30', description: '抵达三亚凤凰国际机场', location: '三亚凤凰国际机场', transportToNext: '打车', transportDuration: '约30分钟'),
        Activity(id: 'a2', time: '13:30 - 14:30', description: '酒店入住', location: '三亚海棠湾喜来登度假酒店', status: ActivityStatus.completed),
        Activity(id: 'a3', time: '15:00 - 18:00', description: '亚龙湾沙滩漫步', location: '亚龙湾国家旅游度假区', status: ActivityStatus.ongoing),
      ], notes: "第一天笔记：天气晴朗，心情愉悦！记得涂防晒。"),
      TripDay(dayNumber: 2, date: DateTime(2025, 6, 2), activities: [
        Activity(id: 'b1', time: '10:00 - 16:00', description: '蜈支洲岛潜水和水上活动', location: '蜈支洲岛'),
        Activity(id: 'b2', time: '18:00 - 19:30', description: '海鲜大餐', location: '第一市场附近'),
      ]),
      TripDay(dayNumber: 3, date: DateTime(2025, 6, 3), activities: [
         Activity(id: 'c1', time: '全天', description: '自由活动或南山文化旅游区', location: '南山文化旅游区'),
      ]),
    ]),
  };

  final List<Ticket> _sampleTickets = [
    Ticket(id: 't1', type: '门票', name: '蜈支洲岛门票', dateTime: DateTime(2025, 6, 2, 9, 0), details: '成人票 x2'),
    Ticket(id: 't2', type: '酒店', name: '海棠湾喜来登', dateTime: DateTime(2025, 6, 1), details: '海景房 - 4晚'),
  ];

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;

    if (widget.newTripInitialData != null && !_sampleTrips.containsKey(widget.tripId)) {
      // 如果是新行程，并且携带了初始数据
      List<Map<String, dynamic>> daysData = List<Map<String, dynamic>>.from(widget.newTripInitialData!['days'] ?? []);
      _tripData = Trip(
        id: widget.tripId,
        name: widget.newTripInitialData!['name'] ?? '新行程',
        days: daysData.map((dayMap) => TripDay(
              dayNumber: dayMap['dayNumber'],
              date: dayMap['date'] as DateTime,
              activities: List<Map<String, dynamic>>.from(dayMap['activities'] ?? []).map((actMap) => Activity(
                id: actMap['id'] ?? 'act${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(100)}', // 生成随机ID
                time: actMap['time'],
                description: actMap['description'],
                location: actMap['location'],
                transportToNext: actMap['transportToNext'],
                transportDuration: actMap['transportDuration'],
              )).toList(),
              notes: dayMap['notes'] ?? '',
            )).toList(),
      );
      _sampleTrips[widget.tripId] = _tripData; // 将新行程添加到模拟数据源
    } else if (!_sampleTrips.containsKey(widget.tripId) && _currentMode == TripMode.edit) {
      // 如果是新行程ID (通过编辑模式进入)，但没有初始数据，则创建一个空的
      _tripData = Trip(id: widget.tripId, name: '我的新行程', days: [
        // 至少给一天，方便编辑
        TripDay(dayNumber: 1, date: DateTime.now(), activities: [], notes: '')
      ]);
      _sampleTrips[widget.tripId] = _tripData; // 将新行程添加到模拟数据源
    } else {
      _tripData = _sampleTrips[widget.tripId] ?? Trip(id: 'error', name: '行程未找到', days: []);
    }
    
    _selectedDayIndex = _tripData.days.isNotEmpty ? 0 : -1;

    if (_currentMode == TripMode.edit || _currentMode == TripMode.travel) {
      _showAiChat = true;
    }
  }

  // ... (其余的 _TripDetailPageState 代码，如 _buildAppBar, _saveTripAndSwitchToViewMode, _buildDateCapsuleBar, _addDay, _buildActivitiesList, _editActivity, _buildBottomViewSwitcher, _buildBottomPageView, _getTicketsForCurrentDay, build, _buildViewModeBottomActions, _buildTravelModeBottomInfo, _buildAiChatFab 保持不变)
  // ... (确保这里包含您上次代码中的所有这些方法)

  // 这里只粘贴 initState 之后的其他方法，以便您复制代码时不容易出错
  // 您需要将下面这些方法粘贴回 _TripDetailPageState 类中，替换掉原来对应的方法或添加到正确位置

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar() {
    List<Widget> actions = [];
    String titleText = _tripData.name;

    if (_currentMode == TripMode.edit) {
      titleText = '编辑: ${(_tripData.name.length > 15 ? "${_tripData.name.substring(0,15)}..." : _tripData.name)}';
      actions = [
        IconButton(icon: const Icon(Icons.undo_outlined), tooltip: '撤销', onPressed: () {/* TODO */}),
        IconButton(icon: const Icon(Icons.history_outlined), tooltip: '历史版本', onPressed: () {/* TODO */}),
        IconButton(icon: const Icon(Icons.save_outlined), tooltip: '保存', onPressed: _saveTripAndSwitchToViewMode),
      ];
    } else if (_currentMode == TripMode.view) {
      actions = [
        IconButton(icon: const Icon(Icons.share_outlined), tooltip: '邀请/分享', onPressed: () {/* TODO */}),
        TextButton(
          onPressed: () => setState(() {
             _currentMode = TripMode.edit;
             _showAiChat = true;
          }),
          child: const Text('编辑', style: TextStyle(fontSize: 16)),
        ),
      ];
    } else { // TripMode.travel
      titleText = '旅行中: ${(_tripData.name.length > 15 ? "${_tripData.name.substring(0,15)}..." : _tripData.name)}';
      actions = [
        IconButton(icon: const Icon(Icons.map_outlined), tooltip: '查看大地图', onPressed: () {/* TODO */}),
      ];
    }

    return AppBar(
      title: Text(titleText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 1.0,
      foregroundColor: Colors.grey[800],
      actions: actions,
    );
  }

  void _saveTripAndSwitchToViewMode() {
    // 在实际应用中，这里应该将 _tripData 保存到后端或本地存储
    // 更新 _sampleTrips 中的数据 (如果它是您的持久化模拟)
    _sampleTrips[widget.tripId] = _tripData;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程已保存 (模拟)')));
    setState(() {
      _currentMode = TripMode.view;
      _showAiChat = false;
    });
  }

  Widget _buildDateCapsuleBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!))
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _currentMode == TripMode.edit ? _tripData.days.length + 1 : _tripData.days.length,
        itemBuilder: (context, index) {
          if (_currentMode == TripMode.edit && index == _tripData.days.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ActionChip(
                avatar: Icon(Icons.add, size: 18, color: Theme.of(context).primaryColor),
                label: const Text('添加日期'),
                onPressed: _addDay,
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!)
                ),
              ),
            );
          }
          if (_tripData.days.isEmpty || index >= _tripData.days.length) return const SizedBox.shrink();

          final day = _tripData.days[index];
          final isSelected = index == _selectedDayIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text('Day ${day.dayNumber} (${day.date.month}/${day.date.day})'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!)
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    );
  }

  void _addDay() {
    setState(() {
      DateTime newDate;
      int newDayNumber;
      if (_tripData.days.isEmpty) {
        newDate = DateTime.now();
        newDayNumber = 1;
      } else {
        final lastDay = _tripData.days.last;
        newDate = lastDay.date.add(const Duration(days: 1));
        newDayNumber = lastDay.dayNumber + 1;
      }
      _tripData.days.add(TripDay(
        dayNumber: newDayNumber,
        date: newDate,
        activities: [],
      ));
      _selectedDayIndex = _tripData.days.length - 1;
    });
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新日期已添加')));
  }

  Widget _buildActivitiesList() {
    if (_tripData.days.isEmpty || _selectedDayIndex < 0 || _selectedDayIndex >= _tripData.days.length) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(_tripData.days.isEmpty && _currentMode == TripMode.edit ? '请点击上方“添加日期”开始规划行程' : 
                    _tripData.days.isEmpty ? '此行程暂无日期安排' : '请选择一个日期查看活动', 
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
        ),
      ));
    }
    final currentDay = _tripData.days[_selectedDayIndex];
    if (currentDay.activities.isEmpty && _currentMode != TripMode.edit) { // 编辑模式下允许空列表以便添加
       return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text('本日暂无活动安排', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
      ));
    }
    if (currentDay.activities.isEmpty && _currentMode == TripMode.edit) {
       return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('本日暂无活动，开始添加吧！', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("添加第一个活动"),
              onPressed: () => _addActivityToCurrentDay(),
            )
          ],
        ),
      ));
    }


    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16,16,16,0),
      itemCount: currentDay.activities.length,
      itemBuilder: (context, index) {
        final activity = currentDay.activities[index];
        final bool showConnector = index < currentDay.activities.length - 1;
        return ActivityCard(
          activity: activity,
          mode: _currentMode,
          showConnector: showConnector,
          onTap: _currentMode == TripMode.edit ? () => _editActivity(currentDay, activity, index) : null,
          onStatusChange: _currentMode == TripMode.travel ? (status) {
            setState(() {
              activity.status = status;
              if (status == ActivityStatus.completed) _checkAndAdvanceOngoingActivity(currentDay, index);
            });
          } : null,
        );
      },
    );
  }
  
  void _checkAndAdvanceOngoingActivity(TripDay currentDay, int completedActivityIndex) {
      bool ongoingFound = false;
      for (var act in currentDay.activities) {
          if (act.status == ActivityStatus.ongoing && act != currentDay.activities[completedActivityIndex]) {
              act.status = ActivityStatus.pending; 
          }
      }
      for (int i = completedActivityIndex + 1; i < currentDay.activities.length; i++) {
          if (currentDay.activities[i].status == ActivityStatus.pending) {
              currentDay.activities[i].status = ActivityStatus.ongoing;
              ongoingFound = true;
              break; 
          }
      }
      if (!ongoingFound) {
          for (int i = 0; i < currentDay.activities.length; i++) {
             if (currentDay.activities[i].status == ActivityStatus.pending) {
                currentDay.activities[i].status = ActivityStatus.ongoing;
                break;
             }
          }
      }
      setState(() {});
  }

  void _addActivityToCurrentDay() {
    if (_selectedDayIndex < 0 || _selectedDayIndex >= _tripData.days.length) return;
    final currentDay = _tripData.days[_selectedDayIndex];
    // 模拟打开一个编辑活动弹窗/页面，然后将返回的数据添加到 activities 列表
    // 为了简化，这里直接添加一个占位活动
    setState(() {
      currentDay.activities.add(Activity(
        id: 'new_act_${DateTime.now().millisecondsSinceEpoch}',
        time: '新活动时间',
        description: '新活动描述',
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新活动已添加，请编辑其详情')));
    // 理想情况下，应该直接打开编辑这个新活动的界面
    _editActivity(currentDay, currentDay.activities.last, currentDay.activities.length -1);

  }


  void _editActivity(TripDay day, Activity activity, int activityIndex) {
    // 示例：使用 showDialog 来模拟编辑
    TextEditingController descController = TextEditingController(text: activity.description);
    TextEditingController timeController = TextEditingController(text: activity.time);
    TextEditingController locController = TextEditingController(text: activity.location);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑活动'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: timeController, decoration: const InputDecoration(labelText: '时间 (如 09:00 - 10:00)')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: '活动描述')),
                const SizedBox(height: 8),
                TextField(controller: locController, decoration: const InputDecoration(labelText: '地点 (可选)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  day.activities[activityIndex].description = descController.text;
                  day.activities[activityIndex].time = timeController.text;
                  day.activities[activityIndex].location = locController.text.isNotEmpty ? locController.text : null;
                });
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }


  Widget _buildBottomViewSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 0, blurRadius: 4, offset: const Offset(0, -1)),
        ],
        border: Border(top: BorderSide(color: Colors.grey[200]!))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomViewTab(BottomView.notes, Icons.note_alt_outlined, '笔记'),
          _buildBottomViewTab(BottomView.map, Icons.map_outlined, '地图'),
          _buildBottomViewTab(BottomView.tickets, Icons.confirmation_number_outlined, '票夹'),
        ],
      ),
    );
  }

  Widget _buildBottomViewTab(BottomView view, IconData icon, String label) {
    final bool isSelected = _currentBottomView == view;
    return InkWell(
      onTap: () {
        if (_currentBottomView != view) {
           setState(() { _currentBottomView = view; });
           _pageController.animateToPage(
            view.index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[500], size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPageView() {
    if (_tripData.days.isEmpty || _selectedDayIndex < 0 || _selectedDayIndex >= _tripData.days.length) {
      return const SizedBox.shrink();
    }
    final currentDayData = _tripData.days[_selectedDayIndex];

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (mounted) {
           setState(() { _currentBottomView = BottomView.values[index]; });
        }
      },
      children: <Widget>[
        NoteViewWidget(
          initialNotes: currentDayData.notes,
          isEditable: _currentMode == TripMode.edit,
          onNotesChanged: (newNotes) {
            if(mounted) setState(() { currentDayData.notes = newNotes; });
          },
        ),
        MapViewWidget(activities: currentDayData.activities, mode: _currentMode),
        TicketViewWidget(tickets: _getTicketsForCurrentDay(currentDayData.date)),
      ],
    );
  }

  List<Ticket> _getTicketsForCurrentDay(DateTime currentDate) {
    return _sampleTickets.where((ticket) {
      return ticket.dateTime.year == currentDate.year &&
             ticket.dateTime.month == currentDate.month &&
             ticket.dateTime.day == currentDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildDateCapsuleBar(),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: _buildActivitiesList()),
                    _buildBottomViewSwitcher(),
                    SizedBox(
                      height: 180,
                      child: _buildBottomPageView(),
                    ),
                  ],
                ),
                if (_showAiChat && _currentMode != TripMode.view) _buildAiChatFab(), // 只在编辑和旅行模式下显示AI Fab
              ],
            )
          ),
          if (_currentMode == TripMode.view) _buildViewModeBottomActions(),
          if (_currentMode == TripMode.travel) _buildTravelModeBottomInfo(),
        ],
      ),
       floatingActionButton: (_currentMode == TripMode.edit && _tripData.days.isNotEmpty && _selectedDayIndex >=0)
        ? FloatingActionButton(
            onPressed: _addActivityToCurrentDay,
            child: const Icon(Icons.add_location_alt_outlined), // 更合适的图标
            tooltip: '添加活动到本日',
          )
        : null, // 其他模式不显示主FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildViewModeBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
        border: Border(top: BorderSide(color: Colors.grey[200]!))
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_calendar_outlined, size: 20),
              label: const Text('编辑行程'),
              onPressed: () => setState(() {
                _currentMode = TripMode.edit;
                _showAiChat = true;
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor, 
                side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.7)),
                padding: const EdgeInsets.symmetric(vertical: 12)
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions_walk_outlined, size: 20, color: Colors.white),
              label: const Text('开始旅行'),
              onPressed: () => setState(() {
                _currentMode = TripMode.travel;
                _showAiChat = true;
                if (_tripData.days.isNotEmpty && _selectedDayIndex < _tripData.days.length) {
                  final currentDay = _tripData.days[_selectedDayIndex];
                  for (var act in currentDay.activities) { act.status = ActivityStatus.pending; }
                  _checkAndAdvanceOngoingActivity(currentDay, -1);
                }
              }),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(vertical: 12)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelModeBottomInfo() {
    Activity? currentActivity;
     if (_tripData.days.isNotEmpty && _selectedDayIndex >=0 && _selectedDayIndex < _tripData.days.length) {
        final day = _tripData.days[_selectedDayIndex];
        currentActivity = day.activities.firstWhere(
            (act) => act.status == ActivityStatus.ongoing,
            orElse: () => day.activities.firstWhere(
                (act) => act.status == ActivityStatus.pending,
                orElse: () => Activity(id: 'none', time: '', description: '本日活动已全部完成或无待办')
            )
        );
    } else {
        currentActivity = Activity(id: 'none', time: '', description: '请选择日期或添加活动');
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentActivity.status == ActivityStatus.ongoing ? '进行中:' : '下一项:',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)
                ),
                const SizedBox(height: 2),
                Text(
                  currentActivity.description,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if(currentActivity.id != 'none' && currentActivity.time.isNotEmpty)
                  Text(
                    '计划时间: ${currentActivity.time}',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.mic_none_outlined, color: Colors.white, size: 28),
            tooltip: 'AI助手语音',
            onPressed: () { /* TODO: 打开AI语音助手 */ }
          )
        ],
      ),
    );
  }

  Widget _buildAiChatFab() {
    return Positioned(
      bottom: (_currentMode == TripMode.travel ? 100 : 20) + MediaQuery.of(context).padding.bottom, // 调整以避开底部栏
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI对话功能待实现')));
        },
        label: const Text('AI助手'),
        icon: const Icon(Icons.smart_toy_outlined),
        backgroundColor: Theme.of(context).hintColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
      ),
    );
  }
}
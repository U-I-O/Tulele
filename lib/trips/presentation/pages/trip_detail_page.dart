// lib/trips/presentation/pages/trip_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math'; // For random ID generation (temp)

// 导入实际的子组件 (假设已拆分到 widgets 文件夹下)
// 您需要确保这些路径是正确的，并且对应的文件存在于您的项目中
import '../widgets/activity_card_widget.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/ticket_view_widget.dart';

// 确保模型类定义 (TripMode, BottomView, ActivityStatus, Activity, TripDay, Trip, Ticket)
// 在这里或从正确位置导入。为了让这个文件能独立运行，暂时在此处定义。
// 最佳实践是将它们放到独立的 domain/entities 或 core/enums 文件中。
enum TripMode { view, edit, travel }
enum BottomView { itinerary, map, tickets }
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
  String? coverImageUrl;

  Trip({
    required this.id,
    required this.name,
    required this.days,
    this.coverImageUrl,
  });
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
  final Map<String, dynamic>? newTripInitialData;

  const TripDetailPage({
    super.key,
    required this.tripId,
    this.initialMode = TripMode.view,
    this.newTripInitialData,
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> with TickerProviderStateMixin {
  late TripMode _currentMode;
  late Trip _tripData;
  late int _selectedDayIndex;

  final PageController _mainContentPageController = PageController(initialPage: 0);
  int _currentMainViewIndex = 0;

  bool _showAiChat = false;
  final TextEditingController _aiTextController = TextEditingController();
  final FocusNode _aiFocusNode = FocusNode();

  // 模拟数据
  final Map<String, Trip> _sampleTrips = {
    '1': Trip(id: '1', name: '三亚海岛度假', coverImageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmVhY2h8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=800&q=60', days: [
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
      List<Map<String, dynamic>> daysData = List<Map<String, dynamic>>.from(widget.newTripInitialData!['days'] ?? []);
      _tripData = Trip(
        id: widget.tripId,
        name: widget.newTripInitialData!['name'] ?? '新行程',
        coverImageUrl: widget.newTripInitialData!['coverImageUrl'],
        days: daysData.map((dayMap) => TripDay(
          dayNumber: dayMap['dayNumber'],
          date: dayMap['date'] as DateTime,
          activities: List<Map<String, dynamic>>.from(dayMap['activities'] ?? []).map((actMap) => Activity(
            id: actMap['id'] ?? 'act${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(100)}',
            time: actMap['time'] ?? '时间未定',
            description: actMap['description'] ?? '活动描述',
            location: actMap['location'],
            transportToNext: actMap['transportToNext'],
            transportDuration: actMap['transportDuration'],
          )).toList(),
          notes: dayMap['notes'] ?? '',
        )).toList(),
      );
      _sampleTrips.putIfAbsent(widget.tripId, () => _tripData);
    } else {
      _tripData = _sampleTrips.putIfAbsent(widget.tripId, () => Trip(id: widget.tripId, name: '我的新行程', days: [TripDay(dayNumber: 1, date: DateTime.now(), activities: [], notes: '')]));
    }

    _selectedDayIndex = _tripData.days.isNotEmpty ? 0 : -1;
    if (_currentMode == TripMode.edit || _currentMode == TripMode.travel) {
      _showAiChat = true;
    }

    _mainContentPageController.addListener(() {
      if (_mainContentPageController.page?.round() != _currentMainViewIndex) {
        if (mounted) {
          setState(() {
            _currentMainViewIndex = _mainContentPageController.page!.round();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _mainContentPageController.dispose();
    _aiTextController.dispose();
    _aiFocusNode.dispose();
    super.dispose();
  }

  void _saveTripAndSwitchToViewMode() {
    _sampleTrips[_tripData.id] = _tripData; // 更新模拟数据
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程已保存 (模拟)')));
    if(mounted) {
      setState(() {
        _currentMode = TripMode.view;
        _showAiChat = false;
      });
    }
  }

  void _addDay() {
    if(mounted) {
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
        // 当添加新日期时，也让PageView跳转到行程视图
        _mainContentPageController.jumpToPage(0);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新日期已添加')));
  }

  void _addActivityToCurrentDay() {
    if (_selectedDayIndex < 0 || _selectedDayIndex >= _tripData.days.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择或添加一个日期')));
      return;
    }
    final currentDay = _tripData.days[_selectedDayIndex];
    if(mounted){
      setState(() {
        currentDay.activities.add(Activity(
          id: 'new_act_${DateTime.now().millisecondsSinceEpoch}',
          time: '新活动时间',
          description: '新活动描述',
        ));
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新活动已添加，请编辑其详情')));
    _editActivity(currentDay, currentDay.activities.last, currentDay.activities.length -1);
  }

  void _editActivity(TripDay day, Activity activity, int activityIndex) {
    TextEditingController descController = TextEditingController(text: activity.description);
    TextEditingController timeController = TextEditingController(text: activity.time);
    TextEditingController locController = TextEditingController(text: activity.location ?? '');

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
                if(mounted){
                  setState(() {
                    final updatedActivity = Activity(
                      id: activity.id,
                      time: timeController.text,
                      description: descController.text,
                      location: locController.text.isNotEmpty ? locController.text : null,
                      status: activity.status,
                      transportToNext: activity.transportToNext,
                      transportDuration: activity.transportDuration,
                    );
                    day.activities[activityIndex] = updatedActivity;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _checkAndAdvanceOngoingActivity(TripDay currentDay, int completedActivityIndex) {
    bool ongoingFound = false;
    for (int i = 0; i < currentDay.activities.length; i++) {
      if (i != completedActivityIndex && currentDay.activities[i].status == ActivityStatus.ongoing) {
        currentDay.activities[i].status = ActivityStatus.pending;
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
    if(mounted) setState(() {});
  }

  List<Ticket> _getTicketsForCurrentDay(DateTime currentDate) {
    return _sampleTickets.where((ticket) {
      return ticket.dateTime.year == currentDate.year &&
          ticket.dateTime.month == currentDate.month &&
          ticket.dateTime.day == currentDate.day;
    }).toList();
  }

  Widget _buildCoverAndTitleSectionWidget(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _currentMode == TripMode.edit ? _editTripNameAndCover : null,
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  image: _tripData.coverImageUrl != null && _tripData.coverImageUrl!.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(_tripData.coverImageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                  )
                      : null,
                ),
                child: _tripData.coverImageUrl == null || _tripData.coverImageUrl!.isEmpty
                    ? Center(child: Icon(Icons.image_search_outlined, size: 60, color: Colors.grey.shade400))
                    : null,
              ),
              if (_currentMode == TripMode.edit)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18)
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20,0,20,20),
                child: Text(
                  _tripData.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black87, offset: Offset(1, 2))],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (_currentMode == TripMode.view) _buildViewModeActionButtonsWidget(),
        if (_currentMode == TripMode.edit) _buildEditModeActionButtonsWidget(),
        if (_currentMode == TripMode.travel) _buildTravelModeHeaderInfoWidget(),
      ],
    );
  }

  void _editTripNameAndCover() async {
    TextEditingController nameController = TextEditingController(text: _tripData.name);
    String? tempCoverUrl = _tripData.coverImageUrl;

    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("编辑行程信息"),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setStateDialog) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: "行程名称"),
                        ),
                        const SizedBox(height: 16),
                        Text("封面图片URL (可选):", style: TextStyle(color: Colors.grey[700])),
                        TextField(
                          decoration: const InputDecoration(hintText: "粘贴图片URL或留空"),
                          controller: TextEditingController(text: tempCoverUrl),
                          onChanged: (value) {
                            tempCoverUrl = value.isNotEmpty ? value : null;
                            // 调用 setStateDialog 刷新对话框内的预览 (如果需要实时预览)
                            // setStateDialog((){});
                          },
                        ),
                        if (tempCoverUrl != null && tempCoverUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Image.network(tempCoverUrl!, height: 60, errorBuilder: (c,e,s) => Text("图片链接无效", style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
                          )
                      ],
                    ),
                  );
                }
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
              ElevatedButton(
                  onPressed: () {
                    if(mounted){
                      setState(() {
                        _tripData.name = nameController.text;
                        _tripData.coverImageUrl = tempCoverUrl;
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("保存")
              )
            ],
          );
        }
    );
  }

  Widget _buildViewModeActionButtonsWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('编辑行程'),
              onPressed: () { if(mounted) setState(() { _currentMode = TripMode.edit; _showAiChat = true; }); },
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.7))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions_walk_outlined, size: 18, color: Colors.white),
              label: const Text('开始旅行'),
              onPressed: () {
                if(mounted) {
                  setState(() {
                    _currentMode = TripMode.travel;
                    _showAiChat = true;
                    if (_tripData.days.isNotEmpty && _selectedDayIndex >=0 && _selectedDayIndex < _tripData.days.length) {
                      final currentDay = _tripData.days[_selectedDayIndex];
                      for (var act in currentDay.activities) { act.status = ActivityStatus.pending; }
                      _checkAndAdvanceOngoingActivity(currentDay, -1);
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeActionButtonsWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(icon: const Icon(Icons.undo_outlined), tooltip: '撤销', onPressed: () {/* TODO */}),
          IconButton(icon: const Icon(Icons.history_outlined), tooltip: '历史版本', onPressed: () {/* TODO */}),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined, size: 18, color: Colors.white),
            label: const Text('保存行程'),
            onPressed: _saveTripAndSwitchToViewMode,
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildTravelModeHeaderInfoWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.explore_outlined, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 8),
          Text("旅行模式已激活", style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor)),
          const Spacer(),
          TextButton(onPressed: (){
            if(mounted) setState(() { _currentMode = TripMode.view; _showAiChat = false; });
          }, child: const Text("结束旅行"))
        ],
      ),
    );
  }

  // ** Corrected: This method returns the SliverPersistentHeader for the date capsules **
  Widget _buildDateCapsuleBarSliver() {
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
                      if(mounted) {
                        setState(() {
                          _selectedDayIndex = index;
                        });
                      }
                      _mainContentPageController.jumpToPage(0);
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
        ),
      ),
    );
  }

  Widget _buildMainContentPageView() {
    if (_tripData.days.isEmpty || _selectedDayIndex < 0 || _selectedDayIndex >= _tripData.days.length) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          _tripData.days.isEmpty && _currentMode == TripMode.edit ? '请在上方日期栏点击“添加日期”以开始规划您的行程。' :
          _tripData.days.isEmpty ? '此行程当前没有日期安排。' :
          '请选择一个日期来查看详细内容。',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ));
    }
    final currentDayData = _tripData.days[_selectedDayIndex];
    return PageView(
      controller: _mainContentPageController,
      onPageChanged: (index) {
        if (mounted) setState(() { _currentMainViewIndex = index; });
      },
      children: <Widget>[
        _buildActivitiesListWithAddButton(), // Page 0: Itinerary
        MapViewWidget(activities: currentDayData.activities, mode: _currentMode), // Page 1: Map
        TicketViewWidget(tickets: _getTicketsForCurrentDay(currentDayData.date)), // Page 2: Tickets
      ],
    );
  }

  Widget _buildActivitiesListWithAddButton() {
    if (_tripData.days.isEmpty || _selectedDayIndex < 0 || _selectedDayIndex >= _tripData.days.length) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(_tripData.days.isEmpty && _currentMode == TripMode.edit ? '请点击日期栏“添加日期”开始规划' :
        _tripData.days.isEmpty ? '此行程暂无日期安排' : '请选择一个日期查看活动',
          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ));
    }
    final currentDay = _tripData.days[_selectedDayIndex];

    int itemCount = currentDay.activities.length;
    if (_currentMode == TripMode.edit) {
      itemCount++;
    }

    if (itemCount == 0 && _currentMode != TripMode.edit) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text('本日暂无活动安排', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16,16,16,16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_currentMode == TripMode.edit && index == currentDay.activities.length) {
          return _buildAddActivityCard();
        }
        final activity = currentDay.activities[index];
        final bool showConnector = index < currentDay.activities.length - 1;
        return ActivityCard(
          activity: activity,
          mode: _currentMode,
          showConnector: showConnector,
          onTap: _currentMode == TripMode.edit ? () => _editActivity(currentDay, activity, index) : null,
          onStatusChange: _currentMode == TripMode.travel ? (status) {
            if(mounted) {
              setState(() {
                activity.status = status;
                if (status == ActivityStatus.completed) _checkAndAdvanceOngoingActivity(currentDay, index);
              });
            }
          } : null,
        );
      },
    );
  }

  Widget _buildAddActivityCard() {
    return InkWell(
      onTap: _addActivityToCurrentDay,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1.0,
        margin: const EdgeInsets.only(bottom: 16, left: 24 + 16.0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5), style: BorderStyle.solid, width: 1.5)
        ),
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 8),
                Text('添加新活动', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomViewSwitcherBar() {
    return BottomNavigationBar(
      currentIndex: _currentMainViewIndex,
      onTap: (index) {
        _mainContentPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: "行程", activeIcon: Icon(Icons.list_alt_rounded)),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "地图", activeIcon: Icon(Icons.map_rounded)),
        BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: "票夹", activeIcon: Icon(Icons.confirmation_number_rounded)),
      ],
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      elevation: 8.0,
    );
  }

  Widget _buildAiChatInputBarStyled() {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).padding.bottom * 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              ),
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => _sendAiMessage(text),
            ),
          ),
          IconButton(
            icon: Icon(Icons.mic_none_outlined, color: Theme.of(context).primaryColor.withOpacity(0.9)),
            tooltip: '语音输入',
            onPressed: () { /* TODO: 语音输入 */ },
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
            tooltip: '发送',
            onPressed: () => _sendAiMessage(_aiTextController.text),
          ),
        ],
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: true, // AppBar is part of CustomScrollView, so top SafeArea is needed here
        bottom: false, // AI input bar handles its own bottom padding if visible
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: _currentMode == TripMode.view ? 320.0 : 280.0,
                    floating: false, // Set to false if you want it to only appear when scrolling to top
                    pinned: true,    // Makes the collapsed AppBar stick
                    stretch: true,
                    backgroundColor: Colors.white,
                    elevation: 0.5,
                    automaticallyImplyLeading: true,
                    iconTheme: IconThemeData(color: Colors.grey[800]),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: _buildCoverAndTitleSectionWidget(context),
                      // You might want a title here for when it's collapsed
                      // title: _currentMode != TripMode.view ? Text("编辑中...") : null,
                      // centerTitle: true,
                    ),
                  ),
                  // Date capsule bar as a SliverPersistentHeader
                  _buildDateCapsuleBarSliver(),

                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _buildMainContentPageView(),
                  ),
                ],
              ),
            ),
            _buildBottomViewSwitcherBar(),
            if (_showAiChat) _buildAiChatInputBarStyled(),
          ],
        ),
      ),
    );
  }
}

// _SliverAppBarDelegate 辅助类
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;
  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => max(maxHeight, minHeight);
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
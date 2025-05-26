// lib/trips/presentation/pages/trip_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math'; // For random ID generation (temp)
import 'package:dotted_border/dotted_border.dart'; // Ensure this is in your pubspec.yaml

// Import actual sub-widget files if they exist and are used.
// For this complete file, sub-widgets are defined as private methods.
// import '../widgets/activity_card_widget.dart'; // Now defined as _StyledActivityCard method
import '../widgets/map_view_widget.dart';
import '../widgets/ticket_view_widget.dart';

// --- Model Classes and Enums (Should ideally be in separate files) ---
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
  Activity({ required this.id, required this.time, required this.description, this.location, this.transportToNext, this.transportDuration, this.status = ActivityStatus.pending });
}
class TripDay {
  final int dayNumber;
  final DateTime date;
  final List<Activity> activities;
  String notes;
  TripDay({ required this.dayNumber, required this.date, required this.activities, this.notes = '' });
}
class Trip {
  final String id;
  String name;
  List<TripDay> days;
  String? coverImageUrl;
  Trip({ required this.id, required this.name, required this.days, this.coverImageUrl });
}
class Ticket {
  final String id;
  final String type;
  final String name;
  final DateTime dateTime;
  final String details;
  Ticket({required this.id, required this.type, required this.name, required this.dateTime, required this.details});
}
// --- End of Model/Enum Definitions ---



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

  bool _isAiChatExpanded = false;
  final TextEditingController _aiTextController = TextEditingController();
  final FocusNode _aiFocusNode = FocusNode();

  // Sample Data
  final Map<String, Trip> _sampleTrips = {
    '1': Trip(id: '1', name: '三亚海岛度假', coverImageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmVhY2h8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=800&q=60', days: [
      TripDay(dayNumber: 1, date: DateTime(2025, 6, 1), activities: [
        Activity(id: 'a1', time: '09:00', description: '抵达三亚凤凰国际机场，前往酒店', location: '三亚凤凰国际机场', transportToNext: '打车', transportDuration: '约30分钟'),
        Activity(id: 'a2', time: '13:30', description: '酒店入住及午餐', location: '三亚海棠湾喜来登度假酒店', status: ActivityStatus.completed),
        Activity(id: 'a3', time: '15:00', description: '亚龙湾沙滩漫步与水上活动', location: '亚龙湾国家旅游度假区', status: ActivityStatus.ongoing),
      ], notes: "第一天笔记：天气晴朗，心情愉悦！记得涂防晒。"),
      TripDay(dayNumber: 2, date: DateTime(2025, 6, 2), activities: [
        Activity(id: 'b1', time: '10:00', description: '蜈支洲岛潜水和水上活动', location: '蜈支洲岛'),
        Activity(id: 'b2', time: '18:00', description: '海鲜大餐', location: '第一市场附近'),
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
    _sampleTrips[_tripData.id] = _tripData;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程已保存 (模拟)')));
    if(mounted) {
      setState(() {
        _currentMode = TripMode.view;
        _isAiChatExpanded = false;
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
    if (currentDay.activities.isNotEmpty) {
      _editActivity(currentDay, currentDay.activities.last, currentDay.activities.length -1);
    }
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
                TextField(controller: timeController, decoration: const InputDecoration(labelText: '时间 (如 09:00)')),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Colors.grey.shade200,
                    image: _tripData.coverImageUrl != null && _tripData.coverImageUrl!.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(_tripData.coverImageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                    )
                        : DecorationImage( // 使用非 const 的 AssetImage
                      image: const AssetImage('assets/images/default_cover.png'), // 确保图片路径正确且在pubspec.yaml中声明
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                    )
                ),
              ),
              if (_currentMode == TripMode.edit)
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20)
                  ),
                ),
              Container(
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
                  _tripData.name,
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
        if (_currentMode == TripMode.view) _buildViewModeActionButtonsStyled(),
        if (_currentMode == TripMode.edit) _buildEditModeActionButtonsStyled(),
        if (_currentMode == TripMode.travel) _buildTravelModeHeaderInfoStyled(),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: "行程名称"),
                        ),
                        const SizedBox(height: 16),
                        Text("封面图片URL (可选):", style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        TextField(
                          decoration: const InputDecoration(hintText: "粘贴图片URL或留空"),
                          controller: TextEditingController(text: tempCoverUrl),
                          onChanged: (value) {
                            tempCoverUrl = value.isNotEmpty ? value : null;
                          },
                        ),
                        if (tempCoverUrl != null && tempCoverUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                tempCoverUrl!,
                                height: 80, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => Container(height: 60, color: Colors.grey[200], child: Center(child: Text("图片预览失败", style: TextStyle(color: Colors.red.shade700, fontSize: 12)))),
                              ),
                            ),
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
          Expanded(child: _buildStyledButton(context, label: '编辑行程', icon: Icons.edit_note_outlined, onPressed: () { if(mounted) setState(() { _currentMode = TripMode.edit; }); })),
          const SizedBox(width: 12),
          Expanded(child: _buildStyledButton(context, label: '开始旅行', icon: Icons.navigation_outlined, onPressed: () {
            if(mounted) {
              setState(() {
                _currentMode = TripMode.travel;
                if (_tripData.days.isNotEmpty && _selectedDayIndex >=0 && _selectedDayIndex < _tripData.days.length) {
                  final currentDay = _tripData.days[_selectedDayIndex];
                  for (var act in currentDay.activities) { act.status = ActivityStatus.pending; }
                  _checkAndAdvanceOngoingActivity(currentDay, -1);
                }
              });
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
          IconButton(icon: Icon(Icons.undo_outlined, color: Colors.grey[700]), tooltip: '撤销', onPressed: () {/* TODO */}),
          IconButton(icon: Icon(Icons.history_outlined, color: Colors.grey[700]), tooltip: '历史版本', onPressed: () {/* TODO */}),
          const SizedBox(width: 8),
          _buildStyledButton(context, label: '保存', icon: Icons.save_alt_outlined, onPressed: _saveTripAndSwitchToViewMode, isPrimary: true)
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
              onPressed: (){ if(mounted) setState(() { _currentMode = TripMode.view; _isAiChatExpanded = false; }); },
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: const Text("结束旅行")
          )
        ],
      ),
    );
  }

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
                    backgroundColor: Colors.grey[50],
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
    if (_tripData.days.isEmpty || _selectedDayIndex < 0 || _selectedDayIndex >= _tripData.days.length) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0), // Added padding
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
        padding: const EdgeInsets.all(20.0), // Added padding
        child: Text(
          _tripData.days.isEmpty && _currentMode == TripMode.edit ? '请点击日期栏“添加日期”开始规划' :
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

    if (itemCount == 0 && _currentMode != TripMode.edit) { // Can be 1 in edit mode for add button
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0), // Added padding
        child: Text('本日暂无活动安排', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16,16,16,16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_currentMode == TripMode.edit && index == currentDay.activities.length) {
          return _buildAddActivityCardStyled();
        }
        final activity = currentDay.activities[index];
        // showConnector is now handled within _StyledActivityCard based on its position
        return _StyledActivityCard(
          activity: activity,
          mode: _currentMode,
          // showConnector: index < currentDay.activities.length - 1, // Pass this explicitly
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

  Widget _buildAddActivityCardStyled() {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, bottom: 16), // Adjusted left padding to align with activity cards' content area
      child: InkWell(
        onTap: _addActivityToCurrentDay,
        borderRadius: BorderRadius.circular(16),
        child: DottedBorder(
          color: Theme.of(context).primaryColor.withOpacity(0.6),
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          radius: const Radius.circular(16),
          borderType: BorderType.RRect,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16)
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).primaryColor.withOpacity(0.8), size: 22),
                  const SizedBox(width: 10),
                  Text('添加新活动', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor.withOpacity(0.9))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomViewSwitcherBarSliver() { // This now returns a SliverPersistentHeader
    return SliverPersistentHeader(
      pinned: true, // Will stick below the main SliverAppBar AND DateCapsuleBarSliver
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
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) { // Added ? for currentChild
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
        elevation: 0.0, // Removed shadow from here
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.pin,
                          background: _buildCoverAndTitleSectionWidget(context),
                        ),
                      ),
                      _buildBottomViewSwitcherBarSliver(), // Moved here
                      _buildDateCapsuleBarSliver(),
                      SliverFillRemaining(
                        hasScrollBody: true,
                        child: _buildMainContentPageView(),
                      ),
                    ],
                  ),
                ),
                // Removed _buildBottomViewSwitcherBar() from here
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

// _StyledActivityCard (The new styled card for activities)
// Placed within the same file for simplicity, but ideally in its own widget file.
class _StyledActivityCard extends StatelessWidget {
  final Activity activity;
  final TripMode mode;
  // final bool showConnector; // Connector logic is now part of its parent Stack
  final VoidCallback? onTap;
  final ValueChanged<ActivityStatus>? onStatusChange;

  const _StyledActivityCard({
    // super.key, // Key can be omitted
    required this.activity,
    required this.mode,
    // required this.showConnector,
    this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = mode == TripMode.travel && activity.status == ActivityStatus.ongoing;
    final isCompleted = mode == TripMode.travel && activity.status == ActivityStatus.completed;

    Color cardBackgroundColor = Colors.white;
    Color titleColor = Colors.grey.shade800;
    Color subtitleColor = Colors.grey.shade600;
    Color iconColor = Colors.grey.shade500;
    BoxBorder? border;
    double elevation = 0.5;

    if (isOngoing) {
      cardBackgroundColor = Theme.of(context).primaryColor.withOpacity(0.08);
      titleColor = Theme.of(context).primaryColorDark ?? Theme.of(context).primaryColor; // Fallback
      subtitleColor = Theme.of(context).primaryColor;
      iconColor = Theme.of(context).primaryColor;
      border = Border.all(color: Theme.of(context).primaryColor.withOpacity(0.6), width: 1.5);
      elevation = 2.0;
    } else if (isCompleted) {
      cardBackgroundColor = Colors.transparent;
      titleColor = Colors.grey.shade500;
      subtitleColor = Colors.grey.shade400;
      iconColor = Colors.grey.shade400;
      border = Border.all(color: Colors.grey.shade300, width: 1);
      elevation = 0.0;
    }

    return InkWell(
      onTap: mode == TripMode.edit ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: border,
          boxShadow: elevation > 0 ? [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isOngoing ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  Icons.location_on_outlined,
                  color: iconColor,
                  size: 26
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.description,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: Colors.grey.shade400,
                      decorationThickness: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: activity.location != null && activity.location!.isNotEmpty ? 6 : 2),
                  if (activity.location != null && activity.location!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.pin_drop_outlined, size: 14, color: subtitleColor.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.location!,
                            style: TextStyle(fontSize: 13, color: subtitleColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: activity.time.isNotEmpty ? 6 : 2),
                  if (activity.time.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 14, color: subtitleColor.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          activity.time,
                          style: TextStyle(fontSize: 13, color: subtitleColor),
                        ),
                      ],
                    ),

                  if (mode == TripMode.travel) ...[
                    const SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: ActivityStatus.values.map((s) {
                        bool isCurrent = activity.status == s;
                        String statusText;
                        Color chipBgColor;
                        Color chipLabelColor;
                        BorderSide chipBorder = BorderSide.none;

                        switch (s) {
                          case ActivityStatus.pending:
                            statusText = "待办";
                            chipBgColor = isCurrent ? Colors.orange.shade100 : Colors.grey.shade100;
                            chipLabelColor = isCurrent ? Colors.orange.shade800 : Colors.grey.shade600;
                            if(isCurrent) chipBorder = BorderSide(color: Colors.orange.shade300);
                            break;
                          case ActivityStatus.ongoing:
                            statusText = "进行中";
                            chipBgColor = isCurrent ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.1);
                            chipLabelColor = isCurrent ? Colors.white : (Theme.of(context).primaryColorDark ?? Theme.of(context).primaryColor);
                            if(isCurrent) chipBorder = BorderSide(color: Theme.of(context).primaryColor.withAlpha(150));
                            break;
                          case ActivityStatus.completed:
                            statusText = "完成";
                            chipBgColor = isCurrent ? Colors.green.shade400 : Colors.green.shade50;
                            chipLabelColor = isCurrent ? Colors.white : Colors.green.shade700;
                            if(isCurrent) chipBorder = BorderSide(color: Colors.green.shade600);
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(statusText, style: TextStyle(fontSize: 11, color: chipLabelColor, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                            backgroundColor: chipBgColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: chipBorder),
                            pressElevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                            onPressed: () {
                              if (onStatusChange != null) onStatusChange!(s);
                            },
                          ),
                        );
                      }).toList(),
                    )
                  ] else if (mode == TripMode.edit) ...[
                    const SizedBox(height: 8.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.edit_note_outlined, color: Colors.grey.shade400, size: 20),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
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
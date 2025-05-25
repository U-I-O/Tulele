// lib/create_trip_details_page.dart
import 'package:flutter/material.dart';
import 'itinerary_editor_page.dart';

class CreateTripDetailsPage extends StatefulWidget {
  const CreateTripDetailsPage({super.key, this.initialTripName});
  final String? initialTripName;

  @override
  State<CreateTripDetailsPage> createState() => _CreateTripDetailsPageState();
}

class _CreateTripDetailsPageState extends State<CreateTripDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tripNameController;
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _allTags = [
    '性价比', '高质量', '亲子', '美食', '文化', '自然', '购物', '度假', '冒险'
  ];
  final Set<String> _selectedTags = {};
  final TextEditingController _customTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.initialTripName ?? '');
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('zh'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
            dialogBackgroundColor: Colors.white,
            buttonTheme: ButtonThemeData(
                textTheme: ButtonTextTheme.primary,
                colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor)
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate == null || (_endDate != null && picked.isAfter(_endDate!))) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && picked.isBefore(_startDate!)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  void _addCustomTag() {
    final String tag = _customTagController.text.trim();
    if (tag.isNotEmpty && !_allTags.contains(tag) && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
      });
      _customTagController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('填写行程信息'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionTitle('行程名称'),
              TextFormField(
                controller: _tripNameController,
                decoration: const InputDecoration(
                  hintText: '例如：北京三日游',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入行程名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              _buildSectionTitle('出发地/目的地'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _departureController,
                      decoration: const InputDecoration(
                        hintText: '出发地',
                        prefixIcon: Icon(Icons.flight_takeoff_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入出发地';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextFormField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        hintText: '目的地',
                        prefixIcon: Icon(Icons.flight_land_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入目的地';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              _buildSectionTitle('出发日期 / 结束日期'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: '选择日期',
                          suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor, size: 20),
                        ),
                        child: Text(
                          _startDate != null
                              ? "${_startDate!.year}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')}"
                              : '出发日期',
                          style: TextStyle(
                            color: _startDate != null ? Theme.of(context).colorScheme.onSurface : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: '选择日期',
                          suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor, size: 20),
                        ),
                        child: Text(
                          _endDate != null
                              ? "${_endDate!.year}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}"
                              : '结束日期',
                          style: TextStyle(
                            color: _endDate != null ? Theme.of(context).colorScheme.onSurface : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_startDate == null || _endDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _startDate == null && _endDate == null ? '请选择出发和结束日期' :
                    _startDate == null ? '请选择出发日期' : '请选择结束日期',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '结束日期不能早于出发日期',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24.0),

              _buildSectionTitle('旅游标签'),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: _allTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customTagController,
                      decoration: const InputDecoration(
                        hintText: '自定义标签...',
                        prefixIcon: Icon(Icons.label_outline, size: 20),
                      ),
                      onFieldSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  TextButton(
                    onPressed: _addCustomTag,
                    child: const Text('添加标签'),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('返回'),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_startDate == null || _endDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请选择完整的出行日期')),
                            );
                            return;
                          }
                          if (_endDate!.isBefore(_startDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('结束日期不能早于出发日期')),
                            );
                            return;
                          }

                          // *** 修改点：确保 tripData['days'] 是一个 List<Map<String, dynamic>> ***
                          final List<Map<String, dynamic>> daysList = [
                            {
                              'dayNumber': 1,
                              'date': _startDate,
                              'title': '${_startDate!.month}月${_startDate!.day}日, 星期X', // 星期X/Y是占位符
                              'activities': [
                                {'time': '09:00 - 12:30', 'description': '抵达${_destinationController.text}', 'details': '航班号XXX, 前往酒店'},
                                {'time': '13:30 - 14:30', 'description': '酒店入住', 'details': '酒店名称, 享受下午茶'},
                                {'time': '15:00 - 18:00', 'description': '初步探索${_destinationController.text}', 'details': '例如：${_destinationController.text}市中心逛逛'},
                              ]
                            }
                          ];

                          if (_endDate!.isAfter(_startDate!)) {
                            int duration = _endDate!.difference(_startDate!).inDays;
                            for (int i = 1; i <= duration; i++) {
                              DateTime currentDate = _startDate!.add(Duration(days: i));
                              daysList.add({ // *** 修改点：直接 add 到 daysList ***
                                'dayNumber': i + 1,
                                'date': currentDate,
                                'title': '${currentDate.month}月${currentDate.day}日, 星期Y',
                                'activities': [
                                  {'time': '全天', 'description': '自由活动或根据AI推荐', 'details': '本日详细安排待定'}
                                ]
                              });
                            }
                          }

                          final tripData = {
                            'name': _tripNameController.text,
                            'departure': _departureController.text,
                            'destination': _destinationController.text,
                            'startDate': _startDate,
                            'endDate': _endDate,
                            'tags': _selectedTags.toList(),
                            'days': daysList, // *** 修改点：使用 daysList ***
                          };


                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItineraryEditorPage(tripData: tripData),
                            ),
                          );
                        }
                      },
                      child: const Text('下一步 (编辑行程)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _departureController.dispose();
    _destinationController.dispose();
    _customTagController.dispose();
    super.dispose();
  }
}
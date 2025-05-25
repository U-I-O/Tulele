// lib/trips/presentation/pages/create_trip_details_page.dart
import 'package:flutter/material.dart';
// *** 修改点：导入新的 trip_detail_page.dart ***
import 'trip_detail_page.dart'; // 假设模型和枚举也在此文件或可从此文件访问
import 'dart:math'; // 用于生成随机ID

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
        title: const Text('填写行程基础信息'), // 更改标题更准确
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
                        Navigator.of(context).pop(); // 简单返回上一页
                      },
                      child: const Text('上一步'), // 按钮文字改为上一步
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

                          // *** 修改点：为新行程生成唯一ID并准备初始数据 ***
                          final String newTripId = 'new_trip_${DateTime.now().millisecondsSinceEpoch}';
                          
                          // 构建初始的每日安排框架
                          final List<Map<String, dynamic>> initialDaysData = [];
                          int duration = _endDate!.difference(_startDate!).inDays;
                          for (int i = 0; i <= duration; i++) { // 从0开始，包含起始日和结束日
                              DateTime currentDate = _startDate!.add(Duration(days: i));
                              initialDaysData.add({
                                'dayNumber': i + 1,
                                'date': currentDate,
                                // 星期几可以在 TripDetailPage 中格式化，或在这里计算
                                'title': '${currentDate.month}月${currentDate.day}日', 
                                'activities': [], // 初始为空活动列表
                                'notes': '', // 初始为空笔记
                              });
                          }

                          final Map<String, dynamic> newTripInitialData = {
                            'name': _tripNameController.text,
                            'departure': _departureController.text, // 虽然没直接用，但可以传递
                            'destination': _destinationController.text, // 同上
                            'startDate': _startDate, // 同上
                            'endDate': _endDate, // 同上
                            'tags': _selectedTags.toList(), // 同上
                            'days': initialDaysData,
                          };

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripDetailPage(
                                tripId: newTripId, // 传递新ID
                                initialMode: TripMode.edit, // 以编辑模式打开
                                newTripInitialData: newTripInitialData, // 传递初始数据
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('下一步 (编辑日程)'),
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
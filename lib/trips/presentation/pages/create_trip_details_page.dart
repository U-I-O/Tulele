// lib/trips/presentation/pages/create_trip_details_page.dart
import 'package:flutter/material.dart';
import 'trip_detail_page.dart'; 
import 'dart:math'; 

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

  late Color _primaryColor;
  late Color _lightPrimaryColor;
  late Color _inputFillColor;
  late TextStyle _inputTextStyle;
  late TextStyle _hintTextStyle;
  late InputDecoration _baseInputDecoration; // Changed from InputDecorationTheme

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.initialTripName ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _primaryColor = Theme.of(context).primaryColor;
    _lightPrimaryColor = _primaryColor.withOpacity(0.1);
    _inputFillColor = Colors.grey.shade100.withOpacity(0.7);
    _inputTextStyle = TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface);
    _hintTextStyle = TextStyle(fontSize: 16, color: Colors.grey.shade500);
    
    // Define a base InputDecoration object
    _baseInputDecoration = InputDecoration(
      filled: true,
      fillColor: _inputFillColor,
      hintStyle: _hintTextStyle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none, 
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
      ),
      prefixIconColor: Colors.grey.shade600,
      suffixIconColor: _primaryColor,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('zh'),
       builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith( 
            colorScheme: ColorScheme.light(
              primary: _primaryColor, 
              onPrimary: Colors.white, 
              surface: Colors.white, 
              onSurface: Colors.grey.shade800, 
            ),
            dialogBackgroundColor: Colors.white,
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
               colorScheme: ColorScheme.light(primary: _primaryColor)
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: _primaryColor,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              dayStyle: TextStyle(color: Colors.grey.shade700),
              weekdayStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
              yearStyle: TextStyle(color: Colors.grey.shade700),
            )
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
        backgroundColor: Colors.white, 
        foregroundColor: Colors.grey.shade800, 
        elevation: 0.5, 
      ),
      backgroundColor: Colors.white, 
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
                style: _inputTextStyle,
                decoration: _baseInputDecoration.copyWith( 
                  hintText: '例如：北京三日游',
                  prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入行程名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              _buildSectionTitle('出发地与目的地'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _departureController,
                      style: _inputTextStyle,
                      decoration: _baseInputDecoration.copyWith(
                        hintText: '出发地',
                        prefixIcon: const Icon(Icons.flight_takeoff_outlined, size: 20),
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
                      style: _inputTextStyle,
                      decoration: _baseInputDecoration.copyWith(
                        hintText: '目的地',
                        prefixIcon: const Icon(Icons.flight_land_outlined, size: 20),
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

              _buildSectionTitle('选择日期'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: _inputFillColor,
                          borderRadius: BorderRadius.circular(10.0),
                           border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _startDate != null
                                  ? "${_startDate!.year}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')}"
                                  : '出发日期',
                              style: _startDate != null ? _inputTextStyle : _hintTextStyle,
                            ),
                            Icon(Icons.calendar_month_outlined, color: _primaryColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                         decoration: BoxDecoration(
                          color: _inputFillColor,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              _endDate != null
                                  ? "${_endDate!.year}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}"
                                  : '结束日期',
                              style: _endDate != null ? _inputTextStyle : _hintTextStyle,
                            ),
                            Icon(Icons.calendar_month_outlined, color: _primaryColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_startDate == null || _endDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    _startDate == null && _endDate == null ? '请选择出发和结束日期' :
                    _startDate == null ? '请选择出发日期' : '请选择结束日期',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    '结束日期不能早于出发日期',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24.0),

              _buildSectionTitle('旅行标签'),
              Wrap(
                spacing: 8.0, 
                runSpacing: 8.0,
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
                    backgroundColor: Colors.grey.shade200.withOpacity(0.6),
                    selectedColor: _lightPrimaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? _primaryColor : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13
                    ),
                    checkmarkColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0), 
                      side: BorderSide(
                        color: isSelected ? _primaryColor.withOpacity(0.5) : Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0), 
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customTagController,
                      style: _inputTextStyle,
                      decoration: _baseInputDecoration.copyWith(
                        hintText: '自定义标签...',
                        prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                      ),
                      onFieldSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  ElevatedButton.icon( 
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('添加'),
                    onPressed: _addCustomTag,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
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
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        side: BorderSide(color: _primaryColor, width: 1.5),
                        foregroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                      child: const Text('上一步'), 
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_startDate == null || _endDate == null) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('请选择完整的出行日期', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
                            );
                            return;
                          }
                           if (_endDate!.isBefore(_startDate!)) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('结束日期不能早于出发日期', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
                            );
                            return;
                          }

                          final String newTripId = 'new_trip_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
                          
                          final List<Map<String, dynamic>> initialDaysData = [];
                          int duration = _endDate!.difference(_startDate!).inDays;
                          for (int i = 0; i <= duration; i++) { 
                              DateTime currentDate = _startDate!.add(Duration(days: i));
                              initialDaysData.add({
                                'dayNumber': i + 1,
                                'date': currentDate,
                                'title': '${currentDate.month}月${currentDate.day}日', 
                                'activities': [], 
                                'notes': '', 
                              });
                          }

                          final Map<String, dynamic> newTripInitialData = {
                            'id': newTripId, 
                            'name': _tripNameController.text,
                            'departure': _departureController.text, 
                            'destination': _destinationController.text, 
                            'startDate': _startDate, 
                            'endDate': _endDate, 
                            'tags': _selectedTags.toList(), 
                            'days': initialDaysData,
                            'color': Colors.primaries[Random().nextInt(Colors.primaries.length)].shade300, 
                            'status': '已计划', 
                          };

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripDetailPage(
                                tripId: newTripId, 
                                initialMode: TripMode.edit, 
                                newTripInitialData: newTripInitialData, 
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        elevation: 2,
                      ),
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
      padding: const EdgeInsets.only(bottom: 14.0, top: 10.0), 
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17.0, 
          fontWeight: FontWeight.w600, 
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.85), 
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
// lib/trips/presentation/pages/activity_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoDatePicker
import '../../../core/models/api_user_trip_model.dart';
import 'place_search_page.dart'; // 导入地点搜索页和PoiInfo

class ActivityEditPage extends StatefulWidget {
  final ApiActivityFromUserTrip? initialActivity;
  final DateTime? dayDate;

  const ActivityEditPage({super.key, this.initialActivity, required this.dayDate});

  @override
  State<ActivityEditPage> createState() => _ActivityEditPageState();
}

class _ActivityEditPageState extends State<ActivityEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _locationNameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _transportController;
  late TextEditingController _iconController;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double? _latitude;
  double? _longitude;

  final FocusNode _nameFocusNode = FocusNode(); // 用于自动聚焦

  @override
  void initState() {
    super.initState();
    final activity = widget.initialActivity;
    _nameController = TextEditingController(text: activity?.title ?? '');
    _locationNameController = TextEditingController(text: activity?.location ?? '');
    _addressController = TextEditingController(text: activity?.address ?? '');
    _descriptionController = TextEditingController(text: activity?.description ?? '');
    _notesController = TextEditingController(text: activity?.note ?? '');
    _transportController = TextEditingController(text: activity?.transportation ?? '');
    _iconController = TextEditingController(text: activity?.icon ?? '');

    if (activity?.startTime != null) {
      try {
        final parts = activity!.startTime!.split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }
    if (activity?.endTime != null) {
      try {
        final parts = activity!.endTime!.split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }
     // 自动聚焦到活动名称
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _transportController.dispose();
    _iconController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }


  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    // ... (时间选择逻辑保持不变) ...
     TimeOfDay? initialTime = isStartTime ? _startTime : _endTime;
    if (initialTime == null && widget.dayDate != null) {
      initialTime = TimeOfDay.fromDateTime(widget.dayDate!);
    } else if (initialTime == null) {
      initialTime = TimeOfDay.now();
    }
    
    DateTime now = DateTime.now();
    DateTime initialDateTime = DateTime(
      widget.dayDate?.year ?? now.year,
      widget.dayDate?.month ?? now.month,
      widget.dayDate?.day ?? now.day,
      initialTime.hour,
      initialTime.minute
    );

    DateTime? pickedDateTime = initialDateTime; // 用于暂存CupertinoDatePicker的值

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // 使底部圆角可见
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () { 
                        setState(() {
                           if (isStartTime) _startTime = null; else _endTime = null;
                        });
                        Navigator.pop(context); 
                      }, 
                      child: const Text('清除时间', style: TextStyle(color: Colors.redAccent, fontSize: 16))
                    ),
                    Text(isStartTime ? "选择到达时间" : "选择离开时间", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () { 
                         if (pickedDateTime != null && mounted) {
                           setState(() {
                             if (isStartTime) {
                               _startTime = TimeOfDay.fromDateTime(pickedDateTime!);
                             } else {
                               _endTime = TimeOfDay.fromDateTime(pickedDateTime!);
                             }
                           });
                         }
                         Navigator.pop(context); 
                      }, 
                      child: Text('确认', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor))
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    pickedDateTime = newDateTime; 
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _navigateToPlaceSearch() async {
    // ... (地点搜索导航逻辑保持不变) ...
     final PoiInfo? selectedPoi = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlaceSearchPage()),
    );

    if (selectedPoi != null && mounted) {
      setState(() {
        _locationNameController.text = selectedPoi.name;
        _addressController.text = selectedPoi.address;
        _latitude = selectedPoi.latitude;
        _longitude = selectedPoi.longitude;
      });
    }
  }

  void _saveActivity() {
    // ... (保存活动逻辑保持不变) ...
     if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('活动名称不能为空')));
      return;
    }
    final newActivity = ApiActivityFromUserTrip(
      id: widget.initialActivity?.id,
      originalPlanActivityId: widget.initialActivity?.originalPlanActivityId,
      title: _nameController.text,
      location: _locationNameController.text.isNotEmpty ? _locationNameController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      startTime: _startTime != null ? "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}" : null,
      endTime: _endTime != null ? "${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}" : null,
      note: _notesController.text.isNotEmpty ? _notesController.text : null,
      transportation: _transportController.text.isNotEmpty ? _transportController.text : null,
      icon: _iconController.text.isNotEmpty ? _iconController.text : null,
      // coordinates: _latitude != null && _longitude != null ? {"latitude": _latitude!, "longitude": _longitude!} : null,
      durationMinutes: widget.initialActivity?.durationMinutes,
      type: widget.initialActivity?.type,
      actualCost: widget.initialActivity?.actualCost,
      bookingInfo: widget.initialActivity?.bookingInfo,
      userStatus: widget.initialActivity?.userStatus ?? 'todo',
    );
    Navigator.pop(context, newActivity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100], // 页面背景色
      appBar: AppBar(
        title: Text(widget.initialActivity == null ? '添加新活动' : '编辑活动', style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView( // 改为 ListView 以便更好地控制间距和分组
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildSectionContainer([
            _buildEditableItem(
              controller: _nameController,
              label: '活动名称*',
              hint: '例如：抵达，入住豪华酒店',
              focusNode: _nameFocusNode, // 传入FocusNode
            ),
          ]),
          _buildSectionContainer([
            _buildTappableItem(
              label: '地点名称',
              value: _locationNameController.text.isNotEmpty ? _locationNameController.text : '选择活动地点',
              onTap: _navigateToPlaceSearch,
              isEmpty: _locationNameController.text.isEmpty,
            ),
            if (_addressController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right:16, top: 0, bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: theme.primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_addressController.text, style: TextStyle(color: Colors.grey[700], fontSize: 14))),
                  ],
                ),
              ),
          ]),
           _buildSectionContainer([
            _buildTappableItem(
              label: '到达时间',
              value: _startTime?.format(context) ?? '选择时间',
              onTap: () => _selectTime(context, true),
              isEmpty: _startTime == null,
            ),
            const CustomDivider(),
            _buildTappableItem(
              label: '离开时间 (可选)',
              value: _endTime?.format(context) ?? '选择时间',
              onTap: () => _selectTime(context, false),
              isEmpty: _endTime == null,
            ),
          ]),
          _buildSectionContainer([
             _buildEditableItem(controller: _descriptionController, label: '活动描述 (可选)', hint: '例如：欣赏昆明湖景色'),
             const CustomDivider(),
             _buildEditableItem(controller: _notesController, label: '备注 (可选)', hint: '例如：记得带相机'),
             const CustomDivider(),
             _buildEditableItem(controller: _transportController, label: '到达此地的交通方式 (可选)', hint: '例如：地铁4号线'),
             const CustomDivider(),
             _buildEditableItem(controller: _iconController, label: '活动图标 (可选)', hint: '例如：landmark, food'),
          ]),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top:12),
        child: ElevatedButton(
          onPressed: _saveActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87, // 深色背景
            foregroundColor: Colors.white, // 白色文字
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 圆角
          ),
          child: const Text('确认添加/修改'),
        ),
      ),
    );
  }

  // 新的构建方法，用于包装一组编辑项
  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // 修改后的文本输入项
  Widget _buildEditableItem({
    required TextEditingController controller,
    required String label,
    String? hint,
    FocusNode? focusNode, // 添加FocusNode参数
    bool isRequired = false, // 标记是否必填
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            focusNode: focusNode, // 应用FocusNode
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none, // 无边框
              isDense: true,
              filled: true, // Explicitly control filling
              fillColor: Colors.transparent, // Set to transparent or Colors.white for white background
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // 修改后的可点击项
  Widget _buildTappableItem({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isEmpty = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 16, color: isEmpty ? Colors.grey[400] : Colors.black87),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义分割线 (如果需要的话)
class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }
}
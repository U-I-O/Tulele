// lib/trips/presentation/pages/trip_plan_edit_page.dart
import 'package:flutter/material.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/services/api_service.dart';
import 'dart:math';

class TripPlanEditPage extends StatefulWidget {
  final ApiUserTrip userTrip;
  const TripPlanEditPage({super.key, required this.userTrip});

  @override
  State<TripPlanEditPage> createState() => _TripPlanEditPageState();
}

class _TripPlanEditPageState extends State<TripPlanEditPage> {
  final ApiService _apiService = ApiService();
  late TextEditingController _planNameController;
  late TextEditingController _editableCoverImageUrlController;
  
  String _travelDurationDisplay = "请选择";
  List<ApiMember> _members = [];
  String _permissionSettingDisplay = "私密"; // 默认值
  DateTime? _pickedStartDate;
  DateTime? _pickedEndDate;

  final FocusNode _planNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _planNameController = TextEditingController(text: widget.userTrip.userTripNameOverride ?? widget.userTrip.displayName);
    _editableCoverImageUrlController = TextEditingController(text: widget.userTrip.coverImage ?? '');
    _members = List.from(widget.userTrip.members);
    _pickedStartDate = widget.userTrip.startDate;
    _pickedEndDate = widget.userTrip.endDate;

    if (_pickedStartDate != null && _pickedEndDate != null) {
      int duration = _pickedEndDate!.difference(_pickedStartDate!).inDays + 1;
      _travelDurationDisplay = "$duration 天";
    }
    
    // 根据实际的 publishStatus 初始化权限显示
    if (widget.userTrip.publishStatus == 'public') {
      _permissionSettingDisplay = '公开';
    } else if (widget.userTrip.publishStatus == 'private_link') { // 假设有这个状态
        _permissionSettingDisplay = '链接分享';
    } else {
       _permissionSettingDisplay = '私密';
    }
    // 自动聚焦到计划名称
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_planNameController.text.isEmpty) { // 如果名称为空，则聚焦
        FocusScope.of(context).requestFocus(_planNameFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _editableCoverImageUrlController.dispose();
    _planNameFocusNode.dispose();
    super.dispose();
  }

  void _inviteMember() { /* ... (逻辑不变) ... */ 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("邀请成员功能待实现")));
  }
  
  void _selectTravelTime() async { /* ... (逻辑不变) ... */ 
     final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        helpText: "选择旅行日期范围",
        cancelText: "取消",
        confirmText: "确认",
        builder: (context, child) { // 主题定制
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor, // header background color
                onPrimary: Colors.white, // header text color
                onSurface: Colors.black, // body text color
              ),
              dialogBackgroundColor:Colors.white,
            ),
            child: child!,
          );
        },
        firstDate: DateTime(DateTime.now().year - 5),
        lastDate: DateTime(DateTime.now().year + 5),
        initialDateRange: _pickedStartDate != null && _pickedEndDate != null
            ? DateTimeRange(start: _pickedStartDate!, end: _pickedEndDate!)
            : null,
      );
      if (picked != null && mounted) {
        setState(() {
          _pickedStartDate = picked.start;
          _pickedEndDate = picked.end;
          int duration = _pickedEndDate!.difference(_pickedStartDate!).inDays + 1;
          _travelDurationDisplay = "$duration 天";
        });
      }
  }

  Future<void> _savePlanChanges() async { /* ... (逻辑不变) ... */ 
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在保存计划详情...')));

    Map<String, dynamic> updatesPayload = {
      'user_trip_name_override': _planNameController.text,
      'coverImage': _editableCoverImageUrlController.text.isNotEmpty ? _editableCoverImageUrlController.text : null,
      'startDate': _pickedStartDate?.toIso8601String().substring(0,10),
      'endDate': _pickedEndDate?.toIso8601String().substring(0,10),
      // 'members': _members.map((m) => m.toJson()).toList(), // 如果成员可编辑
      // 'publish_status': _permissionSettingDisplay == "公开" ? "public" : (_permissionSettingDisplay == "链接分享" ? "private_link" : "private") ,
    };

    try {
      await _apiService.updateUserTrip(widget.userTrip.id, updatesPayload);
      if (mounted) {
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('计划详情保存成功！'), backgroundColor: Colors.green));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(SnackBar(
          content: Text('保存失败: ${e.toString().substring(0, min(e.toString().length, 100))}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
  
  void _deletePlan() async { /* ... (逻辑不变) ... */ 
    final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('确认删除'),
            content: const Text('您确定要删除此行程计划吗？此操作无法撤销。'),
            actions: <Widget>[
              TextButton(child: const Text('取消'), onPressed: () => Navigator.of(context).pop(false)),
              TextButton(child: const Text('删除', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
            ],
          );
        },
      );
      if (confirmDelete == true && mounted) {
        Navigator.pop(context, "DELETE_PLAN"); 
      }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100], // 页面背景色
      appBar: AppBar(
        title: const Text('编辑计划', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView( // 使用ListView代替Column以便滚动
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: <Widget>[
          _buildCoverImageEditSection(theme), 
          const SizedBox(height: 16),
          _buildEditableItem(
            theme: theme,
            label: '计划名称',
            controller: _planNameController,
            focusNode: _planNameFocusNode,
            hintText: '给你的计划起个名字吧',
            maxLength: 25,
          ),
          const SizedBox(height: 16),
          _buildTappableItem(
            theme: theme,
            label: '旅行时间',
            value: _travelDurationDisplay,
            onTap: _selectTravelTime,
          ),
          const SizedBox(height: 16),
          _buildMembersSection(theme),
          const SizedBox(height: 16),
          _buildTappableItem(
            theme: theme,
            label: '权限设置',
            value: _permissionSettingDisplay,
            onTap: () { 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("权限设置待实现")));
            },
          ),
          const SizedBox(height: 40), // 增加底部间距
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top:12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _savePlanChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87, // 深色背景
                foregroundColor: Colors.white, // 白色文字
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('保存'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _deletePlan,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.7)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('删除计划'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageEditSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("封面图片 URL (可选)", style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          TextField(
            controller: _editableCoverImageUrlController,
            decoration: InputDecoration(
              hintText: '粘贴图片链接...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder( // Current border
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300)
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300)
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: theme.primaryColor, width: 1.5)
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              isDense: true,
              filled: true, // Add this
              fillColor: Colors.white, // Add this (or Colors.transparent if you prefer it to take the container's color)
            ),
            style: const TextStyle(fontSize: 15),
            onChanged: (value) {
              setState(() {}); 
            },
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _editableCoverImageUrlController.text.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _editableCoverImageUrlController.text,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Center(child: Text('图片加载失败', style: TextStyle(color: Colors.redAccent))),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItem({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hintText,
    int? maxLength,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.end,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hintText ?? '请输入$label',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                counterText: "", 
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: true, // Add this
                fillColor: Colors.white, // Add this (or Colors.transparent)
              ),
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ),
          // if (maxLength == null) // 通常可点击项才带箭头，输入项通过 hintText 引导
          //   const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTappableItem({
    required ThemeData theme,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('计划成员', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _members.length + 1, 
              itemBuilder: (context, index) {
                if (index == _members.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: InkWell(
                      onTap: _inviteMember,
                      borderRadius: BorderRadius.circular(27.5),
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1.5)
                        ),
                        child: Icon(Icons.add, color: Colors.grey[700], size: 28),
                      ),
                    ),
                  );
                }
                final member = _members[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: CircleAvatar(
                    radius: 27.5,
                    backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                        ? NetworkImage(member.avatarUrl!)
                        : null, 
                    child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                        ? Text(member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : "?", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                        : null,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
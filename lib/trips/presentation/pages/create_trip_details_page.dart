// lib/trips/presentation/pages/create_trip_details_page.dart
import 'package:flutter/material.dart';
// import 'dart:math'; // 如果不再需要前端生成唯一ID，可以移除

// 核心服务和模型
import '../../../core/services/api_service.dart';
import '../../../core/models/api_trip_plan_model.dart';
import '../../../core/models/api_user_trip_model.dart'; // 虽然不直接用构造函数，但 createUserTrip 的 payload 结构会参照它
import '../../../core/utils/auth_utils.dart';

import 'trip_detail_page.dart'; // 用于导航

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

  // UI相关的颜色和样式变量，在 didChangeDependencies 中初始化
  late Color _primaryColor;
  late Color _lightPrimaryColor;
  late Color _inputFillColor;
  late TextStyle _inputTextStyle;
  late TextStyle _hintTextStyle;
  late InputDecoration _baseInputDecoration;

  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.initialTripName ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 避免在每次重建时都重新计算这些颜色，但如果主题会动态改变，则需要保留在这里
    _primaryColor = Theme.of(context).primaryColor;
    _lightPrimaryColor = _primaryColor.withOpacity(0.1);
    _inputFillColor = Colors.grey.shade100.withOpacity(0.7);
    _inputTextStyle = TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface);
    _hintTextStyle = TextStyle(fontSize: 16, color: Colors.grey.shade500);
    
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
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // 例如，只能选最近一个月或未来
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('zh'),
       builder: (BuildContext context, Widget? child) { // 主题定制保持不变
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
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // 如果结束日期早于新的开始日期，或结束日期为空，则将结束日期也设为新的开始日期
          if (_endDate == null || picked.isAfter(_endDate!)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          // 如果开始日期晚于新的结束日期，则将开始日期也设为新的结束日期
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
      if (!mounted) return;
      setState(() {
        _selectedTags.add(tag);
        // 可以选择是否将自定义标签也加入到 _allTags 列表中，以便后续选择
        // _allTags.add(tag); 
      });
      _customTagController.clear();
    } else if (tag.isNotEmpty && (_allTags.contains(tag) || _selectedTags.contains(tag))) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('标签 "$tag" 已存在。')),
        );
    }
  }
  
  Future<void> _submitForm() async {
    if (_isSubmitting) return; // 防止重复提交

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

      if (!mounted) return;
      setState(() { _isSubmitting = true; });

      final messenger = ScaffoldMessenger.of(context); // 在 async gap 前获取
      
      try {
        // 构造 ApiTripPlan 对象
        final List<ApiPlanDay> initialDaysDataForPlan = [];
        if (_startDate != null && _endDate != null) {
          int durationDays = _endDate!.difference(_startDate!).inDays; // 注意这里是 durationDays -1 得到晚数
          for (int i = 0; i <= durationDays; i++) { // 循环次数是 天数
              DateTime currentDate = _startDate!.add(Duration(days: i));
              initialDaysDataForPlan.add(ApiPlanDay(
                dayNumber: i + 1,
                date: currentDate,
                // title: "第 ${i+1} 天", // 可以给每天一个默认标题
                // description: "",     // 默认描述
                activities: [],
                notes: '', // 这是 daily_notes (模板的每日备注)
              ));
          }
        }

        // 获取当前用户ID
        String? currentUserId = await AuthUtils.getCurrentUserId();
        // TODO: 从认证服务获取真实的用户名和头像, 或由后端自动填充
        String currentUsername = "当前用户"; // 占位符

        if (currentUserId == null) {
          throw Exception("无法获取当前用户信息，请重新登录。");
        }

        final newPlanData = ApiTripPlan(
          name: _tripNameController.text.trim(), // 对应 TripPlan.name
          creatorId: currentUserId, // TripPlan 的创建者 (可以是当前用户，也可以是系统)
          // creatorName: currentUsername, // 将由后端填充
          origin: _departureController.text.isNotEmpty ? _departureController.text.trim() : null,
          destination: _destinationController.text.isNotEmpty ? _destinationController.text.trim() : null,
          startDate: _startDate, // 模板的建议开始日期
          endDate: _endDate,   // 模板的建议结束日期
          durationDays: _startDate != null && _endDate != null ? _endDate!.difference(_startDate!).inDays + 1 : null,
          tags: _selectedTags.toList(),
          description: null, // 当前表单没有详细描述，可以后续编辑时添加
          coverImage: null,  // 同上
          days: initialDaysDataForPlan,
          // 以下是 TripPlan 作为市场方案核心时可能有的字段，创建时可留空或由后端设置默认值
          platformPrice: null, // 平台定价，初始创建时可能为null
          averageRating: null,
          reviewCount: 0,
          salesVolume: 0,
          usageCount: 0,
          // estimatedCostRange: "", // 示例，如果表单有此字段
          // suitability: [],
          // highlights: [],
          isFeaturedOnMarket: false, // 默认不精选
          // version: 1 // 初始版本
        );

        // 调用API创建 TripPlan
        // ApiService 的 createNewTripPlan 方法现在返回 Future<ApiTripPlan>
        final createdTripPlan = await _apiService.createNewTripPlan(newPlanData);
        if (!mounted) return;

        if (createdTripPlan.id == null) {
          throw Exception("创建旅行计划失败，未返回计划ID。");
        }

        // 准备创建 UserTrip 的数据 (payload 是 Map<String, dynamic>)
        final newUserTripPayload = {
          "plan_id": createdTripPlan.id!,
          "creator_id": currentUserId, // UserTrip 的创建者是当前用户
          // "creator_name": currentUsername, // 后端根据 creator_id 填充
          // "creator_avatar": currentUserAvatar, // 后端根据 creator_id 填充
          "user_trip_name_override": _tripNameController.text.trim(), // 用户可以自定义实例名称，初始可以和模板名一样
          
          // UserTrip 也复制一份核心规划信息 (这些信息用户可以在自己的UserTrip实例中修改，而不影响原始TripPlan)
          "origin": newPlanData.origin,
          "destination": newPlanData.destination,
          "startDate": newPlanData.startDate?.toIso8601String().substring(0,10), // 发送 YYYY-MM-DD
          "endDate": newPlanData.endDate?.toIso8601String().substring(0,10),   // 发送 YYYY-MM-DD
          "tags": newPlanData.tags,
          "description": newPlanData.description, // UserTrip 实例的描述
          "coverImage": newPlanData.coverImage,   // UserTrip 实例的封面

          // days 也应传递，并转换为 UserTrip 的 days 结构 (ApiDayFromUserTrip)
          // 注意：这里的 activities 内部的 activity_id 应该叫 user_activity_id，并且 original_plan_activity_id 指向模板的 activity_id
          "days": createdTripPlan.days.map((planDay) {
            return {
              "day_number": planDay.dayNumber,
              "date": planDay.date?.toIso8601String().substring(0,10),
              "title": planDay.title, // UserTrip day 的 title
              "description": planDay.description, // UserTrip day 的 description
              "activities": planDay.activities.map((planActivity) {
                return {
                  // "user_activity_id": get_random_object_id_str(), // UserTrip 中活动的唯一ID，应由后端生成或前端生成传递
                  "original_plan_activity_id": planActivity.id, // 引用模板活动的ID
                  "title": planActivity.title,
                  "location_name": planActivity.location, // 注意字段名差异
                  "address": null, // 如果模板中有
                  "coordinates": null, // 如果模板中有
                  "start_time": planActivity.startTime,
                  "end_time": planActivity.endTime,
                  "duration_minutes": null, // 如果模板中有
                  "type": null, // 如果模板中有
                  "actual_cost": null, // 用户实际花费
                  "booking_info": null,
                  "user_activity_notes": planActivity.note, // 模板活动的备注可以作为用户活动的初始备注
                  "user_status": "todo", // 用户感知的活动状态
                  "icon": null // 如果模板中有
                };
              }).toList(),
              "user_daily_notes": planDay.notes, // 模板的每日备注作为用户每日笔记的初始值
            };
          }).toList(),
          
          "members": [
            {
              "userId": currentUserId,
              // "name": currentUsername, // 后端填充
              // "avatarUrl": currentUserAvatar, // 后端填充
              "role": "owner"
            }
          ],
          "messages": [], // 初始化为空
          "tickets": [],  // 初始化为空
          "user_notes": [], // 初始化为空
          "publish_status": "draft",
          "travel_status": "planning",
          // "user_personal_rating": null, // 初始化为空
          // "user_personal_review": null, // 初始化为空
          // "submission_notes_to_admin": null,
          // "admin_feedback_on_review": null,
        };

        // 5. 调用API创建 UserTrip
        // ApiService 的 createUserTrip 方法现在返回 Future<ApiUserTrip>
        final createdUserTrip = await _apiService.createUserTrip(newUserTripPayload);
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(content: Text('行程 "${createdUserTrip.userTripNameOverride}" 创建成功！正在跳转...'), backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(seconds: 1)); // 短暂显示成功消息

        // 6. 导航到 TripDetailPage
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailPage(
              userTripId: createdUserTrip.id, // 传递新创建的 UserTrip ID
            ),
          ),
        );

      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('创建行程失败: ${e.toString()}', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isSubmitting = false; });
        }
      }
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
                  if (value == null || value.isEmpty) return '请输入行程名称';
                  if (value.length > 50) return '名称过长 (最多50字)';
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
                      onPressed: _isSubmitting ? null : _submitForm, // 调用 _submitForm
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                          : const Text('下一步 (编辑日程)'),
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
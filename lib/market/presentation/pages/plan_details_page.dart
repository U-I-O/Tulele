// lib/market/presentation/pages/plan_details_page.dart
import 'package:flutter/material.dart';
// import 'dart:ui'; // For ImageFilter if needed
import '../../../core/utils/auth_utils.dart';


import '../../../core/services/api_service.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/models/api_trip_plan_model.dart'; // For planDetails type
// import '../pages/solution_market_page.dart'; // No longer directly needs TravelPlanMarketItem for data

// 用于导航到行程编辑/详情页面
import '../../../trips/presentation/pages/trip_detail_page.dart';


class PlanDetailsPage extends StatefulWidget {
  final String userTripId; // 接收 UserTrip ID
  // final ApiUserTrip? initialUserTrip; // 可选：如果列表页已经加载了完整数据，可以传递过来避免重复加载

  const PlanDetailsPage({
    super.key, 
    required this.userTripId,
    // this.initialUserTrip 
  });

  @override
  State<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends State<PlanDetailsPage> {
  final ApiService _apiService = ApiService();
  Future<ApiUserTrip>? _userTripFuture;
  ApiUserTrip? _userTripData; // 保存加载的数据

  @override
  void initState() {
    super.initState();
    // if (widget.initialUserTrip != null) {
    //   _userTripData = widget.initialUserTrip;
    //   _userTripFuture = Future.value(widget.initialUserTrip); // 用已有的数据初始化Future
    // } else {
      _loadPlanDetails();
    // }
  }

  Future<void> _loadPlanDetails() async {
    if (!mounted) return;
    setState(() {
      _userTripFuture = _apiService.getUserTripById(widget.userTripId, populatePlan: true);
    });
  }

  // 辅助函数，用于从 ApiUserTrip 获取要在UI上显示的信息
  String _getDisplayTitle(ApiUserTrip? userTrip) {
    if (userTrip == null) return '加载中...';
    return userTrip.displayName;
  }

  IconData _getDisplayIcon(ApiUserTrip? userTrip) {
    if (userTrip == null || (userTrip.tags.isEmpty && (userTrip.planDetails?.tags ?? []).isEmpty)) {
      return Icons.explore_outlined;
    }
    final tagsToShow = userTrip.tags.isNotEmpty ? userTrip.tags : (userTrip.planDetails?.tags ?? []);
    if (tagsToShow.isEmpty) return Icons.explore_outlined;
    // 与 TravelPlanMarketItem._getIconForFirstTag 逻辑保持一致
    String firstTag = tagsToShow.first.toLowerCase();
     switch (firstTag) {
      case '亲子': return Icons.child_friendly_outlined;
      case '海岛': return Icons.beach_access_outlined;
      // ... 其他 case
      default: return Icons.explore_outlined;
    }
  }
  
  String? _getDisplayCoverImage(ApiUserTrip? userTrip) {
    if (userTrip == null) return null;
    return userTrip.coverImage ?? userTrip.planDetails?.coverImage;
  }

  double _getDisplayRating(ApiUserTrip? userTrip) {
    if (userTrip == null) return 0.0;
    return userTrip.planDetails?.averageRating ?? 0.0;
  }

  int _getDisplayReviewCount(ApiUserTrip? userTrip) {
     if (userTrip == null) return 0;
    return userTrip.planDetails?.reviewCount ?? 0;
  }

  String _getDisplayPrice(ApiUserTrip? userTrip, BuildContext context) {
    if (userTrip == null) return '加载中...';
    final price = userTrip.planDetails?.platformPrice;
    return price != null ? '¥${price.toStringAsFixed(2)}' : '价格待定';
  }
  
  String _getDisplayCreator(ApiUserTrip? userTrip) {
    if (userTrip == null) return '';
    return userTrip.creatorName ?? userTrip.planDetails?.creatorName ?? '匿名创作者';
  }

  List<String> _getDisplayTags(ApiUserTrip? userTrip) {
    if (userTrip == null) return [];
    return userTrip.tags.isNotEmpty ? userTrip.tags : (userTrip.planDetails?.tags ?? []);
  }

  List<ApiDayFromUserTrip> _getDisplayDays(ApiUserTrip? userTrip) {
     if (userTrip == null) return [];
     // 优先用 UserTrip 自身的 days，如果为空且 planDetails 存在，则转换 planDetails.days
     if (userTrip.days.isNotEmpty) {
        return userTrip.days;
     } else if (userTrip.planDetails != null && userTrip.planDetails!.days.isNotEmpty) {
        return userTrip.planDetails!.days.map((pd) => ApiDayFromUserTrip.fromPlanDay(pd)).toList();
     }
     return [];
  }

  // TODO: 用户反馈 (评论) 需要新的API来获取特定方案的评论列表
  // final List<Map<String, String>> sampleReviews = [ ... ]; // 暂时保留示例

  Future<void> _adoptThisPlan(ApiUserTrip marketUserTrip) async {
    // 当用户点击“使用此方案”时的逻辑
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context); // 在 async gap 前获取

    try {
      final currentUserId = await AuthUtils.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception("请先登录才能采纳方案。");
      }
      // 假设 AuthUtils 可以提供用户名和头像，如果不能，则依赖后端填充
      // final currentUsername = await AuthUtils.getCurrentUsername() ?? "当前用户";
      // final currentUserAvatar = await AuthUtils.getCurrentUserAvatar();

      // 1. 决定是引用 TripPlan 还是复制内容
      // 如果 marketUserTrip 有 planId，说明它基于一个模板，新 UserTrip 也应关联此 planId
      // 如果 marketUserTrip 没有 planId (不太可能出现在市场)，则需要复制其核心内容到新 TripPlan
      String? basePlanIdToUse = marketUserTrip.planId;
      ApiTripPlan planContentToAdopt;

      if (basePlanIdToUse != null && marketUserTrip.planDetails != null) {
          // 方案基于现有模板，直接使用此模板ID
          planContentToAdopt = marketUserTrip.planDetails!;
      } else {
          // 如果市场上的 UserTrip 没有 planId，或者 planDetails 未加载 (理论上不应发生)
          // 那么我们需要基于这个 UserTrip 的核心内容创建一个新的 TripPlan
          // 这意味着 UserTrip 自身必须包含完整的 name, origin, destination, days 等信息
          ApiTripPlan newPlanFromUserTripData = ApiTripPlan(
              name: marketUserTrip.displayName,
              creatorId: currentUserId, // 新模板的创建者是当前用户
              origin: marketUserTrip.origin,
              destination: marketUserTrip.destination,
              startDate: marketUserTrip.startDate,
              endDate: marketUserTrip.endDate,
              tags: marketUserTrip.tags,
              description: marketUserTrip.description,
              coverImage: marketUserTrip.coverImage,
              days: marketUserTrip.days.map((utDay) => ApiPlanDay( // 转换结构
                  dayNumber: utDay.dayNumber,
                  date: utDay.date,
                  title: utDay.title,
                  description: utDay.description,
                  activities: utDay.activities.map((utAct) => ApiPlanActivity(
                      // id: null, // 新的 planActivity，ID由后端生成
                      title: utAct.title,
                      location: utAct.location,
                      startTime: utAct.startTime,
                      endTime: utAct.endTime,
                      note: utAct.note,
                      transportation: utAct.transportation,
                      // ... 其他从 utAct 映射的字段
                  )).toList(),
                  notes: utDay.notes,
              )).toList(),
              // 其他市场字段在新模板创建时通常为默认值
              platformPrice: null, averageRating: null, reviewCount: 0
          );
          final createdPlan = await _apiService.createNewTripPlan(newPlanFromUserTripData);
          if(createdPlan.id == null) throw Exception("为采纳的方案创建新基础计划失败。");
          basePlanIdToUse = createdPlan.id!;
          planContentToAdopt = createdPlan;
      }

      // 2. 创建新的 UserTrip 实例
      final newUserTripPayload = {
        "plan_id": basePlanIdToUse,
        "creator_id": currentUserId,
        // "creator_name": currentUsername, // 后端填充
        // "creator_avatar": currentUserAvatar, // 后端填充
        "user_trip_name_override": "我的 ${planContentToAdopt.name}", // 给新行程一个默认名称
        
        "origin": planContentToAdopt.origin,
        "destination": planContentToAdopt.destination,
        "startDate": planContentToAdopt.startDate?.toIso8601String().substring(0,10),
        "endDate": planContentToAdopt.endDate?.toIso8601String().substring(0,10),
        "tags": planContentToAdopt.tags,
        "description": planContentToAdopt.description,
        "coverImage": planContentToAdopt.coverImage,
        "days": planContentToAdopt.days.map((d) => d.toJson()).toList(), // 确保是 ApiPlanDay 的 toJson
        
        "members": [{"userId": currentUserId, "role": "owner"}],
        "publish_status": "draft",
        "travel_status": "planning",
      };

      final createdUserTrip = await _apiService.createUserTrip(newUserTripPayload);

      messenger.showSnackBar(
        SnackBar(content: Text('方案已成功添加到您的行程！'), backgroundColor: Colors.green),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 跳转到用户自己的行程详情页，让其编辑
      navigator.pushReplacement(MaterialPageRoute(
        builder: (context) => TripDetailPage(userTripId: createdUserTrip.id),
      ));

    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('采纳方案失败: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiUserTrip>(
      future: _userTripFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || (snapshot.connectionState == ConnectionState.done && !snapshot.hasData && !snapshot.hasError) ) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('错误')), body: Center(child: Text('加载方案详情失败: ${snapshot.error}')));
        }
        if (!snapshot.hasData) {
           return Scaffold(appBar: AppBar(title: const Text('错误')), body: const Center(child: Text('未找到方案详情')));
        }

        final userTrip = snapshot.data!; // 这是从市场点击过来的 UserTrip 完整数据
        _userTripData = userTrip; // 保存一份到状态变量，方便其他地方使用

        // --- 从 userTrip (ApiUserTrip) 中提取要在UI上显示的信息 ---
        final String title = _getDisplayTitle(userTrip);
        final IconData icon = _getDisplayIcon(userTrip); // 用于头部占位
        final String? coverImageUrl = _getDisplayCoverImage(userTrip);
        final double rating = _getDisplayRating(userTrip);
        final int reviewCount = _getDisplayReviewCount(userTrip);
        final String price = _getDisplayPrice(userTrip, context);
        final String creator = _getDisplayCreator(userTrip);
        final List<String> tags = _getDisplayTags(userTrip);
        final List<ApiDayFromUserTrip> itineraryDays = _getDisplayDays(userTrip);


        return Scaffold(
          appBar: AppBar(
            title: Text(title, overflow: TextOverflow.ellipsis),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部信息区域
                Container(
                  height: 220, // 增加高度
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    image: coverImageUrl != null && coverImageUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(coverImageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: coverImageUrl == null || coverImageUrl.isEmpty 
                      ? Icon(icon, size: 80, color: Theme.of(context).primaryColor.withOpacity(0.7)) 
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('$rating (${reviewCount}条评价)', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          const Spacer(),
                          Text(price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('由 $creator 创建', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      if (tags.isNotEmpty) Wrap(spacing: 8.0, children: tags.map((tag) => Chip(label: Text(tag))).toList()),
                      const Divider(height: 32, thickness: 1),

                      Text('行程概览', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (itineraryDays.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text("暂无详细日程安排", style: TextStyle(color: Colors.grey)))),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: itineraryDays.length,
                        itemBuilder: (context, index) {
                          final dayData = itineraryDays[index]; // ApiDayFromUserTrip
                          return Card(
                            elevation: 1, margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                                child: Text('${dayData.dayNumber ?? index + 1}'),
                              ),
                              title: Text(dayData.title ?? '第 ${dayData.dayNumber ?? index + 1} 天', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                              subtitle: dayData.description != null && dayData.description!.isNotEmpty ? Text(dayData.description!, style: TextStyle(fontSize: 13, color: Colors.grey[600])) : null,
                              children: dayData.activities.map((activity) => ListTile( // activity is ApiActivityFromUserTrip
                                contentPadding: const EdgeInsets.only(left: 32, right: 16, top: 0, bottom: 4),
                                dense: true,
                                leading: Icon(Icons.circle, size: 8, color: Theme.of(context).hintColor),
                                title: Text(activity.title, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                                subtitle: activity.location != null && activity.location!.isNotEmpty 
                                    ? Text("${activity.startTime ?? ''} @ ${activity.location}", style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                                    : (activity.startTime != null ? Text(activity.startTime!, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null),
                              )).toList(),
                            ),
                          );
                        },
                      ),
                      // const Divider(height: 32, thickness: 1),
                      // Text('用户反馈 (${sampleReviews.length}条)', style: Theme.of(context).textTheme.titleLarge),
                      // const SizedBox(height: 12),
                      // ListView.builder( /* ... 评论列表，待实现API ... */ ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _adoptThisPlan(userTrip), // 传递加载到的 userTrip
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                    child: Text('采纳此方案 (价格: $price)'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
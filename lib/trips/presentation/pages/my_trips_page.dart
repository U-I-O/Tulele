// lib/trips/presentation/pages/my_trips_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For HSLColor
import 'package:visibility_detector/visibility_detector.dart';

// 核心服务和模型 - 根据您的项目结构调整路径
import '../../../core/services/api_service.dart';
import '../../../core/models/api_user_trip_model.dart';

// 其他页面跳转
import 'package:tulele/market/presentation/pages/solution_market_page.dart';
import '../../../market/presentation/pages/plan_details_page.dart';
import 'trip_detail_page.dart';
import 'qr_scanner_page.dart';

class TravelPlanMarketItem {
  final String id;
  final String title;
  final IconData icon; // 或者 String iconUrl;
  final double rating;
  final int reviewCount;
  final String price;
  final List<String> tags;
  final String creator;
  final String? imageUrl;
  final ApiUserTrip userTripSource;

  TravelPlanMarketItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.tags,
    required this.creator,
    this.imageUrl,
    required this.userTripSource,
  });

  static IconData getIconForFirstTag(List<String> tags) { // <--- 改为静态方法或在State中定义
      if (tags.isEmpty) return Icons.explore_outlined;
      String firstTag = tags.first.toLowerCase();
      switch (firstTag) {
        case '亲子': return Icons.child_friendly_outlined;
        case '海岛': return Icons.beach_access_outlined;
        case '文化': return Icons.account_balance_outlined;
        case '历史': return Icons.history_edu_outlined;
        case '美食': return Icons.restaurant_menu_outlined;
        case '自然': return Icons.landscape_outlined;
        case '徒步': return Icons.directions_walk_outlined;
        default: return Icons.explore_outlined;
      }
    }
  }

class MyTripsPage extends StatefulWidget {

  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  final ApiService _apiService = ApiService(); // 新增ApiService实例
  late Future<List<ApiUserTrip>>? _myUserTripsFuture;
  late Future<List<ApiUserTrip>>? _featuredMarketUserTripsFuture;

  Key _myTripsPageVisibilityKey = UniqueKey(); // 给 VisibilityDetector 一个唯一的key

  @override
  void initState() {
    super.initState();
    _loadData(); // 调用新的统一加载方法
  }

  Future<void> _loadData() async {
    if (mounted) { // 总是检查 mounted
      _loadMyUserTrips();
      _loadFeaturedMarketUserTrips();
    }
  }

  Future<void> _loadMyUserTrips() async {
    if (!mounted) return;
    setState(() {
      _myUserTripsFuture = _apiService.getUserTripsForCurrentUser();
    });
    // 可以添加 .catchError 处理，虽然 FutureBuilder 也会捕获
    _myUserTripsFuture?.catchError((error) {
      if (mounted) {
        // 可选：在这里处理特定错误或记录日志，FutureBuilder 也会显示错误
        print("Error loading my user trips in _loadMyUserTrips: $error");
      }
    });
  }

  Future<void> _loadFeaturedMarketUserTrips() async {
    if (!mounted) return;
    setState(() {
      _featuredMarketUserTripsFuture = _apiService.getPublishedUserTrips(
        sortBy: 'rating', // 或者其他有意义的排序字段，如 'updated_at'
        limit: 5,
      );
    });
    _featuredMarketUserTripsFuture?.catchError((error) {
      if (mounted) {
        print("Error loading featured market user trips in _loadFeaturedMarketUserTrips: $error");
      }
    });
  }

  Color getDarkerColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    final darkerHslColor = hslColor.withLightness(
        (hslColor.lightness - 0.3).clamp(0.0, 1.0));
    return darkerHslColor.toColor();
  }

  String _calculateTripDuration(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) return '待定';
  try {
    int durationDays = endDate.difference(startDate).inDays + 1;
    if (durationDays <= 0) return '待定';
    int durationNights = durationDays - 1;
    if (durationNights < 0) durationNights = 0; // 确保不会是负数
    if (durationNights == 0) return '$durationDays天'; // 例如当天往返
    return '$durationDays天$durationNights晚';
  } catch (e) {
    print('Error calculating trip duration: $e');
    return '待定';
  }
}

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50, // 类似图2的浅蓝色背景
        // 如果需要，可以替换为更复杂的渐变或图片背景
        // 注意：您之前在这里也设置了 image: DecorationImage(image: AssetImage('assets/icon/icon.png'), fit: BoxFit.cover),
        // 如果您希望整个头部背景是这个图片，可以保留。
        // 如果您希望背景是浅蓝色，而图片仅用于飞机图标，则应移除这里的 DecorationImage。
        // 从您的截图 d8dd51ac4326dba5b35d68780239ce0f.jpg 来看，背景是纯浅蓝色，没有整体覆盖的背景图。
        // 因此，我将注释掉下面的 image 属性，以匹配截图效果。
        // image: DecorationImage(image: AssetImage('assets/icon/icon.png'), fit: BoxFit.cover),
      ),
      child: Column( // 保留 Column 以便未来可能添加其他内容，或者可以直接用 Row 如果确定只有这一行
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have A',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700),
                  ),
                  Text(
                    'Nice Trip',
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700, // 与您的截图颜色一致
                        height: 1.1),
                  ),
                ],
              ),
              // 这里用的是您的图片路径 'assets/icon/icon.png'
              // 您的截图 d8dd51ac4326dba5b35d68780239ce0f.jpg 显示的是一个飞机图标
              // 如果 'assets/icon/icon.png' 是飞机图标，那很好。
              // 如果不是，您可能需要用 Icon(Icons.flight, size: 60, color: Colors.blue.shade600) 或者您自己的飞机图片。
              Image.asset(
                'assets/icon/icon.png',
                height: 70, // 根据您的截图调整大小，可能需要调整为 50-60
                // color: Colors.blue.shade700, // 根据您的截图，飞机图标是深蓝色
                errorBuilder: (context, error, stackTrace) {
                  // 如果图片加载失败，显示备用飞机图标
                  return Icon(Icons.flight, size: 60, color: Colors.blue.shade600);
                },
              ),
            ],
          ),
          // const SizedBox(height: 20.0), // 移除 Pro 横幅上方的间距
          // 移除了 "Gooh Pro" 横幅相关的 Container
        ],
      ),
    );
  }

  String _getDisplayStatus(String publishStatus, String travelStatus) {
    if (publishStatus == 'published') return '已发布';
    if (publishStatus == 'pending_review') return '审核中';
    if (publishStatus == 'rejected') return '已驳回';
    if (travelStatus == 'draft') return '未发布';
    // 对于草稿或未明确发布状态的，显示其旅行状态
    return _getTravelStatusText(travelStatus);
  }

  String _getTravelStatusText(String travelStatus) {
    switch (travelStatus) {
      case 'planning': return '计划中';
      case 'traveling': return '旅行中';
      case 'completed': return '已完成';
      default: return '未知'; // 或者 travelStatus 本身
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return VisibilityDetector( // <--- 包裹 Scaffold 或其 body
    key: _myTripsPageVisibilityKey,
    onVisibilityChanged: (visibilityInfo) {
      var visiblePercentage = visibilityInfo.visibleFraction * 100;
      if (mounted && visiblePercentage > 50) { // 当页面超过50%可见时
        // 这里可以添加一个节流逻辑，避免过于频繁的刷新
        // 例如，记录上次刷新的时间，如果距离现在很近则不刷新
        print("MyTripsPage became visible, potentially refreshing data.");
        _loadData(); // 或者只刷新必要的数据
      }
    },
      child:Scaffold(
        appBar: AppBar(
          title: const SizedBox.shrink(),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          actions: [
            // 添加扫码按钮到右上角
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: '扫描邀请二维码',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QrScannerPage()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildCustomHeader(context),
              ),
              // --- “热门方案”区域 ---
              if (_featuredMarketUserTripsFuture != null) // 确保 Future 已初始化
                SliverToBoxAdapter(
                  child: _buildFeaturedPlansSection(context),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                  child: Text(
                    '我的行程',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
              // --- “我的行程”列表 ---
              if (_myUserTripsFuture != null) // 确保 Future 已初始化
                FutureBuilder<List<ApiUserTrip>>(
                  future: _myUserTripsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              // 更具体的错误提示会更好，例如 snapshot.error.toString()
                              '加载我的行程失败: ${snapshot.error}\n请检查网络连接并下拉刷新。',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          )
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverFillRemaining(
                        // ... 你的空状态UI ...
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.luggage_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('暂无行程', style: TextStyle(fontSize: 17, color: Colors.grey[500])),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                                child: Text(
                                  '点击下方的 "+" 按钮，开始创建您的第一次精彩旅程！',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final myTrips = snapshot.data!;
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final userTrip = myTrips[index];
                              final String? tripName = userTrip.userTripNameOverride;
                              final DateTime? startDate = userTrip.startDate ?? userTrip.planDetails?.startDate;
                              final DateTime? endDate = userTrip.endDate ?? userTrip.planDetails?.endDate;
                              final String duration = _calculateTripDuration(startDate, endDate);
                              final String tripDateRange = startDate != null
                                  ? "${startDate.year}/${startDate.month.toString().padLeft(2, '0')}/${startDate.day.toString().padLeft(2, '0')} - ${endDate != null ? "${endDate.year}/${endDate.month.toString().padLeft(2, '0')}/${endDate.day.toString().padLeft(2, '0')}" : "待定"}"
                                  : "日期未定";
                              final String tripLocation = userTrip.destination ?? userTrip.planDetails?.destination ?? "地点未知";
                              
                              final Color tripCardBaseColor = Colors.primaries[index % Colors.primaries.length].shade100;
                              final bool isStubDark = tripCardBaseColor.computeLuminance() < 0.4;
                              final Color stubTextColor = isStubDark ? Colors.white.withOpacity(0.9) : Colors.black87;
                              final Color stubIconColor = isStubDark ? Colors.white70 : Colors.black54;
                              final bool isBaseColorLight = tripCardBaseColor.computeLuminance() > 0.5;
                              final Color statusTextLeftColor = isBaseColorLight
                                  ? getDarkerColor(tripCardBaseColor)
                                  : tripCardBaseColor.withOpacity(0.9);

                              // --- “我的行程”卡片UI ---
                              // 保持你提供的卡片UI实现，因为这部分与后端服务的直接关联性较低，主要是数据展示
                              // ... 你的 Card Widget 代码 ...
                              return Card(
                                elevation: 2.0,
                                margin: const EdgeInsets.only(bottom: 16.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TripDetailPage(userTripId: userTrip.id),
                                      ),
                                    ).then((result){
                                      if (result == true && mounted) { 
                                          _loadMyUserTrips(); // 仅刷新“我的行程”列表
                                          // 如果热门方案也可能受影响（例如用户发布了自己的行程），则调用 _loadData()
                                          // _loadData();
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: Container(
                                            color: Colors.white,
                                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column( // 主要信息区
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(tripName ?? '未命名行程', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: onSurfaceColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                    const SizedBox(height: 7.0),
                                                    Row(children: [Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[600]), const SizedBox(width: 6.0), Expanded(child: Text("日期: $tripDateRange", style: TextStyle(fontSize: 12.0, color: Colors.grey[600]), overflow: TextOverflow.ellipsis))]),
                                                    const SizedBox(height: 5.0),
                                                    Row(children: [Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[600]), const SizedBox(width: 6.0), Expanded(child: Text(tripLocation, style: TextStyle(fontSize: 12.0, color: Colors.grey[600]), overflow: TextOverflow.ellipsis))]),
                                                    const SizedBox(height: 5.0),
                                                    Row(children: [Icon(Icons.people_alt_outlined, size: 13, color: Colors.grey[600]), const SizedBox(width: 6.0), Text('${userTrip.members.length}人行', style: TextStyle(fontSize: 12.0, color: Colors.grey[600]))]),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row( // 状态和更多操作
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: tripCardBaseColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(_getDisplayStatus(userTrip.publishStatus, userTrip.travelStatus), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusTextLeftColor))),
                                                    SizedBox(height: 30, width: 30, child: IconButton(padding: EdgeInsets.zero, icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20), tooltip: '更多操作', onPressed: () { /* TODO */ })),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12, child: CustomPaint(painter: DotLinePainter(dotColor: Colors.grey.shade300, dotRadius: 1.5, spacing: 4.0))),
                                        Expanded( // 右侧时长和状态区
                                          flex: 3,
                                          child: Container(
                                            color: tripCardBaseColor,
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Icon(Icons.luggage_outlined, color: stubIconColor, size: 26),
                                                const SizedBox(height: 8),
                                                Text('时长', style: TextStyle(fontSize: 10, color: stubTextColor.withOpacity(0.7))),
                                                Text(duration, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stubTextColor), textAlign: TextAlign.center),
                                                const SizedBox(height: 8),
                                                Text('状态', style: TextStyle(fontSize: 10, color: stubTextColor.withOpacity(0.7))),
                                                Text(_getTravelStatusText(userTrip.travelStatus), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stubTextColor)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: myTrips.length,
                          ),
                        ),
                      );
                    }
                  },
                )
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()), // 如果 Future 为 null，不显示任何东西
            ],
          ),
        ),
      ),
    );
  }

  // 将 _buildFeaturedPlansSection 移到 build 方法外部，作为 _MyTripsPageState 的一个方法
  Widget _buildFeaturedPlansSection(BuildContext context) {
    // 确保 _featuredMarketUserTripsFuture 不为 null 才构建
    if (_featuredMarketUserTripsFuture == null) {
      return const SizedBox.shrink(); // 或者一个占位加载指示器
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '热门方案',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SolutionMarketPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      alignment: Alignment.centerRight),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '进入方案市场查看更多',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: Colors.grey[600]),
                    ],
                  )),
            ],
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            height: 185,
            child: FutureBuilder<List<ApiUserTrip>>(
              future: _featuredMarketUserTripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                } else if (snapshot.hasError) {
                  return Center(child: Text('加载热门方案失败: ${snapshot.error}', style: TextStyle(color: Colors.grey[500])));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('暂无精选方案', style: TextStyle(color: Colors.grey[400])));
                } else {
                  final featuredUserTrips = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredUserTrips.length,
                    itemBuilder: (context, index) {
                      final userTrip = featuredUserTrips[index];
                      final marketItem = _convertUserTripToMarketItem(userTrip);
                      return _buildMiniPlanCard(context, marketItem);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // _convertUserTripToMarketItem 方法保持与 solution_market_page.dart 中一致的逻辑
TravelPlanMarketItem _convertUserTripToMarketItem(ApiUserTrip userTrip) {
  final String itemTitle = userTrip.displayName;
  final String? itemImageUrl = userTrip.coverImage ?? userTrip.planDetails?.coverImage;
  final double itemRating = userTrip.planDetails?.averageRating ?? 0.0;
  final int itemReviewCount = userTrip.planDetails?.reviewCount ?? 0;
  final double? itemPrice = userTrip.planDetails?.platformPrice;
  final String itemCreator = userTrip.creatorName ?? userTrip.planDetails?.creatorName ?? '匿名创作者';
  final List<String> itemTags = userTrip.tags.isNotEmpty ? userTrip.tags : (userTrip.planDetails?.tags ?? []);

  return TravelPlanMarketItem(
    id: userTrip.id, // UserTrip ID
    title: itemTitle,
    imageUrl: itemImageUrl,
    icon: TravelPlanMarketItem.getIconForFirstTag(itemTags), // 假设_getIconForFirstTag是TravelPlanMarketItem的静态或实例方法
    rating: itemRating,
    reviewCount: itemReviewCount,
    price: itemPrice != null ? '¥${itemPrice.toStringAsFixed(2)}' : '价格待定',
    tags: itemTags,
    creator: itemCreator,
    userTripSource: userTrip, // 传递原始 ApiUserTrip
  );
}

  Widget _buildMiniPlanCard(BuildContext context, TravelPlanMarketItem plan) {
    return SizedBox(
      width: 140,
      child: Card(
        elevation: 0.5,
        margin: const EdgeInsets.only(right: 12.0, bottom: 4.0), // 增加一点底部外边距给阴影空间
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanDetailsPage(userTripId: plan.userTripSource.id,), // <--- 确保传递 UserTrip ID
            ),
          ).then((result) { // 从详情页返回后刷新
              if (result == true && mounted) {
                  _loadData(); // 刷新两个列表，因为热门方案也可能在“我的行程”中
              }
          });
        },
          borderRadius: BorderRadius.circular(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: plan.imageUrl == null
                      ? Theme.of(context).primaryColor.withOpacity(0.05)
                      : null,
                  image: plan.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(plan.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: plan.imageUrl == null
                    ? Center(
                        child: Icon(plan.icon,
                            size: 28,
                            color: Theme.of(context).primaryColor.withOpacity(0.6)))
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.price,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DotLinePainter extends CustomPainter {
  final Color dotColor;
  final double dotRadius;
  final double spacing;

  DotLinePainter({
    required this.dotColor,
    this.dotRadius = 1.5,
    this.spacing = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    double currentY = spacing + dotRadius;
    while (currentY < size.height - dotRadius) {
      canvas.drawCircle(Offset(size.width / 2, currentY), dotRadius, paint);
      currentY += dotRadius * 2 + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant DotLinePainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
           oldDelegate.dotRadius != dotRadius ||
           oldDelegate.spacing != spacing;
  }
}

// 确保 TripMode 和 TravelPlanMarketItem 类已在项目中正确定义和导入
// enum TripMode { view, edit }
// class TravelPlanMarketItem { ... } // 确保从其原始文件导入
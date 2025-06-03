// lib/trips/presentation/pages/my_trips_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For HSLColor

import 'package:tulele/market/presentation/pages/solution_market_page.dart';
import 'package:tulele/market/presentation/pages/plan_details_page.dart';
import 'trip_detail_page.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  final List<Map<String, dynamic>> _trips = [
    {
      'title': '三亚海岛度假',
      'date': '2025/06/01 - 2025/06/05',
      'color': Colors.blue.shade300,
      'id': '1',
      'location': '海南三亚',
      'participants': 3,
      'status': '已计划',
      'coverImageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmVhY2h8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'title': '北京文化之旅',
      'date': '2025/07/15 - 2025/07/20',
      'color': Colors.green.shade300,
      'id': '2',
      'location': '中国北京',
      'participants': 2,
      'status': '已计划',
      'coverImageUrl': null,
    },
    {
      'title': '日本动漫探索',
      'date': '2025/08/10 - 2025/08/18',
      'color': Colors.orange.shade300,
      'id': '3',
      'location': '东京 & 大阪',
      'participants': 1,
      'status': '进行中',
      'coverImageUrl':
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dG9reW98ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    }
  ];

  final List<TravelPlanMarketItem> _featuredMarketPlans = [
    TravelPlanMarketItem(
        id: 'fp1',
        title: '三亚海岛度假 | 亲子游玩5日行程',
        icon: Icons.beach_access_outlined,
        rating: 5.0,
        reviewCount: 12,
        price: '¥39.9',
        tags: ['亲子', '海岛'],
        creator: '旅行达人张三',
        imageUrl:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmVhY2h8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60'),
    TravelPlanMarketItem(
        id: 'fp2',
        title: '北京文化之旅 | 故宫深度游',
        icon: Icons.account_balance_outlined,
        rating: 4.8,
        reviewCount: 25,
        price: '¥29.9',
        tags: ['文化', '历史'],
        creator: '小红薯探险家',
        imageUrl:
            'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YmVpamluZ3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60'),
    TravelPlanMarketItem(
        id: 'p1',
        title: '云南秘境探索7日游',
        icon: Icons.landscape_outlined,
        rating: 4.9,
        reviewCount: 180,
        price: '¥45.0',
        tags: ['自然', '徒步'],
        creator: '地理学家'),
  ];

  Color getDarkerColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    final darkerHslColor = hslColor.withLightness(
        (hslColor.lightness - 0.3).clamp(0.0, 1.0));
    return darkerHslColor.toColor();
  }

  String _calculateTripDuration(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '待定';
    try {
      final dates = dateString.split(' - ');
      if (dates.length == 2) {
        final startDateStr = dates[0].replaceAll('/', '-');
        final endDateStr = dates[1].replaceAll('/', '-');
        final start = DateTime.parse(startDateStr);
        final end = DateTime.parse(endDateStr);
        int durationDays = end.difference(start).inDays + 1;
        if (durationDays <= 0) return '待定';
        int durationNights = durationDays - 1;
        if (durationNights <= 0) return '$durationDays天';
        return '$durationDays天$durationNights晚';
      }
      return '待定';
    } catch (e) {
      print('Error parsing date for duration: $e');
      return '待定';
    }
  }

  // 新增：自定义头部 Widget
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
                color: Colors.blue.shade700, // 根据您的截图，飞机图标是深蓝色
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


  @override
  Widget build(BuildContext context) {
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(), // 移除标题文字
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 使 AppBar 背景与页面背景一致
        elevation: 0, // 移除阴影
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // 新增：自定义可滚动头部
          SliverToBoxAdapter(
            child: _buildCustomHeader(context),
          ),
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
          if (_trips.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.luggage_outlined,
                        size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('暂无行程',
                        style: TextStyle(fontSize: 17, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: Text(
                        '点击下方的 "+" 按钮，开始创建您的第一次精彩旅程！',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[400], height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = _trips[index];
                    final Color tripCardBaseColor = trip['color'] as Color;
                    final String duration =
                        _calculateTripDuration(trip['date'] as String?);
                    
                    final bool isStubDark = tripCardBaseColor.computeLuminance() < 0.4;
                    final Color stubTextColor = isStubDark ? Colors.white.withOpacity(0.9) : Colors.black87;
                    final Color stubIconColor = isStubDark ? Colors.white70 : Colors.black54;

                    final bool isBaseColorLight = tripCardBaseColor.computeLuminance() > 0.5;
                    final Color statusTextLeftColor = isBaseColorLight
                        ? getDarkerColor(tripCardBaseColor)
                        : tripCardBaseColor.withOpacity(0.9);

                    return Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripDetailPage(
                                tripId: trip['id'] as String,
                                initialMode: TripMode.view,
                              ),
                            ),
                          );
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            trip['title']!,
                                            style: TextStyle(
                                                fontSize: 17.0,
                                                fontWeight: FontWeight.bold,
                                                color: onSurfaceColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 7.0),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[600]),
                                              const SizedBox(width: 6.0),
                                              Expanded(
                                                child: Text(
                                                  "出发: ${trip['date']!}",
                                                  style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5.0),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[600]),
                                              const SizedBox(width: 6.0),
                                              Expanded(
                                                child: Text(
                                                  trip['location'] ?? '地点未定',
                                                  style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5.0),
                                          Row(
                                            children: [
                                              Icon(Icons.people_alt_outlined, size: 13, color: Colors.grey[600]),
                                              const SizedBox(width: 6.0),
                                              Text(
                                                '${trip['participants'] ?? 1}人行',
                                                style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: tripCardBaseColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              trip['status'] ?? '未知状态',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: statusTextLeftColor,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30, width: 30,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20),
                                              tooltip: '更多操作',
                                              onPressed: () {},
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 12,
                                child: CustomPaint(
                                  painter: DotLinePainter(
                                    dotColor: Colors.grey.shade300,
                                    dotRadius: 1.5,
                                    spacing: 4.0,
                                  ), 
                                ),
                              ),
                              Expanded(
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
                                      Text(
                                        '时长',
                                        style: TextStyle(fontSize: 10, color: stubTextColor.withOpacity(0.7)),
                                      ),
                                      Text(
                                        duration,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stubTextColor),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '里程',
                                        style: TextStyle(fontSize: 10, color: stubTextColor.withOpacity(0.7)),
                                      ),
                                      Text(
                                        '-- KM',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stubTextColor),
                                      ),
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
                  childCount: _trips.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPlansSection(BuildContext context) {
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
            height: 185, // 修改：增加了热门方案区域的高度，以确保卡片内容完整显示
            child: _featuredMarketPlans.isEmpty
                ? Center(
                    child: Text('暂无精选方案', style: TextStyle(color: Colors.grey[400])))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _featuredMarketPlans.length > 4
                        ? 4
                        : _featuredMarketPlans.length,
                    itemBuilder: (context, index) {
                      final plan = _featuredMarketPlans[index];
                      return _buildMiniPlanCard(context, plan);
                    },
                  ),
          ),
        ],
      ),
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
                    builder: (context) => PlanDetailsPage(plan: plan)));
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
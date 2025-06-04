// lib/market/presentation/pages/solution_market_page.dart
import 'package:flutter/material.dart';
// import 'dart:ui'; // For ImageFilter - 如果你的UI需要模糊效果

import '../../../core/services/api_service.dart';
import '../../../core/models/api_user_trip_model.dart'; // 我们将直接使用 ApiUserTrip
import '../../../core/models/api_trip_plan_model.dart'; // 用于 planDetails
import 'plan_details_page.dart'; // 保持导航目标

// TravelPlanMarketItem 仍然用作 UI 和 ApiUserTrip 之间的适配层或显示模型
// 但其字段现在将从 ApiUserTrip (及其 planDetails) 派生
class TravelPlanMarketItem {
  final String id; // 这将是 UserTrip 的 ID
  final String title;
  final String? imageUrl;
  final IconData icon;
  final double rating;
  final int reviewCount;
  final String price;
  final List<String> tags;
  final String creator;
  // 可以考虑直接存储 ApiUserTrip 对象，如果 PlanDetailsPage 需要它
  final ApiUserTrip userTripSource;


  TravelPlanMarketItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.icon,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.tags,
    required this.creator,
    required this.userTripSource,
  });

  // 工厂构造函数，用于从 ApiUserTrip 创建 TravelPlanMarketItem
  factory TravelPlanMarketItem.fromApiUserTrip(ApiUserTrip userTrip) {
    final String itemTitle = userTrip.displayName; // 使用 getter
    final String? itemImageUrl = userTrip.coverImage ?? userTrip.planDetails?.coverImage;
    final double itemRating = userTrip.planDetails?.averageRating ?? 0.0;
    final int itemReviewCount = userTrip.planDetails?.reviewCount ?? 0;
    final double? itemPrice = userTrip.planDetails?.platformPrice;
    final String itemCreator = userTrip.creatorName ?? userTrip.planDetails?.creatorName ?? '匿名创作者';
    final List<String> itemTags = userTrip.tags.isNotEmpty ? userTrip.tags : (userTrip.planDetails?.tags ?? []);

    return TravelPlanMarketItem(
      id: userTrip.id,
      title: itemTitle,
      imageUrl: itemImageUrl,
      icon: _getIconForFirstTag(itemTags), // 根据标签获取图标
      rating: itemRating,
      reviewCount: itemReviewCount,
      price: itemPrice != null ? '¥${itemPrice.toStringAsFixed(2)}' : '价格待定',
      tags: itemTags,
      creator: itemCreator,
      userTripSource: userTrip, // 保存原始 UserTrip 对象
    );
  }

  static IconData _getIconForFirstTag(List<String> tags) {
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


class SolutionMarketPage extends StatefulWidget {
  const SolutionMarketPage({super.key});

  @override
  State<SolutionMarketPage> createState() => _SolutionMarketPageState();
}

class _SolutionMarketPageState extends State<SolutionMarketPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  Future<List<ApiUserTrip>>? _allPublishedUserTripsFuture;
  List<TravelPlanMarketItem> _featuredPlans = [];
  List<TravelPlanMarketItem> _allMarketPlans = [];
  List<TravelPlanMarketItem> _searchResults = [];

  String _currentSearchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    if (!mounted) return;
    setState(() {
      _allPublishedUserTripsFuture = _apiService.getPublishedUserTrips(
        // 获取所有已发布的，可以按某种默认方式排序，如更新时间或热度
        // sortBy: 'updated_at', // 或者 'popularity' 等，需后端支持
      );
    });

    _allPublishedUserTripsFuture?.then((userTrips) {
      if (!mounted) return;
      final marketItems = userTrips.map((ut) => TravelPlanMarketItem.fromApiUserTrip(ut)).toList();
      
      setState(() {
        _allMarketPlans = marketItems;
        // 筛选精选方案：例如评论数 > 10 (基于 TripPlan 的 reviewCount)
        _featuredPlans = marketItems.where((item) {
            // reviewCount 来自 userTripSource.planDetails.reviewCount
            return item.reviewCount > 10; // 你可以调整这个阈值
        }).toList();
        // 初始搜索结果为所有方案
        _filterPlans(_currentSearchQuery); // 应用当前搜索（如果之前有）
      });
    }).catchError((error) {
      if (mounted) {
        print("Error loading market data: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载方案市场数据失败: $error'), backgroundColor: Colors.red),
        );
        setState(() { // 确保在出错时列表为空或显示错误信息
          _allMarketPlans = [];
          _featuredPlans = [];
          _searchResults = [];
        });
      }
    });
  }

  void _filterPlans(String query) {
    if (!mounted) return;
    _currentSearchQuery = query.toLowerCase(); // 保存当前搜索词
    
    if (_currentSearchQuery.isEmpty) {
      setState(() { _searchResults = _allMarketPlans; });
      return;
    }
    final results = _allMarketPlans.where((plan) {
      final titleLower = plan.title.toLowerCase();
      final tagsContainQuery = plan.tags.any((tag) => tag.toLowerCase().contains(_currentSearchQuery));
      final creatorLower = plan.creator.toLowerCase();
      // 可以加入更多搜索维度，如目的地 (需要 TravelPlanMarketItem 包含 destination)
      return titleLower.contains(_currentSearchQuery) || 
             tagsContainQuery || 
             creatorLower.contains(_currentSearchQuery);
    }).toList();
    setState(() { _searchResults = results; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('方案市场'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5, // 轻微阴影
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator( // 添加下拉刷新
        onRefresh: _loadMarketData,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true, floating: true, elevation: 1,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField( /* ... 搜索框 UI (保持你之前的实现) ... */ 
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索目的地、主题...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.white, // 搜索框背景白色
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0), // 更圆润
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    enabledBorder: OutlineInputBorder( // 默认状态下的边框
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder( // 聚焦状态下的边框
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                    ),
                  ),
                  onChanged: _filterPlans,
                ),
              ),
            ),
            
            // --- “精选方案”区域 ---
            if (_featuredPlans.isNotEmpty) ...[ // 只有当有精选方案时才显示此区域
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20, 16.0, 16.0),
                  child: Text('✨ 精选方案', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: _featuredPlans.length,
                    itemBuilder: (context, index) {
                      return _buildFeaturedPlanCard(_featuredPlans[index]);
                    },
                  ),
                ),
              ),
            ],

            // --- “更多好方案”/搜索结果区域 ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Text(
                 _currentSearchQuery.isEmpty ? '更多好方案' : '搜索结果',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
                ),
              ),
            ),

            // 使用 FutureBuilder 来处理 _allPublishedUserTripsFuture 的状态
            FutureBuilder<List<ApiUserTrip>>(
              future: _allPublishedUserTripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allMarketPlans.isEmpty) { // 初始加载时显示
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError && _allMarketPlans.isEmpty) { // 初始加载错误时显示
                   return SliverFillRemaining(
                      child: Center(
                          child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text('加载失败: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error))
                          )
                      )
                  );
                }
                // 如果有数据（包括搜索结果为空的情况），则显示 _searchResults
                if (_searchResults.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _currentSearchQuery.isEmpty ? '暂无更多方案' : '未找到与“$_currentSearchQuery”相关的方案',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                } else {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: _buildPlanListItem(_searchResults[index]),
                        );
                      },
                      childCount: _searchResults.length,
                    ),
                  );
                }
              }
            ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeaturedPlanCard(TravelPlanMarketItem plan) {
    return SizedBox(
      width: 200, // 精选卡片宽度调整
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlanDetailsPage(userTripId: plan.userTripSource.id,)));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: plan.imageUrl == null ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                  image: plan.imageUrl != null
                      ? DecorationImage(image: NetworkImage(plan.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: plan.imageUrl == null ? Center(child: Icon(plan.icon, size: 50, color: Theme.of(context).primaryColor)) : null,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${plan.rating.toStringAsFixed(1)} (${plan.reviewCount})', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(plan.price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanListItem(TravelPlanMarketItem plan) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PlanDetailsPage(userTripId: plan.userTripSource.id,)));
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: plan.imageUrl == null ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                    image: plan.imageUrl != null
                        ? DecorationImage(image: NetworkImage(plan.imageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: plan.imageUrl == null ? Icon(plan.icon, size: 36, color: Theme.of(context).primaryColor) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16.5), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_border_purple500_outlined, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${plan.rating.toStringAsFixed(1)} (${plan.reviewCount}条评价)', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        const SizedBox(width: 10),
                        Text(plan.price, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('作者: ${plan.creator}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (plan.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: plan.tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.08),
                          labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.w500),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: 0.0, vertical: -2), // 减小Chip的垂直空间
                          side: BorderSide.none,
                        )).toList(),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
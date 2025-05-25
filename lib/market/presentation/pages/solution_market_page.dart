// lib/solution_market_page.dart (UI美化优化)
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'plan_details_page.dart';

// TravelPlanMarketItem 模型类保持不变 (来自之前的代码)
class TravelPlanMarketItem {
  final String id;
  final String title;
  final String? imageUrl; // 改为可选，并可以是网络图片
  final IconData icon; // 作为图片不存在时的备用
  final double rating;
  final int reviewCount;
  final String price;
  final List<String> tags;
  final String creator;

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
  });
}


class SolutionMarketPage extends StatefulWidget {
  const SolutionMarketPage({super.key});

  @override
  State<SolutionMarketPage> createState() => _SolutionMarketPageState();
}

class _SolutionMarketPageState extends State<SolutionMarketPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<TravelPlanMarketItem> _featuredPlans = [
    TravelPlanMarketItem(id: 'fp1', title: '三亚海岛度假 | 亲子游玩5日行程', icon: Icons.beach_access, rating: 5.0, reviewCount: 12, price: '¥39.9', tags: ['亲子', '海岛'], creator: '旅行达人张三', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmVhY2h8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60'),
    TravelPlanMarketItem(id: 'fp2', title: '北京文化之旅 | 故宫长城深度游', icon: Icons.account_balance, rating: 4.8, reviewCount: 25, price: '¥29.9', tags: ['文化', '历史'], creator: '小红薯探险家', imageUrl: 'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YmVpamluZ3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60'),
  ];

  final List<TravelPlanMarketItem> _allPlans = [
    TravelPlanMarketItem(id: 'p1', title: '云南秘境探索7日游', icon: Icons.landscape_outlined, rating: 4.9, reviewCount: 180, price: '¥45.0', tags: ['自然', '徒步'], creator: '地理学家'),
    TravelPlanMarketItem(id: 'p2', title: '成都美食寻味之旅3日', icon: Icons.restaurant_menu_outlined, rating: 4.7, reviewCount: 250, price: '¥19.9', tags: ['美食', '休闲'], creator: '吃货小分队', imageUrl: 'https://images.unsplash.com/photo-1596561250170-7554517310e0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8Y2hlbmdkdXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60'),
    TravelPlanMarketItem(id: 'p3', title: '日本关西赏枫经典路线', icon: Icons.airplanemode_active_outlined, rating: 4.9, reviewCount: 95, price: '¥59.9', tags: ['出境', '摄影'], creator: '全球旅拍师'),
    TravelPlanMarketItem(id: 'p4', title: '欧洲文艺复兴四大城记', icon: Icons.palette_outlined, rating: 4.6, reviewCount: 72, price: '¥88.0', tags: ['艺术', '历史', '欧洲'], creator: '艺术史教授'),
  ];

  List<TravelPlanMarketItem> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = _allPlans;
  }

  void _filterPlans(String query) {
    if (query.isEmpty) {
      setState(() { _searchResults = _allPlans; });
      return;
    }
    final results = _allPlans.where((plan) {
      final titleLower = plan.title.toLowerCase();
      final queryLower = query.toLowerCase();
      final tagsContainQuery = plan.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      return titleLower.contains(queryLower) || tagsContainQuery;
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
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50], // 非常浅的灰色背景
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar( // 将搜索框放在SliverAppBar中，可以有悬浮效果
            pinned: true,
            floating: true,
            elevation: 1,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            automaticallyImplyLeading: false, // 不显示返回按钮
            toolbarHeight: 70, // 给搜索框足够的高度
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20, 16.0, 16.0),
              child: Text(
                '✨ 精选方案',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250, // 增加精选方案卡片的高度
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              child: Text(
                '更多好方案',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          ),
          _searchResults.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _searchController.text.isEmpty ? '暂无更多方案' : '未找到与“${_searchController.text}”相关的方案',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _buildPlanListItem(_searchResults[index]),
                );
              },
              childCount: _searchResults.length,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16)),
        ],
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlanDetailsPage(plan: plan)));
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => PlanDetailsPage(plan: plan)));
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
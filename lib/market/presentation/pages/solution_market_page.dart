// lib/solution_market_page.dart (新建)
import 'package:flutter/material.dart';
import 'plan_details_page.dart'; // 引入方案详情页

// 模拟方案数据模型
class TravelPlanMarketItem {
  final String id;
  final String title;
  final String imageUrl; // 暂时使用Icon代替
  final IconData icon;
  final double rating;
  final int reviewCount;
  final String price;
  final List<String> tags;
  final String creator;

  TravelPlanMarketItem({
    required this.id,
    required this.title,
    this.imageUrl = '',
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

  // 模拟方案市场数据
  final List<TravelPlanMarketItem> _featuredPlans = [
    TravelPlanMarketItem(id: 'fp1', title: '三亚海岛度假 | 亲子游玩5日行程', icon: Icons.beach_access, rating: 5.0, reviewCount: 12, price: '¥39.9', tags: ['亲子', '海岛'], creator: '旅行达人张三'),
    TravelPlanMarketItem(id: 'fp2', title: '北京文化之旅 | 故宫长城深度游', icon: Icons.account_balance, rating: 4.8, reviewCount: 25, price: '¥29.9', tags: ['文化', '历史'], creator: '小红薯探险家'),
  ];

  final List<TravelPlanMarketItem> _allPlans = [
    TravelPlanMarketItem(id: 'p1', title: '云南秘境探索7日游', icon: Icons.landscape, rating: 4.9, reviewCount: 180, price: '¥45.0', tags: ['自然', '徒步'], creator: '地理学家'),
    TravelPlanMarketItem(id: 'p2', title: '成都美食寻味之旅3日', icon: Icons.restaurant, rating: 4.7, reviewCount: 250, price: '¥19.9', tags: ['美食', '休闲'], creator: '吃货小分队'),
    TravelPlanMarketItem(id: 'p3', title: '日本关西赏枫经典路线', icon: Icons.airplanemode_active, rating: 4.9, reviewCount: 95, price: '¥59.9', tags: ['出境', '摄影'], creator: '全球旅拍师'),
    TravelPlanMarketItem(id: 'p4', title: '欧洲文艺复兴四大城记', icon: Icons.palette, rating: 4.6, reviewCount: 72, price: '¥88.0', tags: ['艺术', '历史', '欧洲'], creator: '艺术史教授'),
  ];

  List<TravelPlanMarketItem> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = _allPlans; // 初始显示所有方案
  }

  void _filterPlans(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allPlans;
      });
      return;
    }
    final results = _allPlans.where((plan) {
      final titleLower = plan.title.toLowerCase();
      final queryLower = query.toLowerCase();
      final tagsContainQuery = plan.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      return titleLower.contains(queryLower) || tagsContainQuery;
    }).toList();
    setState(() {
      _searchResults = results;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('方案市场'),
        centerTitle: true,
      ),
      body: CustomScrollView( // 使用CustomScrollView方便组合不同类型的列表项
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索目的地、主题...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor, // 与卡片背景色一致
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
                onChanged: _filterPlans,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Text(
                '精选方案',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220, // 精选方案卡片的高度
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
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '更多方案',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          ),
          _searchResults.isEmpty
              ? SliverFillRemaining( // 使用SliverFillRemaining使其填充剩余空间
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _searchController.text.isEmpty ? '暂无更多方案' : '未找到与“${_searchController.text}”相关的方案',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16)), // 底部安全区域
        ],
      ),
    );
  }

  Widget _buildFeaturedPlanCard(TravelPlanMarketItem plan) {
    return SizedBox(
      width: 280, // 精选卡片宽度
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlanDetailsPage(plan: plan)));
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container( // 模拟图片区域
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
                  ),
                ),
                child: Center(child: Icon(plan.icon, size: 48, color: Theme.of(context).primaryColor)),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${plan.rating.toStringAsFixed(1)} (${plan.reviewCount}条评价)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(plan.price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
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
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PlanDetailsPage(plan: plan)));
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(plan.icon, size: 36, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_border, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${plan.rating.toStringAsFixed(1)} (${plan.reviewCount}条)', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        const SizedBox(width: 8),
                        Text(plan.price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('创建者: ${plan.creator}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    if (plan.tags.isNotEmpty) const SizedBox(height: 6),
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: plan.tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 10)),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        backgroundColor: Theme.of(context).hintColor.withOpacity(0.1),
                        labelStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 10),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    )
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
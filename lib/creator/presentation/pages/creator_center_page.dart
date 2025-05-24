// lib/creator_center_page.dart (新建)
import 'package:flutter/material.dart';
import 'publish_plan_page.dart';
import '../../../trips/presentation/pages/my_published_plans_page.dart';
import 'creator_earnings_page.dart';

class CreatorCenterPage extends StatefulWidget {
  const CreatorCenterPage({super.key});

  @override
  State<CreatorCenterPage> createState() => _CreatorCenterPageState();
}

class _CreatorCenterPageState extends State<CreatorCenterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 模拟创作者数据
    const int publishedPlansCount = 3;
    const double monthlyEarnings = 258.60;
    const String totalTraffic = "5.2千"; // 假设是字符串
    const String creatorLevel = "金牌创作者";


    return Scaffold(
      appBar: AppBar(
        title: const Text('创作中心'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: '发布方案'),
            Tab(text: '我的方案'),
            Tab(text: '创作收益'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 顶部统计信息卡片
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      '您好，创作之星！',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('已发布', '$publishedPlansCount个', Icons.library_books_outlined),
                        _buildStatItem('本月预估收益', '¥$monthlyEarnings', Icons.monetization_on_outlined),
                        _buildStatItem('累计流量', totalTraffic, Icons.trending_up_outlined),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(creatorLevel, style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.bold)),
                      avatar: Icon(Icons.military_tech_outlined, color: Theme.of(context).hintColor, size: 18),
                      backgroundColor: Theme.of(context).hintColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                PublishPlanPage(), // 发布方案页
                MyPublishedPlansPage(), // 我的方案页
                CreatorEarningsPage(), // 创作收益页
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor.withOpacity(0.8)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
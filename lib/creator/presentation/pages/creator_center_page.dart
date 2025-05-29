// lib/creator_center_page.dart (修复版本)
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

  // 模拟创作者数据
  final int publishedPlansCount = 3;
  final double monthlyEarnings = 258.60;
  final String totalTraffic = "5.2千";
  final String creatorLevel = "金牌创作者";

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
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color scaffoldBackgroundColor = Colors.grey[50]!;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 330.0, // 增加高度以容纳所有内容
              floating: false,
              pinned: true,
              elevation: innerBoxIsScrolled ? 2.0 : 0.0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              title: const Text('创作中心'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 60), // 调整标题位置
                background: Container(
                  color: scaffoldBackgroundColor,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 60, 12, 70), // 减少左右边距
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0), // 减少内边距
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                primaryColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 标题与问候语
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.stars_rounded, 
                                    color: primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '您好，创作之星！',
                                    style: TextStyle(
                                      fontSize: 18, // 稍微减小字体
                                      fontWeight: FontWeight.bold, 
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // 数据统计区 - 使用更紧凑的网格布局
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem('已发布', '$publishedPlansCount个', Icons.library_books_outlined)
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.grey.withOpacity(0.3),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  Expanded(
                                    child: _buildStatItem('本月预计收益', '¥$monthlyEarnings', Icons.monetization_on_outlined)
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.grey.withOpacity(0.3),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  Expanded(
                                    child: _buildStatItem('累计流量', totalTraffic, Icons.trending_up_outlined)
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // 创作者等级徽章
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.military_tech_rounded, 
                                      color: Colors.orange[700], 
                                      size: 16
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      creatorLevel, 
                                      style: TextStyle(
                                        color: Colors.orange[700], 
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: primaryColor,
                    indicatorWeight: 3.0,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: '发布方案'),
                      Tab(text: '我的方案'),
                      Tab(text: '创作收益'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          color: scaffoldBackgroundColor,
          child: TabBarView(
            controller: _tabController,
            children: const [
              PublishPlanPage(), // 发布方案页
              MyPublishedPlansPage(), // 我的方案页
              CreatorEarningsPage(), // 创作收益页
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 20, // 进一步减小图标尺寸
            color: Theme.of(context).primaryColor
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: TextStyle(
              fontSize: 14, // 进一步减小字体尺寸
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.onSurface
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: TextStyle(
              fontSize: 10, // 进一步减小字体尺寸
              color: Colors.grey[600]
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
// lib/plan_details_page.dart (新建)
import 'package:flutter/material.dart';
import 'solution_market_page.dart'; // For TravelPlanMarketItem model

class PlanDetailsPage extends StatelessWidget {
  final TravelPlanMarketItem plan;

  const PlanDetailsPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    // 模拟行程日数据
    final List<Map<String, dynamic>> sampleItineraryDays = [
      {
        'day': 'Day 1',
        'title': '抵达与海滩漫步',
        'activities': [
          '09:00 - 12:30: 抵达三亚凤凰国际机场, 前往酒店',
          '13:30 - 14:30: 酒店入住，享受下午茶',
          '15:00 - 18:00: 亚龙湾沙滩漫步'
        ]
      },
      {
        'day': 'Day 2',
        'title': '海岛探索',
        'activities': [
          '10:00 - 16:00: 蜈支洲岛游玩 (潜水、水上项目)',
          '18:00 - 19:30: 海鲜大餐'
        ]
      },
      // ...更多天数
    ];

    // 模拟用户评价数据
    final List<Map<String, String>> sampleReviews = [
      {'user': '用户123456', 'rating': '5.0', 'comment': '这个行程非常棒!推荐的酒店很适合带孩子,沙滩活动也很丰富。', 'date': '2025-05-20'},
      {'user': '旅行者小王', 'rating': '4.5', 'comment': '行程安排非常合理,时间掌握得刚刚好。推荐的餐厅都很适合家庭用餐。', 'date': '2025-05-18'},
    ];


    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息区域 (模拟图片和大标题)
            Container(
              height: 200,
              width: double.infinity,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(plan.icon, size: 80, color: Theme.of(context).primaryColor),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('${plan.rating.toStringAsFixed(1)} (${plan.reviewCount}条评价)', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      const Spacer(),
                      Text(plan.price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('由 ${plan.creator} 创建', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    children: plan.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                  const Divider(height: 32, thickness: 1),

                  Text('行程概览', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                  const SizedBox(height: 12),
                  // 简化的行程列表
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sampleItineraryDays.length,
                    itemBuilder: (context, index) {
                      final dayData = sampleItineraryDays[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            child: Text(dayData['day'].substring(dayData['day'].length - 1)), // Day 数字
                          ),
                          title: Text(dayData['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                          children: (dayData['activities'] as List<String>).map((activity) => ListTile(
                            contentPadding: const EdgeInsets.only(left: 32, right: 16, top: 0, bottom: 4),
                            dense: true,
                            leading: Icon(Icons.circle, size: 8, color: Theme.of(context).hintColor),
                            title: Text(activity, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                          )).toList(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 32, thickness: 1),

                  Text('用户反馈 (${sampleReviews.length}条)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                  const SizedBox(height: 12),
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sampleReviews.length,
                      itemBuilder: (context, index) {
                        final review = sampleReviews[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(review['user']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    Text(review['rating']!, style: TextStyle(color: Colors.grey[700])),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(review['comment']!, style: TextStyle(color: Colors.grey[800])),
                                const SizedBox(height: 4),
                                Text(review['date']!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        );
                      }
                  ),
                ],
              ),
            ),
            Padding( // 底部购买按钮区域
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 实现购买/使用方案逻辑
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('购买/使用方案功能待实现')),
                  );
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                child: Text('使用此方案 (模拟 ${plan.price})'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
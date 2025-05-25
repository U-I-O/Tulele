// lib/my_published_plans_page.dart
import 'package:flutter/material.dart';

class PublishedPlan {
  final String title;
  final String submissionTime;
  final String status;
  final String? platformPrice;

  // *** 修改点：添加 const 构造函数 ***
  const PublishedPlan({ // <--- 添加 const
    required this.title,
    required this.submissionTime,
    required this.status,
    this.platformPrice,
  });
}

class MyPublishedPlansPage extends StatelessWidget {
  const MyPublishedPlansPage({super.key});

  // *** 修改点：移除列表前的 const，因为列表本身不是 const，但其元素可以是。
  // 或者，如果所有字段都是final且适合const，可以将列表也设为const，
  // 但通常对于实例变量中的列表，列表本身不必是const。
  // 这里我们保持列表本身为 final，但其内容通过 const 构造函数创建。
  final List<PublishedPlan> _publishedPlans = const [ // <--- 列表前的 const 可以保留，因为元素都是 const
    // *** 修改点：使用 const 构造函数创建实例 ***
    PublishedPlan(title: '三亚海岛度假 | 亲子游玩5日行程', submissionTime: '2025-05-15 10:23', status: '审核中'),
    PublishedPlan(title: '丽江古城休闲游', submissionTime: '2025-04-20 15:47', status: '已上架', platformPrice: '¥29.90'),
    PublishedPlan(title: '深度探索徽州文化3日', submissionTime: '2025-03-10 09:11', status: '已驳回'),
    PublishedPlan(title: '城市CityWalk指南-上海篇', submissionTime: '2025-02-01 14:00', status: '已上架', platformPrice: '¥9.90'),
  ];

  Color _getStatusColor(String status, BuildContext context) {
    switch (status) {
      case '审核中':
        return Colors.orange.shade600;
      case '已上架':
        return Colors.green.shade600;
      case '已驳回':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '审核中':
        return Icons.hourglass_top_outlined;
      case '已上架':
        return Icons.check_circle_outline_outlined;
      case '已驳回':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _publishedPlans.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('您还没有发布过任何方案', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('去“发布方案”页分享您的精彩旅程吧！', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _publishedPlans.length,
        itemBuilder: (context, index) {
          final plan = _publishedPlans[index];
          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '提交时间: ${plan.submissionTime}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getStatusIcon(plan.status), color: _getStatusColor(plan.status, context), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            plan.status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(plan.status, context),
                            ),
                          ),
                        ],
                      ),
                      if (plan.status == '已上架' && plan.platformPrice != null)
                        Text(
                          '平台定价: ${plan.platformPrice}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).hintColor),
                        ),
                    ],
                  ),
                  if (plan.status == '审核中')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '平台正在审核您的行程方案，预计需要1-2个工作日。审核通过后我们会为方案定价并上架至方案市场。',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                      ),
                    ),
                  if (plan.status == '已驳回')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '抱歉，您的方案未通过审核，请查看通知中心了解详情并修改。',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (plan.status == '已驳回' || plan.status == '审核中')
                        TextButton(
                          onPressed: () { /* TODO: 编辑方案 */ },
                          child: const Text('编辑'),
                        ),
                      if (plan.status == '已上架')
                        TextButton(
                          onPressed: () { /* TODO: 查看方案表现/数据 */ },
                          child: const Text('查看数据'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('查看 "${plan.title}" 方案详情 (待实现)')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            textStyle: const TextStyle(fontSize: 14)
                        ),
                        child: const Text('查看'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
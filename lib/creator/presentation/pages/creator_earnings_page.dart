// lib/creator_earnings_page.dart
import 'package:flutter/material.dart';

class EarningsData {
  final String period;
  final double amount;
  // *** 修改点：添加 const 构造函数 ***
  const EarningsData(this.period, this.amount); // <--- 添加 const
}

class CreatorEarningsPage extends StatelessWidget {
  const CreatorEarningsPage({super.key});

  // 模拟收益数据
  // 这些 final 成员可以在 StatelessWidget 中直接初始化
  final double currentMonthEarnings = 258.60;
  final String currentMonthPeriod = "2025-05-01 至 2025-05-31";

  // *** 修改点：移除列表前的 const，并确保元素使用 const 构造 ***
  final List<EarningsData> earningsTrend = const [ // <--- 列表前的 const 可以保留
    // *** 修改点：使用 const 构造函数创建实例 ***
    EarningsData("4/10", 50.0),
    EarningsData("4/17", 120.5),
    EarningsData("4/24", 90.0),
    EarningsData("5/1", 150.75),
    EarningsData("5/8", 200.0),
    EarningsData("5/15", 230.20),
    EarningsData("5/22", 258.60),
  ];

  final Map<String, String> earningsBreakdown = const { // Map 可以是 const
    "平台总销售额": "¥1,120.00",
    "基础激励比例": "20%",
    "评分提升加成": "+2%",
    "精选方案奖励": "+3%",
    "实际激励比例": "25%",
  };

  final List<Map<String, dynamic>> planPerformance = const [ // 内部的 Map 也是 const
    {'name': '三亚海岛度假', 'users': 128, 'earnings': 98.50, 'status': '热门'},
    {'name': '丽江古城休闲游', 'users': 85, 'earnings': 158.60, 'status': '持续上升'},
    {'name': '城市CityWalk指南-上海篇', 'users': 32, 'earnings': 1.50, 'status': '新晋'},
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsSummaryCard(context),
            const SizedBox(height: 24.0),
            _buildSectionTitle(context, '收益趋势 (模拟图表区)'),
            _buildEarningsTrendChartPlaceholder(context),
            const SizedBox(height: 24.0),
            _buildSectionTitle(context, '本月激励构成'),
            _buildEarningsBreakdownCard(context),
            const SizedBox(height: 24.0),
            _buildSectionTitle(context, '方案表现'),
            _buildPlanPerformanceList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildEarningsSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5月创作激励',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${currentMonthEarnings.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '结算周期: $currentMonthPeriod',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.history_outlined, size: 20),
              label: const Text('查看历史激励'),
              onPressed: () { /* TODO: 跳转到历史激励页面 */ },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).hintColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsTrendChartPlaceholder(BuildContext context) {
    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: 200,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey[300]!)
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart_outlined, size: 48, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                '收益趋势图表展示区域',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height:4),
              Text(
                '(需要集成图表库如 charts_flutter 或 fl_chart)',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdownCard(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: earningsBreakdown.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPlanPerformanceList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: planPerformance.length,
      itemBuilder: (context, index) {
        final item = planPerformance[index];
        return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPerformanceMetric(context, Icons.people_alt_outlined, "使用人数", item['users'].toString()),
                      _buildPerformanceMetric(context, Icons.attach_money_outlined, "贡献收益", "¥${(item['earnings'] as double).toStringAsFixed(2)}"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Chip(
                      label: Text(item['status'], style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                ],
              ),
            )
        );
      },
    );
  }

  Widget _buildPerformanceMetric(BuildContext context, IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
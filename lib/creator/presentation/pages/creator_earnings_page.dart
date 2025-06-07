// lib/creator_earnings_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
            _buildSectionTitle(context, '收益趋势'),
            _buildEarningsTrendChart(context),
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
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: theme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 改为居中对齐
            children: [
              // 标题部分
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // 标题行也居中
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '5月创作激励',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 金额显示
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // 金额行居中
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentMonthEarnings.toStringAsFixed(2),
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              // 日期信息居中
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // 日期行居中
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '结算周期: $currentMonthPeriod',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 查看历史按钮 - 保持居中
              Center( // 确保按钮居中
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history_outlined, size: 18),
                  label: const Text('查看历史激励'),
                  onPressed: () { /* TODO: 跳转到历史激励页面 */ },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsTrendChart(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '近期收益变化',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 50,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= earningsTrend.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              earningsTrend[index].period,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  minX: 0,
                  maxX: earningsTrend.length - 1.0,
                  minY: 0,
                  maxY: 300,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        earningsTrend.length,
                        (index) => FlSpot(index.toDouble(), earningsTrend[index].amount),
                      ),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withOpacity(0.8),
                          theme.primaryColor,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: theme.primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.primaryColor.withOpacity(0.3),
                            theme.primaryColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot touchedSpot) => theme.colorScheme.surface,
                      tooltipBorderRadius: BorderRadius.circular(8),
                      tooltipBorder: BorderSide(
                        color: theme.primaryColor.withOpacity(0.2),
                      ),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final index = barSpot.x.toInt();
                          return LineTooltipItem(
                            '${earningsTrend[index].period}: ¥${barSpot.y.toStringAsFixed(2)}',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdownCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
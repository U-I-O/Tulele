// lib/trips/presentation/pages/my_trips_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // 引入ui包以使用ImageFilter (虽然在此版本卡片中未使用，但保留以备将来扩展)
import 'create_trip_options_page.dart';
import 'trip_detail_page.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  // 示例行程数据，实际应用中会从后端或本地存储获取
  // 为卡片添加更多信息，如地点、参与人数等，以便更接近参考图的丰富度
  final List<Map<String, dynamic>> _trips = [
    {
      'title': '三亚海岛度假',
      'date': '2025/06/01 - 2025/06/05',
      'color': Colors.blue.shade400, // 直接使用Color对象
      'id': '1',
      'location': '海南三亚',
      'participants': 3,
      'status': '已计划', // 例如：已计划, 进行中, 已完成
      'coverImageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmVhY2h8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'title': '北京文化之旅',
      'date': '2025/07/15 - 2025/07/20',
      'color': Colors.green.shade400,
      'id': '2',
      'location': '中国北京',
      'participants': 2,
      'status': '已计划',
      'coverImageUrl': null,
    },
    {
      'title': '日本动漫探索',
      'date': '2025/08/10 - 2025/08/18',
      'color': Colors.orange.shade400, // 更改颜色以更好地区分
      'id': '3',
      'location': '东京 & 大阪',
      'participants': 1,
      'status': '进行中',
      'coverImageUrl': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dG9reW98ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    }
  ];

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('行程夹'),
        centerTitle: true,
        backgroundColor: Colors.white, // AppBar 背景设为白色
        elevation: 0.5, // AppBar 轻微阴影
        foregroundColor: onSurfaceColor, // AppBar 文字和图标颜色
      ),
      backgroundColor: Colors.grey[100], // 页面背景使用非常浅的灰色
      body: _trips.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage_outlined, size: 70, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              '暂无行程',
              style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                '点击右下角的 "+" 按钮，开始创建您的第一次精彩旅程吧！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.5),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0), // 增加底部padding给FAB和导航栏空间
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          final Color tripColor = trip['color'] as Color;

          return Card(
            elevation: 2.0, // 卡片阴影
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // 圆角卡片
            ),
            clipBehavior: Clip.antiAlias, // 确保内容在圆角内
            child: InkWell( // 使整个卡片可点击
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
              borderRadius: BorderRadius.circular(12.0),
              child: Row(
                children: [
                  // 左侧彩色竖条
                  Container(
                    width: 8.0,
                    height: 110, // 根据卡片内容大致匹配高度
                    decoration: BoxDecoration(
                      color: tripColor,
                      // 如果希望竖条也有圆角，可以设置：
                      // borderRadius: const BorderRadius.only(
                      //   topLeft: Radius.circular(12.0),
                      //   bottomLeft: Radius.circular(12.0),
                      // ),
                    ),
                  ),
                  // 右侧内容区域
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            trip['title']!,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6.0),
                              Text(
                                trip['date']!,
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6.0),
                              Expanded(
                                child: Text(
                                  trip['location'] ?? '地点未定',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    '${trip['participants'] ?? 1}人行',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tripColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  trip['status'] ?? '未知状态',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: tripColor, // 使用更深的颜色以保证对比度
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 右上角更多操作按钮 (可选)
                  Material( // 使用Material包裹IconButton以支持InkWell效果
                    color: Colors.transparent,
                    child: IconButton(
                      padding: const EdgeInsets.all(12.0), // 调整padding使点击区域合适
                      constraints: const BoxConstraints(), // 移除默认的最小尺寸限制
                      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20),
                      tooltip: '更多操作',
                      onPressed: () {
                        // TODO: 实现更多操作，例如编辑、删除、分享等
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('更多操作 for "${trip['title']}"')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 假设 create_trip_options_page.dart 也在 lib/trips/presentation/pages/ 目录下
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripOptionsPage()),
          );
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
        tooltip: '创建新行程',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
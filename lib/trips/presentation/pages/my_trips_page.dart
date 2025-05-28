// lib/trips/presentation/pages/my_trips_page.dart
// (确保此文件位于 lib/trips/presentation/pages/ 目录下，并在 main.dart 中正确引用)
// (如果之前它在 lib/ 根目录，请移动到指定位置并更新 main.dart 中的 import)

import 'package:flutter/material.dart';
import 'dart:ui'; // 引入ui包以使用ImageFilter
import 'create_trip_options_page.dart'; // 假设此文件也在 pages 目录下
import 'trip_detail_page.dart'; // 引入新的行程详情页

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  final List<Map<String, dynamic>> _trips = [
    {
      'title': '三亚海岛度假',
      'date': '2025/06/01 - 2025/06/05',
      'color': Colors.blue.shade300,
      'id': '1', // 确保每个行程有唯一ID
      'imageUrl': null,
    },
    {
      'title': '北京文化之旅',
      'date': '2025/07/15 - 2025/07/20',
      'color': Colors.green.shade300,
      'id': '2',
      'imageUrl': null,
    },
    {
      'title': '日本动漫探索',
      'date': '2025/08/10 - 2025/08/18',
      'color': Colors.red.shade300,
      'id': '3',
      'imageUrl': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dG9reW98ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('行程夹'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: _trips.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              '暂无行程',
              style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              '点击右下角 "+" 开始创建您的第一次旅程吧！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[400]),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return GestureDetector(
            onTap: () {
              // *** 修改点：导航到 TripDetailPage 并传递 tripId ***
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailPage(
                    tripId: trip['id'] as String, // 传递行程ID
                    initialMode: TripMode.view,  // 默认以浏览模式打开
                  ),
                ),
              );
            },
            child: Card(
              elevation: 4.0,
              margin: const EdgeInsets.only(bottom: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: trip['imageUrl'] == null ? (trip['color'] as Color) : null,
                      image: trip['imageUrl'] != null
                          ? DecorationImage(
                        image: NetworkImage(trip['imageUrl'] as String),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                      )
                          : null,
                    ),
                  ),
                  if (trip['imageUrl'] != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16.0),
                          bottomRight: Radius.circular(16.0),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trip['title']!,
                          style: const TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1,1))
                              ]
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          trip['date']!,
                          style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.white70,
                              shadows: [
                                Shadow(blurRadius: 1.0, color: Colors.black38, offset: Offset(1,1))
                              ]
                          ),
                        ),
                      ],
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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
        child: const Icon(Icons.add),
      ),
    );
  }
}
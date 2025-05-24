// lib/my_trips_page.dart (修改后 - 移除AppBar和BottomNavigationBar)
import 'package:flutter/material.dart';
import 'create_trip_options_page.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  // 示例行程数据，实际应用中会从后端或本地存储获取
  final List<Map<String, String>> _trips = [
    {
      'title': '三亚海岛度假',
      'date': '2025/06/01 - 2025/06/05',
      'color': 'blue',
      'id': '1'
    },
    {
      'title': '北京文化之旅',
      'date': '2025/07/15 - 2025/07/20',
      'color': 'green',
      'id': '2'
    },
    {
      'title': '日本动漫探索',
      'date': '2025/08/10 - 2025/08/18',
      'color': 'red',
      'id': '3'
    }
  ];

  Color _getTripCardColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Theme.of(context).primaryColor.withOpacity(0.85);
      case 'green':
        return Colors.green.shade400.withOpacity(0.85);
      case 'red':
        return Colors.red.shade400.withOpacity(0.85);
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 每个页面现在有自己的Scaffold和AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的行程'),
        centerTitle: true,
      ),
      body: _trips.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无行程',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角 "+" 开始创建您的第一次旅程吧！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // 增加底部padding给FAB空间
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return GestureDetector(
            onTap: () {
              // TODO: 点击行程卡片，跳转到行程详情/编辑页面
              // 例如: Navigator.push(context, MaterialPageRoute(builder: (context) => ItineraryViewPage(tripId: trip['id']!)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('查看 "${trip['title']}" 行程详情 (待实现)')),
              );
            },
            child: Card(
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: _getTripCardColor(trip['color']!),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['title']!,
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        trip['date']!,
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripOptionsPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      // BottomNavigationBar 已经移到 main.dart 中的 MainPageNavigator
    );
  }
}
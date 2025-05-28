import 'package:flutter/material.dart';
import '../pages/trip_detail_page.dart'; // 为了引入 Activity, TripMode (与上面一样，需要良好规划模型和枚举位置)

class MapViewWidget extends StatelessWidget {
  final List<Activity> activities;
  final TripMode mode; // 虽然这里没用到，但保持接口一致性

  const MapViewWidget({super.key, required this.activities, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8)
      ),
      margin: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              '地图视图 (待集成高德地图)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (activities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: Text('今日活动数: ${activities.length}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              )
          ],
        ),
      ),
    );
  }
}
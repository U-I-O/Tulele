// lib/trips/presentation/widgets/map_view_widget.dart
import 'package:flutter/material.dart';
// 导入新的活动模型
import '../../../core/models/api_user_trip_model.dart'; // ApiActivityFromUserTrip 在这里定义
// 导入 TripMode 枚举
import '../../../core/enums/trip_enums.dart';

class MapViewWidget extends StatelessWidget {
  final List<ApiActivityFromUserTrip> activities; // <--- 类型已正确
  final TripMode mode;

  const MapViewWidget({super.key, required this.activities, required this.mode});

  @override
  Widget build(BuildContext context) {
    // 当前是一个占位符实现，如果未来要集成真实地图，这里的逻辑会复杂得多
    // 例如，需要将 activities 列表转换为地图标记点
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[200],
          // border: Border.all(color: Colors.grey[300]!), // 可以移除边框，让它更像内容区域
          // borderRadius: BorderRadius.circular(8)
      ),
      // margin: const EdgeInsets.all(12), // margin 也可以由父级控制或移除
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              '地图视图 (待实现)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (activities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top:8.0),
                // 显示当前选中日期的活动数量
                child: Text('当前日期活动数: ${activities.length}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: Text('当前日期无活动可在地图上显示', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              )
          ],
        ),
      ),
    );
  }
}
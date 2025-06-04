// lib/trips/presentation/widgets/map_view_widget.dart
import 'package:flutter/material.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/enums/trip_enums.dart';

// 假设你使用 amap_flutter_map 插件
// import 'package:amap_flutter_map/amap_flutter_map.dart';
// import 'package:amap_flutter_base/amap_flutter_base.dart'; // For LatLng

// 模拟 AMapController 和 LatLng (实际使用时从插件导入)
class AMapController {
  void moveCamera(CameraUpdate update) {}
  Future<void> addMarker(MarkerOption option) async {}
  Future<void> clearMarkers() async {}
}
class CameraUpdate {
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) => CameraUpdate();
  static CameraUpdate newLatLngZoom(LatLng latlng, double zoom) => CameraUpdate();
}
class LatLng { final double latitude; final double longitude; LatLng(this.latitude, this.longitude); }
class LatLngBounds { final LatLng northeast; final LatLng southwest; LatLngBounds({required this.northeast, required this.southwest}); }
class MarkerOption { final LatLng? position; final String? title; final String? snippet; MarkerOption({this.position, this.title, this.snippet});}
// 模拟结束

class MapViewWidget extends StatefulWidget {
  final List<ApiActivityFromUserTrip> activities;
  final TripMode mode;

  const MapViewWidget({super.key, required this.activities, required this.mode});

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  AMapController? _mapController;
  final String _yourAmapKeyForMap = "YOUR_AMAP_KEY_FOR_MAP_DISPLAY"; // 地图展示也需要Key

  // static const AMapPrivacyStatement amapPrivacyStatement = AMapPrivacyStatement(hasContains: true, hasShow: true, hasAgree: true); // 插件要求

  void _onMapCreated(AMapController controller) {
    _mapController = controller;
    _addMarkersToMap();
  }

  void _addMarkersToMap() {
    if (_mapController == null || widget.activities.isEmpty) return;

    _mapController!.clearMarkers(); // 清除旧标记

    List<LatLng> points = [];
    for (var activity in widget.activities) {
      // 确保你的 ApiActivityFromUserTrip 模型中有坐标信息
      // 假设坐标存储在 activity.coordinates Map<String, double> 中
      // final lat = activity.coordinates?['latitude'];
      // final lng = activity.coordinates?['longitude'];
      // 这里用模拟数据代替
      final lat = 40.0 + (widget.activities.indexOf(activity) * 0.01); // 模拟纬度
      final lng = 116.3 + (widget.activities.indexOf(activity) * 0.01); // 模拟经度


      if (lat != null && lng != null) {
        final position = LatLng(lat, lng);
        points.add(position);
        _mapController!.addMarker(MarkerOption(
          position: position,
          title: activity.title,
          snippet: activity.location ?? '',
        ));
      }
    }

    if (points.isNotEmpty) {
      if (points.length == 1) {
        _mapController!.moveCamera(CameraUpdate.newLatLngZoom(points.first, 14)); // 缩放到单个点
      } else {
        // 计算边界以包含所有点
        double minLat = points.first.latitude, maxLat = points.first.latitude;
        double minLng = points.first.longitude, maxLng = points.first.longitude;
        for (var point in points) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }
        _mapController!.moveCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50, // padding
        ));
      }
    }
  }
  
  @override
  void didUpdateWidget(covariant MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities != widget.activities) {
      _addMarkersToMap(); // 活动列表变化时更新标记
    }
  }


  @override
  Widget build(BuildContext context) {
    // --- 真实地图集成 ---
    /*
    return AMapWidget(
      apiKey: AMapApiKey(iosKey: _yourAmapKeyForMap, androidKey: _yourAmapKeyForMap),
      onMapCreated: _onMapCreated,
      privacyStatement: amapPrivacyStatement,
      initialCameraPosition: CameraPosition(target: LatLng(39.909187, 116.397451), zoom: 10), // 默认北京
    );
    */
    
    // --- 当前占位符实现 ---
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              '高德地图视图 (待真实集成)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (widget.activities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: Text('当前日期活动数: ${widget.activities.length}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
// lib/trips/presentation/widgets/map_view_widget.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/enums/trip_enums.dart';
import 'dart:async';

// 导入百度地图官方插件
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_baidu_mapapi_search/flutter_baidu_mapapi_search.dart';
// 修改TripMapPage类实现完整的旅行地图页面
class TripMapPage extends StatefulWidget {
  final ApiUserTrip userTripData;
  final int selectedDayIndex;

  const TripMapPage({
    Key? key,
    required this.userTripData,
    required this.selectedDayIndex,
  }) : super(key: key);

  @override
  State<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  int _currentDayIndex = 0;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _currentDayIndex = widget.selectedDayIndex;
  }

  @override
  Widget build(BuildContext context) {
    final dayInfo = widget.userTripData.days.isNotEmpty && _currentDayIndex >= 0 && _currentDayIndex < widget.userTripData.days.length
        ? "第${widget.userTripData.days[_currentDayIndex].dayNumber}天"
        : "无行程";
    
    final activities = widget.userTripData.days.isNotEmpty && _currentDayIndex >= 0 && _currentDayIndex < widget.userTripData.days.length
        ? widget.userTripData.days[_currentDayIndex].activities
        : [];
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userTripData.displayName ?? "我的旅行",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              dayInfo,
              style: TextStyle(fontSize: 14, color: Colors.grey[200]),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 地图
          Positioned.fill(
            child: EnhancedMapViewWidget(
              userTripData: widget.userTripData,
              activities: activities as List<ApiActivityFromUserTrip>,
              mode: TripMode.view,
            ),
          ),
          
          // 日期选择栏
          if (widget.userTripData.days.length > 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.userTripData.days.length,
                  itemBuilder: (context, index) {
                    final day = widget.userTripData.days[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentDayIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _currentDayIndex == index ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            "第${day.dayNumber}天",
                            style: TextStyle(
                              color: _currentDayIndex == index ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
          // 加载指示器
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

// 增强的地图视图组件
class EnhancedMapViewWidget extends StatefulWidget {
  final ApiUserTrip userTripData;
  final List<ApiActivityFromUserTrip> activities;
  final TripMode mode;

  const EnhancedMapViewWidget({
    Key? key,
    required this.userTripData,
    required this.activities,
    required this.mode,
  }) : super(key: key);

  @override
  State<EnhancedMapViewWidget> createState() => _EnhancedMapViewWidgetState();
}

class _EnhancedMapViewWidgetState extends State<EnhancedMapViewWidget> {
  BMFMapController? _mapController;
  // 增加反地理编码的搜索实例
  BMFReverseGeoCodeSearch? _reverseGeoSearch;
  BMFTransitRouteSearch? _transitRouteSearch;
  bool _isRoutePlanningLoading = false;
  /// 路线 polyline
  BMFPolyline? _polyline;
  /// 路线数组，用于管理多条路线
  final List<BMFPolyline> _polylines = [];
  /// 路线ID计数器
  int _polylineIdCounter = 0;
  final List<BMFMarker> _markers = [];
  
  // 初始化地图选项
  final BMFMapOptions _initMapOptions = BMFMapOptions(
    center: BMFCoordinate(39.917215, 116.380341),
    zoomLevel: 12,
    mapPadding: BMFEdgeInsets(left: 30, top: 30, right: 30, bottom: 30),
    compassPosition: BMFPoint(40, 40),
    gesturesEnabled: true,
    zoomEnabled: true,
    scrollEnabled: true,
    overlookEnabled: true,
    rotateEnabled: true,
    changeCenterWithDoubleTouchPointEnabled: true,
  );

  @override
  void initState() {
    super.initState();
    _transitRouteSearch = BMFTransitRouteSearch();
    _reverseGeoSearch = BMFReverseGeoCodeSearch();
  }
  
  @override
  void dispose() {
    _transitRouteSearch = null;
    super.dispose();
  }

  // 地图创建完成回调
  void _onMapCreated(BMFMapController controller) {
    _mapController = controller;
    
    // 确保地图可以用手势操作
    _enableMapGestures();
    
    // 添加标记点击事件监听
    _mapController!.setMapClickedMarkerCallback(callback: (BMFMarker marker) {
      _onMarkerClicked(marker);
    });
    
    // 更新标记和路线
    _updateMarkersAndRoutes();
  }
  
  // 启用地图手势
  void _enableMapGestures() {
    if (_mapController == null) return;
    
    // 根据文档示例启用所有手势
    _mapController!.updateMapOptions(BMFMapOptions(
      scrollEnabled: true,   // 启用平移
      zoomEnabled: true,     // 启用缩放
      overlookEnabled: true, // 启用俯视
      rotateEnabled: true,   // 启用旋转
      changeCenterWithDoubleTouchPointEnabled: true // 双击放大地图时以点击处为地图中心
    ));
  }

  // 处理标记点击事件
  void _onMarkerClicked(BMFMarker marker) {
    // 根据marker的identifier找到对应的活动
    final activity = widget.activities.firstWhere(
      (act) => act.id == marker.identifier,
      orElse: () => widget.activities[int.tryParse(marker.identifier?.split('_').last ?? '-1') ?? 0],
    );
    
    // 显示活动简介对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.description != null && activity.description!.isNotEmpty)
              Text(activity.description!),
            const SizedBox(height: 8),
            Text('时间: ${activity.startTime ?? ''} - ${activity.endTime ?? ''}'),
            if (activity.actualCost != null)
              Text('费用: ¥${activity.actualCost}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 更新标记和路线
  void _updateMarkersAndRoutes() async {
    if (_mapController == null || !mounted) return;

    clearAllMarkers();
    clearAllPolylines();
    
    // 检查是否有活动
    if (widget.activities.isEmpty) {
      return;
    }
    
    // 收集有效坐标点
    final List<BMFCoordinate> validPoints = [];
    final List<ApiActivityFromUserTrip> validActivities = [];
    
    
    // 创建标记
    for (int i = 0; i < widget.activities.length; i++) {
      final activity = widget.activities[i];
      
      // 检查活动是否有有效坐标
      if (activity.coordinates == null ||
          activity.coordinates!['latitude'] == null ||
          activity.coordinates!['longitude'] == null) {
        continue;
      }
      
        final lat = activity.coordinates!['latitude']!;
        final lng = activity.coordinates!['longitude']!;
        final position = BMFCoordinate(lat, lng);
      validPoints.add(position);
      validActivities.add(activity);
      
      // 选择图标
      String icon = 'resources/icon_mark.png';

      // 添加标记点
      await addMarkerToMap(
        position: position,
        title: activity.title ,
        subtitle: "${activity.startTime ?? ''} - ${activity.endTime ?? ''}",
        identifier: activity.id ?? 'marker_$i',
        icon: icon,
      );
      debugPrint('当前添加的点坐标: ${position.latitude}, ${position.longitude}');
      debugPrint('当前活动: ${activity.title}');      
    }
    
    // 如果有多个有效点，绘制简单路线
    if (validPoints.length > 1) {
      setState(() {
        _isRoutePlanningLoading = true;
      });
      
      // 尝试进行路线规划
      await _planTransitRoute(validActivities);
      
      setState(() {
        _isRoutePlanningLoading = false;
      });
    }
    
    // 调整地图视图以显示所有标记
    _adjustMapViewToShowAllMarkers(validPoints);
  }
  
  // 规划公交路线
  Future<void> _planTransitRoute(List<ApiActivityFromUserTrip> activities) async {
    if (_transitRouteSearch == null || _reverseGeoSearch == null || activities.length < 2) return;
    

    debugPrint('=== 路线规划开始: ${activities.length}个活动点 ===');

    // 尝试为每对相邻活动规划路线
    for (int i = 0; i < activities.length - 1; i++) {
      final startActivity = activities[i];
      final endActivity = activities[i + 1];
      
      debugPrint('规划路线: 从${startActivity.title}到${endActivity.title}');
      
      // 确保有坐标
      if (startActivity.coordinates == null || endActivity.coordinates == null) {
        debugPrint('错误: 活动坐标为空');
        continue;
      }
      
      // 提取坐标
      final startLat = startActivity.coordinates!['latitude']!;
      final startLng = startActivity.coordinates!['longitude']!;
      final endLat = endActivity.coordinates!['latitude']!;
      final endLng = endActivity.coordinates!['longitude']!;
      
      debugPrint('起点坐标: $startLat, $startLng');
      debugPrint('终点坐标: $endLat, $endLng');
      
      // 获取起点和终点城市
      final startCity = await _getCityFromCoordinate(startLat, startLng);
      final endCity = await _getCityFromCoordinate(endLat, endLng);
      
      debugPrint('起点城市: $startCity, 终点城市: $endCity');
      
      // 创建起点和终点
      final BMFPlanNode from = BMFPlanNode(
        pt: BMFCoordinate(startLat, startLng),
        name: startActivity.title,
      );
      
      final BMFPlanNode to = BMFPlanNode(
        pt: BMFCoordinate(endLat, endLng),
        name: endActivity.title,
      );
      
      // 判断是市内还是跨城
      if (startCity == endCity) {
        // 同城交通
        debugPrint('执行市内交通规划: $startCity');
        await _planTransitInCityEfficient(from, to, startCity);
      } else {
        // 跨城交通
        debugPrint('执行跨城交通规划: $startCity → $endCity');
        await _planCrossCityTransit(from, to, startCity, endCity);
      }
    }
  }

  // 获取坐标对应的城市
  Future<String> _getCityFromCoordinate(double lat, double lng) async {
    debugPrint('开始反地理编码: 获取($lat, $lng)的城市信息');
    final Completer<String> completer = Completer<String>();
    
    // 设置反地理编码搜索参数
    BMFReverseGeoCodeSearchOption option = BMFReverseGeoCodeSearchOption(
      location: BMFCoordinate(lat, lng),
      radius: 500,
      isLatestAdmin: true,
    );
    
    // 设置回调
    _reverseGeoSearch!.onGetReverseGeoCodeSearchResult(callback: (result, errorCode) {
      if (errorCode == BMFSearchErrorCode.NO_ERROR && result != null) {
        final city = result.addressDetail?.city ?? '北京市';
        debugPrint('反地理编码成功: 城市为 $city');
        completer.complete(city);
      } else {
        debugPrint('反地理编码失败: 错误码 $errorCode，使用默认城市');
        completer.complete('北京市'); // 默认城市
      }
    });
    
    // 发起反地理编码搜索
    bool searchResult = await _reverseGeoSearch!.reverseGeoCodeSearch(option);
    debugPrint('发起反地理编码搜索: ${searchResult ? "成功" : "失败"}');
    
    return completer.future;
  }

  // =============== 新增高效版函数 ===============
  
  /// 高效版本的市内交通规划
  Future<void> _planTransitInCityEfficient(BMFPlanNode from, BMFPlanNode to, String city) async {
    debugPrint('开始高效版市内交通规划: $city');
    
    
    // 设置回调
    final completer = Completer<bool>();
    _transitRouteSearch!.onGetTransitRouteSearchResult(callback: (result, errorCode) {
      if (errorCode != BMFSearchErrorCode.NO_ERROR || result.routes == null || result.routes!.isEmpty) {
        debugPrint('市内路线规划失败或无结果: 错误码 $errorCode');
        // 规划失败时直接连接起点和终点
        _drawSimplePolyline([from.pt!, to.pt!]);
        completer.complete(false);
        return;
      }
      
      debugPrint('市内路线规划成功: ${result.routes?.length ?? 0}个方案');
      
      // 使用第一个方案
      final route = result.routes!.first;
      
      // 提取所有坐标点
      List<BMFCoordinate> allPoints = [];
      
      // 添加起点
      if (route.starting?.location != null) {
        allPoints.add(route.starting!.location!);
      }
      
      // 收集路径中的所有点
      for (final step in route.steps ?? []) {
        if (step.points != null && step.points!.isNotEmpty) {
          allPoints.addAll(step.points!);
        }
      }
      
      // 添加终点
      if (route.terminal?.location != null) {
        allPoints.add(route.terminal!.location!);
      }
      
      // 使用高效方式绘制
      if (allPoints.length >= 2) {
        _drawSimplePolyline(allPoints);
      } else {
        // 如果没有足够的点，直接连接起点和终点
        _drawSimplePolyline([from.pt!, to.pt!]);
      }
      
      completer.complete(true);
    });
    
    // 创建公交路线规划参数
    final BMFTransitRoutePlanOption option = BMFTransitRoutePlanOption(
      from: from,
      to: to,
      city: city,
    );
    
    // 发起搜索
    bool searchResult = await _transitRouteSearch!.transitRouteSearch(option);
    debugPrint('发起高效版市内交通规划搜索: ${searchResult ? "成功" : "失败"}');
    
    // 等待回调完成
    await completer.future;
    return;
  }
  
  /// 高效版本的路线绘制函数
  Future<void> _drawSimplePolyline(List<BMFCoordinate> points) async {
    debugPrint('绘制高效版路线, 点数量: ${points.length}');
    
    if (_mapController == null || points.length < 2) return;
    
    try {
      await addPolylineToMap(
        points: points,
        width: 8,
        color: Colors.blue, // 或其他颜色
        texturePath: "resources/traffic_texture_smooth.png", // 如果需要纹理
        updateView: true,
      );  
      
      // 设置地图视图范围
      if (points.length >= 2) {
        double minLat = double.infinity;
        double maxLat = -double.infinity;
        double minLng = double.infinity;
        double maxLng = -double.infinity;
        
        for (BMFCoordinate point in points) {
          minLat = min(minLat, point.latitude);
          maxLat = max(maxLat, point.latitude);
          minLng = min(minLng, point.longitude);
          maxLng = max(maxLng, point.longitude);
        }
        
        // 创建矩形区域
        final bounds = BMFCoordinateBounds(
          northeast: BMFCoordinate(maxLat, maxLng),
          southwest: BMFCoordinate(minLat, minLng)
        );
        
        // 设置地图显示区域，添加边距
        await _mapController!.setVisibleMapRectWithPadding(
          visibleMapBounds: bounds,
          insets: EdgeInsets.all(50),
          animated: true
        );
      }
    } catch (e) {
      debugPrint('高效版路线绘制出错: $e');
      
      // 简单错误处理
      try {
        await addPolylineToMap(
          points: points,
          width: 8,
          color: Colors.blue, // 或其他颜色
          texturePath: "resources/traffic_texture_smooth.png", // 如果需要纹理
          updateView: true,
        );
      } catch (e2) {
        debugPrint('备用路线绘制也失败: $e2');
      }
    }
  }
  
  /// 高效版本的跨城交通规划
  Future<void> _planCrossCityTransit(BMFPlanNode from, BMFPlanNode to, String fromCity, String toCity) async {
    debugPrint('开始高效版跨城交通规划: 从$fromCity到$toCity');    
    // 设置回调
    final completer = Completer<bool>();    
    // 创建跨城公交搜索实例
    final massTransitSearch = BMFMassTransitRouteSearch();    
    // 设置回调
    massTransitSearch.onGetMassTransitRouteSearchResult(callback: (result, errorCode) {
      if (errorCode != BMFSearchErrorCode.NO_ERROR || result == null || result.routes == null || result.routes!.isEmpty) {
        debugPrint('跨城交通规划失败或无结果: 错误码 $errorCode');
        // 规划失败时直接连接起点和终点
        _drawDirectLine(from.pt!, to.pt!);
        completer.complete(false);
        return;
      }      
      debugPrint('跨城交通规划成功: ${result.routes?.length ?? 0}个方案');      
      // 使用第一个方案
      final route = result.routes!.first;      
      // 提取所有路线坐标点
      List<BMFCoordinate> allPoints = [];      
      // 遍历所有大段路线及子路段，提取坐标点
      for (final massTransitStep in route.steps ?? []) {
        for (final subStep in massTransitStep.steps ?? []) {
          if (subStep.points != null && subStep.points!.isNotEmpty) {
            allPoints.addAll(subStep.points!);
          }
        }
      }      
      // 使用官方示例的高效方式绘制路线
      if (allPoints.length >= 2) {
        _drawTexturedPolyline(allPoints);
      } else {
        // 如果没有足够的点，直接连接起点和终点
        _drawDirectLine(from.pt!, to.pt!);
      }
      
      completer.complete(true);
    });
    
    // 创建跨城公交路线规划参数
    final BMFMassTransitRoutePlanOption option = BMFMassTransitRoutePlanOption(
      from: BMFPlanNode(pt: from.pt, cityName: fromCity),
      to: BMFPlanNode(pt: to.pt, cityName: toCity),
    );
    
    // 发起搜索
    bool searchResult = await massTransitSearch.massTransitRouteSearch(option);
    debugPrint('发起高效版跨城交通规划搜索: ${searchResult ? "成功" : "失败"}');
    
    // 等待回调完成
    await completer.future;
    return;
  }
  
  /// 使用纹理绘制路线 - 官方推荐的高效方法
  Future<void> _drawTexturedPolyline(List<BMFCoordinate> points) async {
    debugPrint('使用纹理绘制路线, 点数量: ${points.length}');
    
    if (points.length < 2) return;
    
    try {
      await addPolylineToMap(
          points: points,
          width: 8,
          color: Colors.blue, // 或其他颜色
          texturePath: "resources/traffic_texture_smooth.png", // 如果需要纹理
          updateView: true,
        );
      
      // 设置地图显示范围
      _adjustMapViewToShowAllMarkers(points);
    } catch (e) {
      debugPrint('纹理路线绘制出错: $e');      
      // 简单错误处理 - 使用普通线条
      _addSimpleRoute(points);
    }
  }
  /// 使用两点直接绘制路线（可用作失败时的备选方案）
  Future<void> _drawDirectLine(BMFCoordinate start, BMFCoordinate end) async {
    debugPrint('绘制直线连接');
    
    try {
      await addPolylineToMap(
          points: [start, end],
          width: 6,
          color: Colors.orange, // 或其他颜色
          texturePath: "resources/traffic_texture_smooth.png", // 如果需要纹理
          updateView: true,
        );
    
      // 调整地图视图
      final bounds = BMFCoordinateBounds(
        northeast: BMFCoordinate(
          max(start.latitude, end.latitude), 
          max(start.longitude, end.longitude)
        ),
        southwest: BMFCoordinate(
          min(start.latitude, end.latitude), 
          min(start.longitude, end.longitude)
        )
      );
      
      await _mapController!.setVisibleMapBounds(bounds, true);
    } catch (e) {
      debugPrint('绘制直线连接失败: $e');
    }
  }
  // =============================================
  // 使用简单线路绘制连接坐标点，不使用动画
  Future<void> _addSimpleRoute(List<BMFCoordinate> points) async {
    debugPrint('开始添加普通线路, 点数量: ${points.length}');
    
    if (_mapController == null || points.length < 2) return;
    
    try {
      // 颜色列表（多色渐变效果）
      List<Color> colors = [
        Colors.blue,
        Colors.green,
        Colors.cyan,
        Colors.purple,
      ];
      
      // 如果点数较多，分段绘制以实现不同颜色效果
      if (points.length > 10) {
        // 将路线分为多段，每段使用不同颜色
        int segmentSize = points.length ~/ 4;  // 大致分为4段        
        for (int i = 0; i < 4; i++) {
          int startIdx = i * segmentSize;
          int endIdx = (i == 3) ? points.length : (i + 1) * segmentSize;          
          if (endIdx <= startIdx + 1) continue; // 至少需要2个点          
          List<BMFCoordinate> segmentPoints = points.sublist(startIdx, endIdx);        
          // 直接使用新函数添加路线
          await addPolylineToMap(
            points: segmentPoints,
            width: 6,
            color: colors[i], // 或其他颜色
            texturePath: "resources/traffic_texture_smooth.png", // 如果需要纹理
            updateView: true,
          );
      }
    } else {
       await addPolylineToMap(
            points: points,
            width: 6,
            color: colors[0], // 或其他颜色
            texturePath: "resources/traffic_texture_smooth.png", // 如果需要纹理
            updateView: true,
          );
      }
    } catch (e) {
      debugPrint('添加普通线路出错: $e');
      
      // 如果出错，尝试使用最简单的直线连接
      try {

        await addPolylineToMap(
          points: [points.first, points.last],
          width: 5,
          color: Colors.red, // 或其他颜色
          texturePath: "resources/traffic_texture_smooth.png", // 如果需要纹理
          updateView: true,
        );
        debugPrint('退化为简单直线连接');
      } catch (e2) {
        debugPrint('简单直线连接也失败: $e2');
      }
    }
  }
  
  // 调整地图视图以显示所有标记
  Future<void> _adjustMapViewToShowAllMarkers(List<BMFCoordinate> points) async {
    debugPrint('开始调整地图视图显示所有标记点, 点数量: ${points.length}');
    
    if (_mapController == null || points.isEmpty) return;
    
    if (points.length == 1) {
      // 只有一个点时，直接移动到该点
      debugPrint('只有一个点，直接移动到坐标: ${points[0].latitude}, ${points[0].longitude}');
      
      final BMFMapStatus mapStatus = BMFMapStatus(
        fLevel: 15,
        targetGeoPt: points[0],
      );
      bool result = await _mapController!.setNewMapStatus(mapStatus: mapStatus);
      debugPrint('移动地图: ${result ? "成功" : "失败"}');
    } else {
      // 多个点时，计算包含所有点的矩形区域
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;
      
      for (BMFCoordinate point in points) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }
      
      debugPrint('计算边界: 西南($minLat, $minLng), 东北($maxLat, $maxLng)');
      
      // 创建矩形区域
      final BMFCoordinateBounds bounds = BMFCoordinateBounds(
        northeast: BMFCoordinate(maxLat, maxLng),
        southwest: BMFCoordinate(minLat, minLng)
      );
      
      // 设置地图显示区域
      bool result = await _mapController!.setVisibleMapBounds(bounds, true);
      debugPrint('设置地图可见边界: ${result ? "成功" : "失败"}');
    }
    
    debugPrint('地图视图调整完成');
  }

  // ================================== 管理路线和标记工具类 ==================
  /// 管理路线和标记工具类 - 添加标记点到地图
  Future<BMFMarker?> addMarkerToMap({
    required BMFCoordinate position,
    required String title,
    String? subtitle,
    String? identifier,
    String icon = 'resources/icon_mark.png',
    bool updateView = false,
  }) async {
    if (_mapController == null) return null;
    
    debugPrint('添加标记点: $title at (${position.latitude}, ${position.longitude})');
    
    // 创建标记
    BMFMarker marker = BMFMarker.icon(
      position: position,
      title: title,
      subtitle: subtitle,
      identifier: identifier ?? 'marker_${_markers.length}',
      icon: icon,
      enabled: true,
    );
    
    // 添加到地图
    bool result = await _mapController!.addMarker(marker);
    if (result) {
      _markers.add(marker);
      debugPrint('标记点添加成功: ${marker.identifier}');
      
      // 如果需要，更新地图视图
      if (updateView) {
        await _adjustMapViewToShowAllMarkers([marker.position]);
      }
      
      return marker;
    } else {
      debugPrint('标记点添加失败');
      return null;
    }
  }

  /// 添加路线到地图
  Future<BMFPolyline?> addPolylineToMap({
    required List<BMFCoordinate> points,
    double width = 8,
    Color color = Colors.blue,
    String? texturePath,
    bool updateView = false,
  }) async {
    if (_mapController == null || points.length < 2) return null;
    
    debugPrint('添加路线, 点数量: ${points.length}');
    
    try {

      // 创建路线
      if (texturePath != null && texturePath.isNotEmpty) {
        // 使用纹理路线
        _polyline = BMFPolyline(
          width: width.toInt(),
          coordinates: points,
          indexs: [0],  // 使用单一索引绘制整条路径
          textures: [texturePath],
          dottedLine: false,
        );
      } else {
        // 使用颜色路线
        _polyline = BMFPolyline(
          width: width.toInt(),
          coordinates: points,
          indexs: [0],  // 使用单一索引
          colors: [color],
          lineDashType: BMFLineDashType.LineDashTypeNone,
          lineJoinType: BMFLineJoinType.LineJoinRound,
          lineCapType: BMFLineCapType.LineCapRound,
        );
      }
      
      // 添加到地图
      bool result = await _mapController!.addPolyline(_polyline!);
      if (result) {
        // 添加到路线数组
        _polylines.add(_polyline!);
        debugPrint('路线添加成功');
        
        // 如果需要，更新地图视图
        if (updateView) {
          await _adjustMapViewToShowAllMarkers(points);
        }
        
        return _polyline;
      } else {
        debugPrint('路线添加失败');
        return null;
      }
    } catch (e) {
      debugPrint('添加路线出错: $e');
      return null;
    }
  }

  /// 清除所有标记点
  Future<bool> clearAllMarkers() async {
    if (_mapController == null) return false;
    
    try {
      debugPrint('清除所有标记点: ${_markers.length}个');
      bool result = await _mapController!.cleanAllMarkers();
      if (result) {
        _markers.clear();
        debugPrint('所有标记点已清除');
      } else {
        debugPrint('清除标记点失败');
      }
      return result;
    } catch (e) {
      debugPrint('清除标记点出错: $e');
      return false;
    }
  }

  /// 清除所有路线
  Future<bool> clearAllPolylines() async {
    if (_mapController == null) return false;
    
    try {
      debugPrint('清除所有路线: ${_polylines.length}个');
      
      // 清除单路线对象
      if (_polyline != null) {
        await _mapController!.removeOverlay(_polyline!.id);
        _polyline = null;
      }
      
      // 清除数组中的每条路线
      bool allRemoved = true;
      for (var polyline in _polylines) {
        bool removed = await _mapController!.removeOverlay(polyline.id);
        if (!removed) {
          allRemoved = false;
          debugPrint('移除路线失败: ${polyline.id}');
        }
      }
      
      // 清空列表
      _polylines.clear();
      debugPrint('所有路线已清除');
      return allRemoved;
    } catch (e) {
      debugPrint('清除路线出错: $e');
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant EnhancedMapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.activities, oldWidget.activities)) {
      _updateMarkersAndRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 地图主体
        GestureDetector(
          child: BMFMapWidget(
      onBMFMapCreated: _onMapCreated, 
            mapOptions: _initMapOptions,
          ),
        ),
        
        // 加载指示器
        if (_isRoutePlanningLoading)
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text("正在规划路线...", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
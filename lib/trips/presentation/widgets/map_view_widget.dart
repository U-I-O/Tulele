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
              widget.userTripData.displayName,
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
  final List<BMFMarker> _markers = [];
  // 增加反地理编码的搜索实例
  BMFReverseGeoCodeSearch? _reverseGeoSearch;
  BMFTransitRouteSearch? _transitRouteSearch;
  bool _isRoutePlanningLoading = false;
  
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

    // 清除现有标记
    await _mapController!.cleanAllMarkers();
    _markers.clear();
    
    // 清除所有路线和覆盖物
    // await _mapController?.clearOverlays();
    
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
      
      // 使用BMFMarker.icon()代替弃用的构造方法
      BMFMarker marker = BMFMarker.icon(
        position: position,
        title: activity.title,
        subtitle: "${activity.startTime ?? ''} - ${activity.endTime ?? ''}",
        identifier: activity.id ?? 'marker_$i',
        icon: 'assets/icon/icon_mark.png',
        enabled: true,
      );

      debugPrint('当前添加的点坐标: ${position.latitude}, ${position.longitude}');
      debugPrint('当前活动: ${activity.title}');
      
      // 添加标记到地图
      bool result = await _mapController!.addMarker(marker);
      if (result) {
        _markers.add(marker);
      }
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
    
    // 清除已有路线
    // await _mapController?.clearOverlays();
    
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
        await _planTransitInCity(from, to, startCity);
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

  // 市内交通规划
  Future<void> _planTransitInCity(BMFPlanNode from, BMFPlanNode to, String city) async {
    debugPrint('开始市内交通规划搜索: $city');
    
    _transitRouteSearch!.onGetTransitRouteSearchResult(callback: (result, errorCode) {
      if (errorCode == BMFSearchErrorCode.NO_ERROR && result != null) {
        debugPrint('市内路线规划成功: ${result.routes?.length ?? 0}个方案');
        _drawTransitRoute(result);
      } else {
        debugPrint('市内路线规划失败: 错误码 $errorCode');
        // 如果路线规划失败，改用简单连线
        debugPrint('改用简单连线代替');
        _addSimpleRoute([from.pt!, to.pt!]);
      }
    });
    
    // 创建公交路线规划参数
    final BMFTransitRoutePlanOption option = BMFTransitRoutePlanOption(
      from: from,
      to: to,
      city: city,
    );
    
    // 发起搜索
    bool searchResult = await _transitRouteSearch!.transitRouteSearch(option);
    debugPrint('发起市内交通规划搜索: ${searchResult ? "成功" : "失败"}');
  }

  // 跨城交通规划
  Future<void> _planCrossCityTransit(BMFPlanNode from, BMFPlanNode to, String fromCity, String toCity) async {
    debugPrint('开始跨城交通规划: 从$fromCity到$toCity');
    
    // 创建跨城公交搜索实例
    final massTransitSearch = BMFMassTransitRouteSearch();
    
    massTransitSearch.onGetMassTransitRouteSearchResult(callback: (result, errorCode) {
      if (errorCode == BMFSearchErrorCode.NO_ERROR && result != null) {
        debugPrint('跨城路线规划成功: ${result.routes?.length ?? 0}个方案');
        _drawMassTransitRoute(result);
      } else {
        debugPrint('跨城路线规划失败: 错误码 $errorCode');
        // 如果路线规划失败，改用简单连线
        debugPrint('改用简单连线代替');
        _addSimpleRoute([from.pt!, to.pt!]);
      }
    });
    
    // 创建跨城公交路线规划参数
    final BMFMassTransitRoutePlanOption option = BMFMassTransitRoutePlanOption(
      from: BMFPlanNode(pt: from.pt, cityName: fromCity),
      to: BMFPlanNode(pt: to.pt, cityName: toCity),
    );
    
    // 发起搜索
    bool searchResult = await massTransitSearch.massTransitRouteSearch(option);
    debugPrint('发起跨城交通规划搜索: ${searchResult ? "成功" : "失败"}');
  }

  // 绘制公交路线
  void _drawTransitRoute(BMFTransitRouteResult result) async {
    debugPrint('开始绘制市内公交路线');
    
    if (_mapController == null || !mounted) return;
    
    // 获取路线方案
    final routes = result.routes;
    if (routes == null || routes.isEmpty) {
      debugPrint('绘制公交路线失败: 没有可用的路线方案');
      return;
    }
    
    debugPrint('使用第一种方案, 总共${routes.length}种方案');
    
    // 使用第一种方案
    final route = routes.first;
    debugPrint('路线步骤数量: ${route.steps?.length ?? 0}');
    
    try {
      // 收集所有路线点，创建简单连线
      List<BMFCoordinate> allPoints = [];
      
      // 添加起点
      if (route.starting?.location != null) {
        allPoints.add(route.starting!.location!);
      }
      
      // 尝试从各个步骤中提取关键点
      for (final step in route.steps ?? []) {
        debugPrint('提取步骤关键点');
        
        // 根据百度地图SDK文档获取正确的属性
        // 尝试提取可能的位置点信息
        try {
          // 公交步行段可能有起终点
          if (step is BMFWalkingStep) {
            if (step.points != null && step.points!.isNotEmpty) {
              allPoints.addAll(step.points!);
            }
          } 
          // 公交路段可能有其他位置信息
          else if (step is BMFTransitStep) {
            // 使用反射或尝试其他可能的属性
            final firstPoint = step.points?.firstOrNull;
            final lastPoint = step.points?.lastOrNull;
            if (firstPoint != null) allPoints.add(firstPoint);
            if (lastPoint != null && firstPoint != lastPoint) allPoints.add(lastPoint);
          }
        } catch (e) {
          debugPrint('尝试提取路线点出错: $e');
        }
      }
      
      // 添加终点
      if (route.terminal?.location != null) {
        allPoints.add(route.terminal!.location!);
      }
      
      // 确保至少有两个点用于绘制线路
      if (allPoints.length >= 2) {
        debugPrint('使用简单动画线路绘制，共${allPoints.length}个点');
        await _addSimpleRoute(allPoints);
      } else {
        debugPrint('没有足够的点来绘制路线');
      }
    } catch (e) {
      debugPrint('绘制路线出错: $e');
      
      // 如果有起点和终点，至少连接它们
      if (route.starting?.location != null && route.terminal?.location != null) {
        debugPrint('退回到简单起终点连线');
        await _addSimpleRoute([route.starting!.location!, route.terminal!.location!]);
      }
    }
    
    debugPrint('绘制市内公交路线完成');
  }

  // 绘制跨城路线 - 处理嵌套结构
  void _drawMassTransitRoute(BMFMassTransitRouteResult result) async {
    debugPrint('开始绘制跨城路线');
    if (_mapController == null || !mounted) return;
    
    // 获取路线方案
    final routes = result.routes;
    if (routes == null || routes.isEmpty) {
      debugPrint('绘制跨城路线失败: 没有可用的路线方案');
      return;
    }
    
    debugPrint('使用第一种方案, 总共${routes.length}种方案');
    
    try {
      // 使用第一种方案
      final route = routes.first;
      
      // 收集所有路线点用于简单连线
      List<BMFCoordinate> allPoints = [];
      
      debugPrint('大段路线数量: ${route.steps?.length ?? 0}');
      
      // 处理每个大段路线
      for (final massTransitStep in route.steps ?? []) {
        debugPrint('子路段数量: ${massTransitStep.steps?.length ?? 0}');
        
        // 尝试收集所有可用的点
        for (final subStep in massTransitStep.steps ?? []) {
          if (subStep.points != null && subStep.points!.isNotEmpty) {
            allPoints.addAll(subStep.points!);
            debugPrint('添加子路段点: ${subStep.points!.length}个');
          }
        }
      }
      
      // 确保至少有两个点用于绘制线路
      if (allPoints.length >= 2) {
        debugPrint('使用简单动画线路绘制，共${allPoints.length}个点');
        await _addSimpleRoute(allPoints);
      } else {
        debugPrint('没有足够的点来绘制路线');
      }
    } catch (e) {
      debugPrint('绘制跨城路线出错: $e');
      
      // 如果出错，尝试获取起点和终点
      if (result.routes != null && 
          result.routes!.isNotEmpty && 
          result.routes!.first.starting?.location != null && 
          result.routes!.first.terminal?.location != null) {
        debugPrint('退回到简单起终点连线');
        await _addSimpleRoute([
          result.routes!.first.starting!.location!, 
          result.routes!.first.terminal!.location!
        ]);
      }
    }
    
    debugPrint('绘制跨城路线完成');
  }
  
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
          
          // 创建折线段
          final overlay = BMFPolyline(
            coordinates: segmentPoints,
            width: 6,
            indexs: List.generate(segmentPoints.length, (index) => index),
            colors: [colors[i], colors[(i + 1) % 4]], // 使用渐变色
            lineDashType: BMFLineDashType.LineDashTypeNone,
            lineJoinType: BMFLineJoinType.LineJoinRound,
            lineCapType: BMFLineCapType.LineCapRound,
          );
          
          bool result = await _mapController!.addPolyline(overlay);
          debugPrint('添加线段${i+1}/4: ${result ? "成功" : "失败"}');
      }
    } else {
        // 点数较少时直接创建单一折线
        final overlay = BMFPolyline(
          coordinates: points,
          width: 6,
          indexs: List.generate(points.length, (index) => index),
          colors: colors,  // 使用多色渐变
          lineDashType: BMFLineDashType.LineDashTypeNone,
          lineJoinType: BMFLineJoinType.LineJoinRound,
          lineCapType: BMFLineCapType.LineCapRound,
        );
        
        bool result = await _mapController!.addPolyline(overlay);
        debugPrint('添加普通线路: ${result ? "成功" : "失败"}');
      }
    } catch (e) {
      debugPrint('添加普通线路出错: $e');
      
      // 如果出错，尝试使用最简单的直线连接
      try {
        final simpleOverlay = BMFPolyline(
          coordinates: [points.first, points.last],
          width: 5,
          indexs: [0, 1],
          colors: [Colors.red],
          lineDashType: BMFLineDashType.LineDashTypeNone,
        );
        
        await _mapController!.addPolyline(simpleOverlay);
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
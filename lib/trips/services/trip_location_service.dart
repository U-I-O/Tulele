// lib/trips/services/trip_location_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'trip_notification_service.dart';


// 与目标场景的距离展示、和自动打卡签到


class TripLocationService {
  // 单例模式
  static final TripLocationService _instance = TripLocationService._internal();
  factory TripLocationService() => _instance;
  TripLocationService._internal();

  // 添加用于存储当前位置信息的属性
  Position? _currentPosition;
  String _currentAddress = "未获取地址";
  // 位置更新回调
  Function(double latitude, double longitude, String address)? onLocationUpdate;
  
  
  // 通知服务
  final TripNotificationService _notificationService = TripNotificationService();
  
  // 位置流订阅
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  
  // 开始位置跟踪
  Future<void> startLocationTracking() async {
    if (_isTracking) return;
    
    // 检查位置权限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('TripLocationService: 位置权限被拒绝');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('TripLocationService: 位置权限被永久拒绝');
      return;
    }
    
    // 开始监听位置变化
 // 开始监听位置变化
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // 移动100米才更新
      ),
    ).listen((Position position) {
      _currentPosition = position;
      
      // 输出位置信息到控制台
      debugPrint('当前位置: 纬度=${position.latitude}, 经度=${position.longitude}');
      
      // 获取地址
      _getAddressFromLatLng(position);
      
      // 通知服务处理位置更新
      _notificationService.processLocationUpdate(
        position.latitude, 
        position.longitude
      );
      
      // 调用回调（如果有）
      if (onLocationUpdate != null) {
        onLocationUpdate!(position.latitude, position.longitude, _currentAddress);
      }
    });
    
    _isTracking = true;
  }
  
  // 停止位置跟踪
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

   // 添加地理编码方法
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.street}, ${place.subLocality}, '
            '${place.locality}, ${place.postalCode}, ${place.country}';
        
        debugPrint('当前地址: $_currentAddress');
      }
    } catch (e) {
      debugPrint('获取地址失败: $e');
    }
  }
  
  // 获取当前位置方法
  Future<Position?> getCurrentPosition() async {
    if (_currentPosition != null) return _currentPosition;
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      debugPrint('获取当前位置失败: $e');
      return null;
    }
  }
  
  // 获取当前地址
  String get currentAddress => _currentAddress;
  
  // 检查是否在跟踪
  bool get isTracking => _isTracking;
}
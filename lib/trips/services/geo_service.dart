 // 在lib/trips/services/geo_service.dart中
import 'package:flutter/foundation.dart';
import 'package:flutter_baidu_mapapi_search/flutter_baidu_mapapi_search.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'dart:async';

class GeoService {
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  final BMFGeocodeSearch _geoCodeSearch = BMFGeocodeSearch();
    
  Future<Map<String, double>?> getCoordinatesFromName(String locationName, {String? city}) async {
    debugPrint('开始地理编码: 地点=$locationName, 城市=${city ?? "不指定"}');
    
    final completer = Completer<Map<String, double>?>();
    
    // 设置回调
    _geoCodeSearch.onGetGeoCodeSearchResult(callback: (result, errorCode) {
      if (errorCode == BMFSearchErrorCode.NO_ERROR && 
          result != null && 
          result.location != null) {
        final coordinates = {
          'latitude': result.location!.latitude,
          'longitude': result.location!.longitude,
        };
        debugPrint('地理编码成功: $locationName => (${coordinates['latitude']}, ${coordinates['longitude']})');
        completer.complete(coordinates);
      } else {
        debugPrint('地理编码失败: 错误码=$errorCode, 地点=$locationName');
        completer.complete(null);
      }
    });
    
    // 创建地理编码选项
    final BMFGeoCodeSearchOption option = BMFGeoCodeSearchOption(
      address: locationName,
      city: city,
    );
    
    // 发起搜索
    bool searchResult = await _geoCodeSearch.geoCodeSearch(option);
    debugPrint('发起地理编码搜索: ${searchResult ? "成功" : "失败"}');
    
    // 如果发起搜索失败，直接返回null
    if (!searchResult) {
      completer.complete(null);
    }
    
    return completer.future;
  }
}
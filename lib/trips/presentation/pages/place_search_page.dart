// lib/trips/presentation/pages/place_search_page.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:flutter_baidu_mapapi_search/flutter_baidu_mapapi_search.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';

class PoiInfo {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  PoiInfo({required this.name, required this.address, this.latitude, this.longitude});
}

class PlaceSearchPage extends StatefulWidget {
  final String? city;
  const PlaceSearchPage({super.key, this.city});

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PoiInfo> _searchResults = [];
  bool _isSearching = false;
  
  // 根据官方文档，创建一个搜索实例并作为成员变量持有
  final BMFPoiCitySearch _poiSearch = BMFPoiCitySearch();

  @override
  void initState() {
    super.initState();
    
    // 在initState中为 _poiSearch 实例设置回调监听
    _poiSearch.onGetPoiCitySearchResult(
      callback: (BMFPoiSearchResult result, BMFSearchErrorCode errorCode) {
        List<PoiInfo> newResults = [];
        if (errorCode == BMFSearchErrorCode.NO_ERROR && result.poiInfoList != null) {
          newResults = result.poiInfoList!.map((poi) {
            return PoiInfo(
              name: poi.name ?? '未知地点',
              address: poi.address ?? '地址不详',
              latitude: poi.pt?.latitude,
              longitude: poi.pt?.longitude,
            );
          }).toList();
        }
        
        if (mounted) {
          setState(() {
            _searchResults = newResults;
            _isSearching = false;
          });
        }
      }
    );
  }

  Future<void> _searchPlace(String keyword) async {
    if (keyword.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    if (mounted) setState(() => _isSearching = true);

    // *** 核心修正：不再创建新的搜索实例 ***
    // 移除: BMFPoiSearch poiSearch = BMFPoiSearch();

    BMFPoiCitySearchOption option = BMFPoiCitySearchOption(
      city: widget.city ?? '全国',
      keyword: keyword,
    );

    // *** 核心修正：使用已持有并设置了监听的 _poiSearch 实例来发起搜索 ***
    await _poiSearch.poiCitySearch(option);
  }

  @override
  void dispose() {
    // 可以在此注销监听，但当前插件版本似乎不需要手动操作
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI 部分无需修改
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '在“${widget.city ?? '全国'}”搜索地点...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchPlace('');
                    },
                  )
                : null,
          ),
          onChanged: _searchPlace,
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemBuilder: (context, index) {
                if (index != _searchResults.length - 1) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text(_searchResults[index].name),
                        subtitle: Text(_searchResults[index].address),
                        onTap: () {
                          Navigator.pop(context, _searchResults[index]);
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }
                return ListTile(
                  title: Text(_searchResults[index].name),
                  subtitle: Text(_searchResults[index].address),
                  onTap: () {
                    Navigator.pop(context, _searchResults[index]);
                  },
                );
              },
              itemCount: _searchResults.length,
            ),
    );
  }
}
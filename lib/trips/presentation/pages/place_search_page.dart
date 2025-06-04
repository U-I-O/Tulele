// lib/trips/presentation/pages/place_search_page.dart
import 'package:flutter/material.dart';
// 假设你使用 amap_flutter_search 插件
// import 'package:amap_flutter_search/amap_flutter_search.dart'; 

// 模拟高德POI搜索结果项
class PoiInfo {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  PoiInfo({required this.name, required this.address, this.latitude, this.longitude});
}

class PlaceSearchPage extends StatefulWidget {
  const PlaceSearchPage({super.key});

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PoiInfo> _searchResults = [];
  bool _isSearching = false;
  String _yourAmapKey = "YOUR_AMAP_KEY"; // <--- 在这里或通过配置传入你的高德Key

  @override
  void initState() {
    super.initState();
    // 初始化高德搜索SDK (如果插件需要)
    // AMapFlutterSearch.setApiKey(iosKey: _yourAmapKey, androidKey: _yourAmapKey); // 示例
  }

  Future<void> _searchPlace(String keyword) async {
    if (keyword.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);

    // --- 实际的高德POI搜索逻辑 ---
    // 这里是模拟，你需要用 amap_flutter_search 插件的真实API调用
    // 例如:
    /*
    try {
      final poiResult = await AMapFlutterSearch.searchKeyword(
        keyword, 
        city: "北京" // 可以让用户选择城市或自动定位
      );
      List<PoiInfo> results = poiResult.map((poi) => PoiInfo(
        name: poi.title ?? '未知地点',
        address: poi.address ?? '',
        latitude: poi.latLonPoint?.latitude,
        longitude: poi.latLonPoint?.longitude,
      )).toList();
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print("Error searching place: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("搜索地点失败: $e")));
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
    */

    // 模拟API调用
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _searchResults = [
        PoiInfo(name: "$keyword - 颐和园", address: "北京市海淀区新建宫门路19号", latitude: 40.0000, longitude: 116.2755),
        PoiInfo(name: "$keyword - 故宫博物院", address: "北京市东城区景山前街4号", latitude: 39.9163, longitude: 116.3972),
        PoiInfo(name: "$keyword - 天安门广场", address: "北京市东城区长安街", latitude: 39.9087, longitude: 116.3975),
      ];
      _isSearching = false;
    });
    // --- 模拟结束 ---
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索地点名称...',
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
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final poi = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(poi.name.substring(0,1))), // 如图3样式
                  title: Text(poi.name),
                  subtitle: Text(poi.address),
                  trailing: TextButton( // “添加”按钮
                    child: const Text("添加"),
                    onPressed: () {
                      Navigator.pop(context, poi); // 返回选中的 PoiInfo 对象
                    },
                  ),
                  onTap: () {
                     Navigator.pop(context, poi);
                  }
                );
              },
            ),
    );
  }
}
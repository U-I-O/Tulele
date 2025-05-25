// lib/itinerary_editor_page.dart (新建)
import 'package:flutter/material.dart';

// 模拟票务信息模型
class TicketInfo {
  final String type; // '交通', '住宿', '门票', '餐饮'
  final String name;
  final String details; // 日期，座位号，房型，份数等
  final String status; // '已预订', '待使用', '已使用'
  final IconData icon;

  TicketInfo({required this.type, required this.name, required this.details, required this.status, required this.icon});
}

class ItineraryEditorPage extends StatefulWidget {
  final Map<String, dynamic> tripData; // 从上一页接收行程数据

  const ItineraryEditorPage({super.key, required this.tripData});

  @override
  State<ItineraryEditorPage> createState() => _ItineraryEditorPageState();
}

class _ItineraryEditorPageState extends State<ItineraryEditorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> _days;

  // 模拟票夹数据，实际应与行程关联
  final List<TicketInfo> _sampleTickets = [
    TicketInfo(type: '门票', name: '天涯海角风景区门票', details: '2025年6月2日, 成人票x2, 儿童票x1', status: '待使用', icon: Icons.local_activity_outlined),
    TicketInfo(type: '住宿', name: '三亚海棠湾喜来登度假酒店', details: '2025/06/01-06/05, 海景亲子房', status: '已预订', icon: Icons.hotel_outlined),
    TicketInfo(type: '交通', name: '航班 MU5428', details: '上海 -> 三亚, 09:00起飞', status: '已预订', icon: Icons.flight_outlined),
  ];


  @override
  void initState() {
    super.initState();
    _days = List<Map<String, dynamic>>.from(widget.tripData['days'] ?? []);
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateForTab(DateTime? date) {
    if (date == null) return '日期未知';
    // 简单返回 月/日
    return '${date.month}/${date.day}';
  }

  String _formatDateForTitle(DateTime? date) {
    if (date == null) return '日期未知';
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    // 返回 年月日 星期
    return '${date.year}年${date.month}月${date.day}日, 星期${weekdays[date.weekday -1]}';
  }


  @override
  Widget build(BuildContext context) {
    String tripName = widget.tripData['name'] ?? '我的行程';
    DateTime? startDate = widget.tripData['startDate'];
    DateTime? endDate = widget.tripData['endDate'];
    String dateRange = '日期未定';
    int totalDays = _days.length;

    if (startDate != null && endDate != null) {
      dateRange = "${startDate.year}/${startDate.month}/${startDate.day} - ${endDate.year}/${endDate.month}/${endDate.day} (${endDate.difference(startDate).inDays + 1}天${endDate.difference(startDate).inDays}晚)";
    }


    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(tripName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (startDate != null && endDate != null)
              Text(
                dateRange,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.normal),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: '保存行程',
            onPressed: () {
              // 模拟保存
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('行程已保存 (模拟)')),
              );
              // 实际应用中，这里会调用API保存数据
              // 可以弹出一个确认对话框或导航到"行程已保存"页面
              _showSavedConfirmationDialog(context, tripName);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3.0,
          tabs: _days.map((day) {
            DateTime? dayDate = day['date'] is String ? DateTime.tryParse(day['date']) : day['date'] as DateTime?;
            return Tab(text: 'Day ${day['dayNumber']} (${_formatDateForTab(dayDate)})');
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.map((dayData) {
          List<Map<String, dynamic>> activities = List<Map<String, dynamic>>.from(dayData['activities'] ?? []);
          DateTime? dayDate = dayData['date'] is String ? DateTime.tryParse(dayData['date']) : dayData['date'] as DateTime?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _formatDateForTitle(dayDate), // 使用格式化的日期和星期
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                ),
                if (activities.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("本日暂无活动安排，点击下方按钮添加吧！", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  )),
                ...activities.map((activity) {
                  return _buildActivityCard(activity);
                }).toList(),
                const SizedBox(height: 20),
                _buildSectionTabs(), // 笔记、地图、票夹的Tabs
                const SizedBox(height: 80), // 为悬浮按钮留出空间
              ],
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 实现添加新活动到当前选中日期的逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('添加新活动功能待实现')),
          );
        },
        label: const Text('添加活动'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity['time'] ?? '时间未定',
              style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            Text(
              activity['description'] ?? '活动描述',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (activity['details'] != null && (activity['details'] as String).isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Text(
                activity['details'],
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('编辑'),
                  onPressed: () { /* TODO: 编辑活动逻辑 */ },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                  label: Text('删除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onPressed: () { /* TODO: 删除活动逻辑 */ },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 模拟 笔记、地图、票夹 的切换
  int _selectedSubTabIndex = 0; // 0: 笔记, 1: 地图, 2: 票夹

  Widget _buildSectionTabs() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSubTabButton('笔记', Icons.note_alt_outlined, 0),
            _buildSubTabButton('地图', Icons.map_outlined, 1),
            _buildSubTabButton('票夹', Icons.confirmation_number_outlined, 2),
          ],
        ),
        const SizedBox(height: 16),
        _buildSubTabContent(),
      ],
    );
  }

  Widget _buildSubTabButton(String title, IconData icon, int index) {
    bool isSelected = _selectedSubTabIndex == index;
    return TextButton.icon(
      icon: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700]),
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal:16, vertical: 8),
          backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
      ),
      onPressed: () {
        setState(() {
          _selectedSubTabIndex = index;
        });
      },
    );
  }

  Widget _buildSubTabContent() {
    switch (_selectedSubTabIndex) {
      case 0: // 笔记
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!)
          ),
          child: TextField(
            maxLines: 5,
            decoration: InputDecoration.collapsed(
                hintText: '记录这一天的旅行笔记...',
                hintStyle: TextStyle(color: Colors.grey[500])
            ),
          ),
        );
      case 1: // 地图
        return Container(
          height: 200,
          decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!)
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text('地图预览区 (待实现)', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        );
      case 2: // 票夹
        return _sampleTickets.isEmpty
            ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!)
            ),
            child: Center(child: Text('当前行程暂无票务信息', style: TextStyle(color: Colors.grey[600])))
        )
            : Column(
          children: _sampleTickets.map((ticket) => Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom:8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(ticket.icon, color: Theme.of(context).primaryColor, size: 20),
              ),
              title: Text(ticket.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("${ticket.details}\n状态: ${ticket.status}", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              isThreeLine: true,
              trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
              onTap: () { /* TODO: 查看票务详情 */},
            ),
          )).toList(),
        );
      default:
        return Container();
    }
  }

  void _showSavedConfirmationDialog(BuildContext context, String tripName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(width: 12),
              const Text('行程已保存'),
            ],
          ),
          content: Text('您的 "$tripName" 行程已成功创建并保存。'),
          actions: <Widget>[
            TextButton(
              child: const Text('查看行程'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Potentially do nothing if already on editor page, or navigate to a trip overview page
              },
            ),
            ElevatedButton(
              child: const Text('返回首页'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst); // Pop until MyTripsPage
              },
            ),
          ],
        );
      },
    );
  }

}
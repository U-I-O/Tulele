// lib/notification_center_page.dart (新建)
import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final List<NotificationItem> _notifications = [
    NotificationItem(title: '方案审核通过', subtitle: '您的方案“三亚海岛度假 | 亲子游玩5日行程”已通过审核并上架至方案市场，定价为¥39.90。', time: '2025-05-17 09:35', icon: Icons.check_circle_outline, iconColor: Colors.green.shade600),
    NotificationItem(title: '创作激励到账', subtitle: '您的方案“丽江古城休闲游”本月为您贡献了¥158.60的创作激励。', time: '2025-05-10 15:22', icon: Icons.card_giftcard_outlined, iconColor: Colors.orange.shade700, isRead: true),
    NotificationItem(title: '方案被收藏', subtitle: '您的方案“北京文化之旅”被25名用户收藏。', time: '2025-05-05 18:43', icon: Icons.favorite_outline, iconColor: Colors.pink.shade400),
    NotificationItem(title: '流量提升', subtitle: '恭喜!您的方案“北京文化之旅”获得了首页推荐，预计带来更多曝光。', time: '2025-05-03 10:00', icon: Icons.trending_up_outlined, iconColor: Colors.blue.shade600, isRead: true),
    NotificationItem(title: '系统通知', subtitle: '途乐乐V1.2版本已更新，快去体验新功能吧！', time: '2025-04-28 12:00', icon: Icons.system_update_alt_outlined, iconColor: Colors.purple.shade400),
  ];

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('所有通知已标记为已读')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text('全部已读', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无通知', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => Divider(height: 1, indent: 70, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: notification.iconColor.withOpacity(0.15),
              child: Icon(notification.icon, color: notification.iconColor, size: 24),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                color: notification.isRead ? Colors.grey[700] : Theme.of(context).colorScheme.onBackground,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                notification.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(notification.time.split(' ')[1], style: TextStyle(fontSize: 12, color: Colors.grey[500])), // 只显示时间
                if (!notification.isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  )
              ],
            ),
            onTap: () {
              _markAsRead(index);
              // TODO: 点击通知跳转到对应详情页或执行操作
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(notification.title),
                    content: Text(notification.subtitle),
                    actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("关闭"))],
                  )
              );
            },
          );
        },
      ),
    );
  }
}
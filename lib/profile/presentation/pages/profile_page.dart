// lib/profile_page.dart (新建)
import 'package:flutter/material.dart';
import 'notification_center_page.dart';
import '../creator/creator_center_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildListTile(BuildContext context, String title, IconData icon, {VoidCallback? onTap, String? trailingText}) {
    return Card( // 将ListTile包裹在Card中以应用主题样式
      elevation: 1, // 可以调整或移除，因为CardTheme已有默认
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onBackground)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) Text(trailingText, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title 功能待开发')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            tooltip: '通知中心',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationCenterPage()));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // 用户信息区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Icon(Icons.person, size: 35, color: Theme.of(context).primaryColor),
                    // backgroundImage: NetworkImage('用户头像URL'), // 实际应用中替换
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '张三', // 模拟用户名
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '旅行爱好者', // 模拟用户标签
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.grey[500]),
                    onPressed: (){ /* TODO: 编辑个人资料 */},
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, '我的服务'),
          _buildListTile(context, '我的订单', Icons.list_alt_outlined),
          _buildListTile(context, '我的票夹', Icons.confirmation_number_outlined),
          _buildListTile(context, '我的收藏', Icons.favorite_border_outlined),

          const SizedBox(height: 24),
          _buildSectionTitle(context, '创作与分享'),
          _buildListTile(
              context,
              '创作中心',
              Icons.palette_outlined, // 或 Icons.create_outlined
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatorCenterPage()));
              }
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(context, '其他'),
          _buildListTile(context, '设置', Icons.settings_outlined),
          _buildListTile(context, '关于途乐乐', Icons.info_outline),
          _buildListTile(context, '退出登录', Icons.logout_outlined, onTap: (){
            // TODO: 实现退出登录逻辑
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('退出登录 (模拟)')),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
// lib/profile_page.dart (按计划书功能 + 参考图排版风格修改)
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'notification_center_page.dart';
import '../../../creator/presentation/pages/creator_center_page.dart';

import '../../../creator/presentation/pages/publish_plan_page.dart';      // 导入发布方案页面
import '../../../trips/presentation/pages/my_published_plans_page.dart'; // 导入我的已发布方案页面
// 占位页面，实际项目中需要创建
// import 'my_orders_page.dart';
// import 'my_tickets_global_page.dart';
// import 'my_favorites_page.dart';
// import 'account_security_page.dart';
// import 'about_app_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _userName = "途乐乐用户"; // 模拟用户名
  final String _userHandle = "@tulele_explorer"; // 模拟用户Handle
  final String _userAvatarUrl = 'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60'; // 示例头像URL

  @override
  void initState() {
    super.initState();
    // 根据计划书的功能，我们将Tab调整为更符合其内容的分组
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color scaffoldBackgroundColor = Colors.white; // 直接使用主题中的背景色

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 260.0, // 调整展开高度
                floating: false,
                pinned: true,
                elevation: innerBoxIsScrolled ? 2.0 : 0.0, // 滚动时显示阴影
                backgroundColor: Colors.white, // AppBar背景统一为白色
                surfaceTintColor: Colors.transparent, // 避免M3滚动变色
                centerTitle: true, // AppBar标题是否居中（收起时）
                iconTheme: IconThemeData(color: onSurfaceColor),
                actions: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_outlined, color: onSurfaceColor.withOpacity(0.8)),
                    tooltip: '通知中心',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationCenterPage()));
                    },
                  ),
                  // 可以添加一个设置图标，如果“设置”不在主Tab中
                  // IconButton(icon: Icon(Icons.settings_outlined, color: onSurfaceColor.withOpacity(0.8)), onPressed: () {})
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin, //确保TabBar固定
                  centerTitle: true, // Header中的标题也居中
                  titlePadding: const EdgeInsets.only(bottom: 50, left: 16, right: 16), // 为TabBar留出空间
                  title: innerBoxIsScrolled ? Text( // 仅在收起时显示AppBar标题
                    _userName,
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ) : null,
                  background: Container(
                    color: scaffoldBackgroundColor, // 背景色与页面一致
                    padding: const EdgeInsets.only(top: kToolbarHeight + 10), // 适配AppBar高度
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          backgroundImage: NetworkImage(_userAvatarUrl),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          _userName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurfaceColor),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _userHandle, // "旅行爱好者" 或其他描述
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 55), // 为TabBar留出足够空间
                      ],
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey[500],
                  indicatorColor: primaryColor,
                  indicatorWeight: 2.5,
                  tabs: const [
                    Tab(text: '我的服务'), // Tab 1: 对应订单、票夹、收藏
                    Tab(text: '创作中心'), // Tab 2: 对应创作相关
                    Tab(text: '通用设置'), // Tab 3: 对应设置、关于等
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildServicesTab(context),
              _buildCreatorHubTab(context),
              _buildGeneralSettingsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  // Tab 1: 我的服务 (订单、票夹、收藏)
  Widget _buildServicesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildServiceItemCard(
            context,
            icon: Icons.list_alt_rounded,
            title: '我的订单',
            subtitle: '查看您的所有旅行订单',
            color: Colors.orange.shade300,
            onTap: () { /* TODO: Navigate to MyOrdersPage */ }
        ),
        _buildServiceItemCard(
            context,
            icon: Icons.confirmation_number_rounded,
            title: '我的票夹',
            subtitle: '管理您的交通、门票等凭证',
            color: Colors.green.shade300,
            onTap: () { /* TODO: Navigate to MyGlobalTicketsPage */ }
        ),
        _buildServiceItemCard(
            context,
            icon: Icons.favorite_rounded,
            title: '我的收藏',
            subtitle: '查看您收藏的行程方案与地点',
            color: Colors.pink.shade200,
            onTap: () { /* TODO: Navigate to MyFavoritesPage */ }
        ),
      ],
    );
  }

  // Tab 2: 创作中心
  Widget _buildCreatorHubTab(BuildContext context) {
    return SingleChildScrollView( // 使用SingleChildScrollView以防内容过多
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 让按钮撑满宽度
        children: [
          // 一个醒目的进入创作中心的卡片/按钮
          _buildGlassNavigationCard(
              context,
              title: "进入创作中心",
              subtitle: "管理您的方案、查看收益、参与创作激励计划。",
              icon: Icons.palette_outlined,
              color: Theme.of(context).primaryColor,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatorCenterPage()));
              }
          ),
          const SizedBox(height: 20),
          Text("快捷操作", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('发布新行程方案'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublishPlanPage()));
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('查看我发布的方案'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPublishedPlansPage()));
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Tab 3: 通用设置
  Widget _buildGeneralSettingsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0), // 调整内边距
      children: [
        _buildSettingsItem(context, '账号与安全', Icons.shield_outlined, onTap: () { /* TODO */ }),
        _buildSettingsItem(context, '通知偏好', Icons.notifications_active_outlined, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationCenterPage()));
        }),
        _buildSettingsItem(context, '通用设置', Icons.tune_outlined, onTap: () { /* TODO */ }),
        const Divider(height: 24, thickness: 0.5),
        _buildSettingsItem(context, '关于途乐乐', Icons.info_outline, onTap: () { /* TODO */ }),
        _buildSettingsItem(context, '隐私政策', Icons.privacy_tip_outlined, onTap: () { /* TODO */ }),
        _buildSettingsItem(context, '帮助与反馈', Icons.help_outline_outlined, onTap: () { /* TODO */ }),
        const Divider(height: 24, thickness: 0.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('退出登录 (模拟)')),
              );
            },
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                foregroundColor: Colors.red.shade700,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text('退出登录', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        )
      ],
    );
  }

  // 服务项卡片 (可考虑磨砂玻璃效果)
  Widget _buildServiceItemCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color, // 用于图标背景或卡片强调色
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0.5, // 轻微阴影
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white, // 卡片背景白色
      child: InkWell( // 使用InkWell提供点击效果
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis,),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // 磨砂玻璃导航卡片 (用于创作中心入口等)
  Widget _buildGlassNavigationCard(BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias, // 确保内部效果在圆角内
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            // 可以用渐变色或者从主题色派生
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
          ),
          child: ClipRRect( // 内部再加一层ClipRRect确保BackdropFilter也在圆角内
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1), // 非常淡的覆盖色
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 36, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ]
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 设置项列表Tile
  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 24),
      title: Text(title, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[350]),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title 功能待开发')),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    );
  }
}
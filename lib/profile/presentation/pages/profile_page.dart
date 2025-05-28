// lib/profile_page.dart (按计划书功能 + 参考图排版风格修改)
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'notification_center_page.dart';
import '../../../creator/presentation/pages/creator_center_page.dart';
import '../../../core/services/user_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'edit_profile_page.dart';

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
  final String _defaultUserName = "途乐乐用户"; // 默认用户名
  final String _defaultUserHandle = "@tulele_explorer"; // 默认用户Handle
  final String _defaultAvatarUrl = 'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60'; // 示例头像URL
  
  final _userService = UserService();
  
  // 获取当前登录用户，如果未登录返回null
  get _currentUser => _userService.currentUser;
  
  // 判断用户是否已登录
  bool get _isLoggedIn => _currentUser != null;
  
  // 获取用户名，如果未登录则返回默认名称
  String get _userName => _isLoggedIn ? _currentUser!.username : _defaultUserName;
  
  // 获取用户标识，如果未登录则返回默认标识
  String get _userHandle => _isLoggedIn ? '@${_currentUser!.email.split('@')[0]}' : _defaultUserHandle;
  
  // 获取用户头像，如果未登录或用户没有设置头像则返回默认头像
  String get _userAvatarUrl => _isLoggedIn && _currentUser!.avatarUrl != null ? _currentUser!.avatarUrl! : _defaultAvatarUrl;

  @override
  void initState() {
    super.initState();
    // 根据计划书的功能，我们将Tab调整为更符合其内容的分组
    _tabController = TabController(length: 3, vsync: this);
    
    // 监听用户状态变化
    _userService.userStream.listen((user) {
      if (mounted) {
        setState(() {
          // 用户状态变化，更新UI
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // 处理登录/登出
  Future<void> _handleLoginOrLogout() async {
    if (_isLoggedIn) {
      // 已登录，执行登出
      await _userService.logout();
      if (mounted) {
        setState(() {});
      }
    } else {
      // 未登录，导航到登录页面
      final loginResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
      
      // 登录成功，刷新页面
      if (loginResult == true && mounted) {
        setState(() {});
      }
    }
  }

  // 打开个人资料编辑页面
  Future<void> _navigateToEditProfile() async {
    if (!_isLoggedIn) {
      // 未登录，弹出登录页面
      await _handleLoginOrLogout();
      return;
    }
    
    // 已登录，导航到编辑资料页面
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );
    
    // 如果资料更新成功，刷新页面
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color scaffoldBackgroundColor = Colors.grey[50]!; // 更浅的背景

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
                  // 添加登录/登出按钮
                  IconButton(
                    icon: Icon(
                      _isLoggedIn ? Icons.logout : Icons.login,
                      color: onSurfaceColor.withOpacity(0.8),
                    ),
                    tooltip: _isLoggedIn ? '退出登录' : '登录',
                    onPressed: _handleLoginOrLogout,
                  ),
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
                        // 包装头像为可点击的组件，点击后进入编辑资料页面
                        GestureDetector(
                          onTap: _navigateToEditProfile,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          backgroundImage: NetworkImage(_userAvatarUrl),
                              ),
                              if (_isLoggedIn)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        // 用户名也可点击进入编辑资料页面
                        GestureDetector(
                          onTap: _navigateToEditProfile,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                        Text(
                          _userName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurfaceColor),
                              ),
                              if (_isLoggedIn) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ],
                          ),
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
    // 如果未登录，显示登录提示
    if (!_isLoggedIn) {
      return _buildLoginPrompt(context, '登录后查看您的旅行服务');
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        _buildListItem(
            context,
            icon: Icons.list_alt_rounded,
            title: '我的订单',
            color: Colors.orange.shade300,
            onTap: () { /* TODO: Navigate to MyOrdersPage */ }
        ),
        _buildListItem(
            context,
            icon: Icons.confirmation_number_rounded,
            title: '我的票夹',
            color: Colors.green.shade300,
            onTap: () { /* TODO: Navigate to MyGlobalTicketsPage */ }
        ),
        _buildListItem(
            context,
            icon: Icons.favorite_rounded,
            title: '我的收藏',
            color: Colors.pink.shade200,
            onTap: () { /* TODO: Navigate to MyFavoritesPage */ }
        ),
      ],
    );
  }

  // Tab 2: 创作中心
  Widget _buildCreatorHubTab(BuildContext context) {
    // 如果未登录，显示登录提示
    if (!_isLoggedIn) {
      return _buildLoginPrompt(context, '登录后使用创作中心功能');
    }
    
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
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('查看我的已发布方案'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPublishedPlansPage()));
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 3: 通用设置
  Widget _buildGeneralSettingsTab(BuildContext context) {
    final List<Widget> items = [];
    
    if (_isLoggedIn) {
      items.add(_buildListItem(
        context,
        icon: Icons.account_circle_outlined,
        title: '账号与安全',
        color: Colors.blue.shade300,
        onTap: () => _navigateToEditProfile(),
      ));
    }
    
    items.addAll([
      _buildListItem(
        context,
        icon: Icons.language_outlined,
        title: '语言设置',
        color: Colors.teal.shade300,
        onTap: () { /* TODO: Navigate to LanguageSettingsPage */ },
      ),
      _buildListItem(
        context,
        icon: Icons.notifications_outlined,
        title: '通知设置',
        color: Colors.amber.shade300,
        onTap: () { /* TODO: Navigate to NotificationSettingsPage */ },
      ),
      _buildListItem(
        context,
        icon: Icons.help_outline,
        title: '帮助与反馈',
        color: Colors.indigo.shade300,
        onTap: () { /* TODO: Navigate to HelpAndFeedbackPage */ },
      ),
      _buildListItem(
        context,
        icon: Icons.info_outline,
        title: '关于途乐乐',
        color: Colors.cyan.shade300,
        onTap: () { /* TODO: Navigate to AboutAppPage */ },
      ),
    ]);
    
    if (_isLoggedIn) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onPressed: _handleLoginOrLogout,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: items,
    );
  }

  // 未登录时显示登录提示
  Widget _buildLoginPrompt(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _handleLoginOrLogout,
              child: const Text('立即登录'),
            ),
          ),
        ],
      ),
    );
  }

  // 简约列表项
  Widget _buildListItem(BuildContext context, {
    required IconData icon, 
    required String title, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w500
          ),
        ),
        trailing: Icon(
          Icons.chevron_right, 
          color: Colors.grey[400], 
          size: 22
        ),
        onTap: () {
          // 添加点击的涟漪动画效果
          _animateListItemTap(context).then((_) => onTap());
        },
      ),
    );
  }
  
  // 点击时的涟漪动画效果
  Future<void> _animateListItemTap(BuildContext context) async {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    await controller.forward();
    await controller.reverse();
    controller.dispose();
  }

  Widget _buildGlassNavigationCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '立即进入',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
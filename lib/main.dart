// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui'; // For BackdropFilter

// 确保这些页面的路径和名称与您的项目结构一致
import 'package:tulele/trips/presentation/pages/my_trips_page.dart';
import 'package:tulele/profile/presentation/pages/profile_page.dart';
import 'package:tulele/trips/presentation/pages/create_trip_options_page.dart'; // 我们仍需此页的导航目标
import 'package:tulele/ai/presentation/pages/ai_planner_page.dart';
import 'package:tulele/trips/presentation/pages/create_trip_details_page.dart';


void main() {
  runApp(const MyAppEntry());
}

class MyAppEntry extends StatelessWidget {
  const MyAppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '途乐乐',
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF), // 主题蓝，可以根据参考图1调整为更中性的颜色
        hintColor: const Color(0xFFFF9500),   // 辅助橙
        scaffoldBackgroundColor: Colors.white, // 修改点：全局背景色设为纯白
        fontFamily: 'PingFangSC', // 或者您选择的其他字体
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87, // AppBar 文字和图标颜色改为深灰/黑色
          elevation: 0, // 极简风格，AppBar 通常无阴影或非常轻微
          iconTheme: IconThemeData(color: Colors.grey[700]),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87, // AppBar 标题颜色
            fontFamily: 'PingFangSC',
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5, // 卡片阴影可以更柔和
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87, // 主要按钮背景改为深色，以突出
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // 增加按钮padding
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'PingFangSC'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            elevation: 0.5,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700], fontFamily: 'PingFangSC'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            foregroundColor: Colors.grey[700],
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black87, // TextButton 颜色也改为黑色系
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'PingFangSC'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          )
        ),
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[200]!), // 输入框边框更淡
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.black54, width: 1.5), // 聚焦时黑色
          ),
          filled: true,
          fillColor: Colors.grey[100], // 输入框背景非常浅的灰色
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        // 修改点：底部导航栏主题
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.black,       // 选中项改为黑色
          unselectedItemColor: Colors.grey[400], // 未选中项颜色更淡
          backgroundColor: Colors.white,
          elevation: 0, // 通常悬浮胶囊无阴影，或由父组件控制
          showUnselectedLabels: true, // 参考图1显示了未选中的标签
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[200], // 分割线颜色更淡
          thickness: 0.5,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF333333), // 使用深灰色作为种子色，产生中性色调
          primary: Colors.black87, // 主要交互颜色（如按钮）可以设为黑色
          secondary: const Color(0xFF007AFF), // 辅助色，可以用于次要强调
          background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
          error: Colors.redAccent,
          onError: Colors.white,
        ).copyWith(background: Colors.white),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      home: const MainPageNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPageNavigator extends StatefulWidget {
  const MainPageNavigator({super.key});

  @override
  State<MainPageNavigator> createState() => _MainPageNavigatorState();
}

class _MainPageNavigatorState extends State<MainPageNavigator> {
  int _selectedIndex = 0;
  bool _showCreateOptions = false; // 控制创建选项的显示

  static const List<Widget> _widgetOptions = <Widget>[
    MyTripsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleCreateOptionsOverlay() {
    setState(() {
      _showCreateOptions = !_showCreateOptions;
    });
  }

  void _navigateToCreateOption(BuildContext context, String type) {
    setState(() {
      _showCreateOptions = false; // 关闭选项
    });
    if (type == 'ai') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AiPlannerPage()));
    } else if (type == 'manual') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTripDetailsPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // 使用Stack来叠加页面和创建选项的蒙层
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
          // 创建选项的蒙层和按钮
          if (_showCreateOptions)
            _buildCreateOptionsOverlay(context),
        ],
      ),
      // 修改点：悬浮胶囊式 BottomAppBar
      floatingActionButton: SizedBox(
        width: 64, height: 64, // FAB尺寸
        child: FloatingActionButton(
          onPressed: _toggleCreateOptionsOverlay,
          backgroundColor: Theme.of(context).colorScheme.primary, // 使用黑色系
          foregroundColor: Colors.white,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: AnimatedRotation( // 给加号一个旋转动画
            turns: _showCreateOptions ? 0.125 : 0, // 旋转45度
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8.0, // 可以根据需要调整阴影
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0, // FAB和BottomAppBar之间的间距
        padding: const EdgeInsets.symmetric(horizontal: 12.0), // 为左右Item提供内边距
        height: 65, // 底部导航栏高度
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 将Item推到两边
          children: <Widget>[
            _buildBottomNavItem(
              context: context,
              icon: _selectedIndex == 0 ? Icons.list_alt_rounded : Icons.list_alt_outlined,
              label: '行程夹',
              isSelected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            _buildBottomNavItem(
              context: context,
              icon: _selectedIndex == 1 ? Icons.person_rounded : Icons.person_outline_rounded,
              label: '我的',
              isSelected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color color = isSelected ? Colors.black : Colors.grey.shade500;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding( // 给每个item一些内边距，使其不紧贴边缘
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: color, size: 26), // 图标稍大
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11, // 字号稍大
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 创建行程选项的悬浮层
  Widget _buildCreateOptionsOverlay(BuildContext context) {
    return Stack(
      children: [
        // 半透明背景蒙层
        GestureDetector(
          onTap: _toggleCreateOptionsOverlay, // 点击蒙层关闭选项
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Container(
              color: Colors.black.withOpacity(0.4), // 背景变暗效果
            ),
          ),
        ),
        // 选项按钮定位在FAB上方
        Positioned(
          bottom: kBottomNavigationBarHeight + 70.0, // FAB高度 + notchMargin + 一些额外间距
          left: 0,
          right: 0,
          child: Row( // 修改：从Column改为Row，实现左右布局
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // 修改：居中对齐，实现对称
            children: [
              _buildCreateOptionButton(
                context,
                icon: Icons.auto_awesome, // AI 图标
                label: 'AI智能规划', // 名称已符合要求
                onTap: () => _navigateToCreateOption(context, 'ai'),
              ),
              const SizedBox(width: 24), // 修改：从height改为width，调整间距以实现对称美观
              _buildCreateOptionButton(
                context,
                icon: Icons.edit_calendar_outlined, // 手动创建图标
                label: '自定义行程', // 修改：更改名称
                onTap: () => _navigateToCreateOption(context, 'manual'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateOptionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    // 参考图2的样式：圆形图标在左，文字在右，整体一个圆角背景
    return Material( // 使用Material来提供InkWell效果和阴影（如果需要）
      color: Colors.transparent, // 背景由内部Container控制
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0), // 圆角胶囊形状
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 让Row包裹内容
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
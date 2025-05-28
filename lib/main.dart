// lib/main.dart (重构以支持底部导航栏切换主页面)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'trips/presentation/pages/my_trips_page.dart';
import 'market/presentation/pages/solution_market_page.dart';
import 'profile/presentation/pages/profile_page.dart';
import 'core/services/user_service.dart';
import 'auth/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化用户服务
  await UserService().initialize();
  
  runApp(const MyAppEntry());
}

class MyAppEntry extends StatefulWidget {
  const MyAppEntry({super.key});

  @override
  State<MyAppEntry> createState() => _MyAppEntryState();
}

class _MyAppEntryState extends State<MyAppEntry> {
  final _userService = UserService();
  
  @override
  void initState() {
    super.initState();
    
    // 监听用户状态变化
    _userService.userStream.listen((user) {
      setState(() {
        // 用户状态发生变化，重新构建UI
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '途乐乐',
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF),
        hintColor: const Color(0xFFFF9500),
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'PingFangSC',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.grey[800]),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontFamily: 'PingFangSC',
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'PingFangSC'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[400]!),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700], fontFamily: 'PingFangSC'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            foregroundColor: Colors.grey[700],
          ),
        ),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF007AFF),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'PingFangSC'),
            )
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF007AFF).withOpacity(0.15),
          secondarySelectedColor: const Color(0xFF007AFF),
          labelStyle: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: Colors.grey[400]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: const Color(0xFF007AFF),
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 8.0,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          primary: const Color(0xFF007AFF),
          secondary: const Color(0xFFFF9500),
          background: Colors.grey[100]!,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.grey[800]!,
          onSurface: Colors.grey[800]!,
          error: Colors.redAccent,
          onError: Colors.white,
        ).copyWith(background: Colors.grey[100]),
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
      home: const MainPageNavigator(), // 主导航器
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

  static const List<Widget> _widgetOptions = <Widget>[
    MyTripsPage(), // 行程夹
    SolutionMarketPage(), // 方案市场
    ProfilePage(), // 我的
  ];

  void _onItemTapped(int index) {
    // 如果点击的是"我的"页面，需要检查是否已登录
    if (index == 2 && UserService().currentUser == null) {
      // 未登录，弹出登录页面
      _showLoginPage();
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // 显示登录页面
  Future<void> _showLoginPage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
    
    // 如果登录成功，切换到"我的"页面
    if (result == true) {
      setState(() {
        _selectedIndex = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // 使用IndexedStack保持页面状态
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel_outlined),
            activeIcon: Icon(Icons.card_travel),
            label: '行程夹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_mall_directory_outlined),
            activeIcon: Icon(Icons.store_mall_directory),
            label: '方案市场',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
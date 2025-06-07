// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui'; // For BackdropFilter
import 'dart:async';
import 'dart:io'; // For Platform check

// 确保这些页面的路径和名称与您的项目结构一致
import 'package:tulele/trips/presentation/pages/my_trips_page.dart';
import 'package:tulele/profile/presentation/pages/profile_page.dart';
import 'package:tulele/ai/presentation/pages/ai_planner_page.dart';
import 'package:tulele/trips/presentation/pages/create_trip_details_page.dart';
import 'package:tulele/trips/presentation/pages/trip_invitation_page.dart';
// 导入QR码扫描页面
import 'package:tulele/trips/presentation/pages/qr_scanner_page.dart';

//通知服务
import 'package:tulele/trips/services/trip_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tulele/core/services/notification_service.dart' as notification_service;
//测试通知页面
import 'package:tulele/profile/presentation/pages/notification_test_page.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';

// 导入依赖注入相关
import 'core/di/service_locator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 全局变量，用于存储应用启动时可能存在的通知响应
NotificationResponse? initialNotificationResponseFromLaunch;

Future<void> main() async {
  // 确保 Flutter 环境已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖注入
  await _initDependencies();

  // ******************** 新增：百度地图SDK初始化 ********************
  // 1. 设置同意隐私协议 (必须在使用任何百度地图功能前调用)
  BMFMapSDK.setAgreePrivacy(true);

  // 2. 初始化百度地图SDK
  // 注意：AK (API Key) 的主要配置位置在原生的 AndroidManifest.xml 和 Info.plist 文件中。
  BMFMapSDK.setApiKeyAndCoordType(
    'bXFtUXEAbctYkjW9fA5nAiSWUMQTid4f',
    BMF_COORD_TYPE.BD09LL // 指定坐标类型，通常使用百度自家的BD09LL
  );
  // ******************************************************************

  // ******************** 新增：百度地图SDK初始化 ********************
  // 1. 设置同意隐私协议 (必须在使用任何百度地图功能前调用)
  BMFMapSDK.setAgreePrivacy(true);

  // 2. 初始化百度地图SDK
  // 注意：AK (API Key) 的主要配置位置在原生的 AndroidManifest.xml 和 Info.plist 文件中。
  BMFMapSDK.setApiKeyAndCoordType(
    'v6hN8FYWu3doReyzysYeicU2IVQrE5ch',
    BMF_COORD_TYPE.BD09LL // 指定坐标类型，通常使用百度自家的BD09LL
  );
  // ******************************************************************

  // 调用 notification_service 中的初始化函数，并获取可能的初始通知响应
  initialNotificationResponseFromLaunch = await notification_service.initializeNotificationService();

  runApp(MyAppEntry(initialNotificationResponse: initialNotificationResponseFromLaunch));
}

/// 初始化依赖注入
Future<void> _initDependencies() async {
  // 初始化服务定位器
  ServiceLocatorSetup.init();

}

class MyAppEntry extends StatelessWidget {
  final NotificationResponse? initialNotificationResponse; // 添加参数

  const MyAppEntry({super.key, this.initialNotificationResponse}); // 修改构造函数

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '途乐乐',
      navigatorKey: navigatorKey,
      theme: appTheme,
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
      home: MainPageNavigator(initialNotificationResponse: initialNotificationResponse), // 传递参数
      // 添加路由处理
      onGenerateRoute: (settings) {
        // 处理邀请链接
        if (settings.name != null && settings.name!.startsWith('/invite/')) {
          // 提取邀请码
          final invitationCode = settings.name!.replaceFirst('/invite/', '');
          // 导入邀请处理页面
          return MaterialPageRoute(
            builder: (context) => TripInvitationPage(invitationCode: invitationCode),
          );
        }
        return null;
      },
      debugShowCheckedModeBanner: false,
      routes: {
        '/testNotificationPage': (context) => TestNotificationPage(null),
      },
    );
  }
}

///主页面容器和导航逻辑
class MainPageNavigator extends StatefulWidget {
  final NotificationResponse? initialNotificationResponse; // 添加参数

  const MainPageNavigator({super.key, this.initialNotificationResponse}); // 修改构造函数

  @override
  State<MainPageNavigator> createState() => _MainPageNavigatorState();
}

class _MainPageNavigatorState extends State<MainPageNavigator> {
  // bool _notificationsEnabled = false;//通知是否启用
  
  int _selectedIndex = 0;//当前激活的页面索引
  bool _showCreateOptions = false;//是否显示创建选项

  late List<Widget> _widgetOptions;//页面选项列表
  StreamSubscription<NotificationResponse>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      MyTripsPage(),
      ProfilePage(),
    ];

    _configureSelectNotificationSubject(); // 处理前台/恢复时的通知点击

    // 处理应用启动时通过通知传递的响应
    if (widget.initialNotificationResponse != null) {
      debugPrint('主页导航（初始状态）通过通知启动:处理初始化响应.');
      _handleNotificationResponse(widget.initialNotificationResponse!);
    }
  }

  void _configureSelectNotificationSubject() {
    _notificationSubscription = notification_service.selectNotificationStream.stream.listen((NotificationResponse response) async {
      await _handleNotificationResponse(response); // 调用共享处理方法
    });
  }

  // 通用的通知响应处理函数
  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    debugPrint('主页导航器 (_handleNotificationResponse): Payload: ${response.payload}, ActionID: ${response.actionId}, Input: ${response.input}');

    // 根据 payload 处理:
    if (response.payload != null && response.payload!.isNotEmpty) {
      if (response.payload?.startsWith('trip_') == true ||
          response.payload?.startsWith('activity_') == true) {
        // 旅行相关通知，交给TripNotificationService处理
        final tripNotificationService = TripNotificationService();
        tripNotificationService.handleNotificationResponse(response);
        return;
      }
      else if (response.payload == '项目 Z') {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('通知被点击'),
              content: Text('负载数据: ${response.payload}\n动作ID: ${response.actionId}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('好的'),
                ),
              ],
            ),
          );
      }
      else if (response.payload == '项目 X') {
          debugPrint('---------通知输入---------: payload触发: ${response.payload}');
          if (!mounted) return;
          // 这是 'showNotificationWithTextAction' 设置的 payload
          // 我们可以在这里处理用户输入，例如显示一个对话框
          if (response.input != null && response.input!.isNotEmpty) {
            debugPrint('通知输入: User input from notification: ${response.input}');
            showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: Text('收到文本输入'),
                content: Text('用户输入内容: ${response.input}\n原始Payload: ${response.payload}\n动作ID: ${response.actionId}'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('好的'),
                  ),
                ],
              ),
            );
          } 
          else {
            showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: Text('通知被点击'),
                content: Text('通知类型：文本输入 (但未检测到用户输入或用户未通过输入动作交互)\nPayload: ${response.payload}\n动作ID: ${response.actionId}'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('好的'),
                  ),
                ],
              ),
            );
          }
      }
    }
    // 根据 actionId 处理 (可以与 payload 处理逻辑结合或独立处理):
    if (response.actionId == notification_service.urlLaunchActionId) {
      debugPrint("尝试打开链接...");
      // 实际的打开链接逻辑可以在这里添加，例如使用 url_launcher 插件
    } 
    else if (response.actionId == 'text_id_1') { // 这是 showNotificationWithTextAction 中定义的 actionId
      if (response.input != null && response.input!.isNotEmpty) {
        debugPrint('MainPageNavigator: Received input via actionId \'text_id_1\': ${response.input}');
        // 为了避免重复显示对话框 (如果 payload 和 actionId 同时处理)，您可以选择一个主要的处理点
        // 既然 payload == '项目 X' 已经处理了带输入的对话框，这里可能只需要打印日志或做其他非UI操作
        // 或者如果确实需要，可以再次显示一个不同的对话框，或者更新现有对话框（如果适用）
      } else {
        debugPrint('MainPageNavigator: ActionId \'text_id_1\' was triggered, but no input received.');
      }
    }
  }



  @override
  void dispose() {
    _notificationSubscription?.cancel();
    notification_service.selectNotificationStream.close();
    super.dispose();
  }

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
      _showCreateOptions = false;
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
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
          if (_showCreateOptions)
            _buildCreateOptionsOverlay(context),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 64, height: 64,
        child: FloatingActionButton(
          onPressed: _toggleCreateOptionsOverlay,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: AnimatedRotation(
            turns: _showCreateOptions ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8.0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    final color = isSelected ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: Theme.of(context).bottomNavigationBarTheme.selectedLabelStyle?.fontSize ?? 10,
                    fontWeight: isSelected ? FontWeight.w600: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOptionsOverlay(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleCreateOptionsOverlay,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
        Positioned(
          bottom: (kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 80), // Adjust as needed
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCreateOptionItem(
                context: context,
                icon: Icons.auto_awesome_rounded,
                label: 'AI 规划行程',
                onTap: () => _navigateToCreateOption(context, 'ai'),
              ),
              const SizedBox(height: 16),
               _buildCreateOptionItem(
                context: context,
                icon: Icons.edit_calendar_rounded,
                label: '手动创建行程',
                onTap: () => _navigateToCreateOption(context, 'manual'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 扫描二维码按钮
  Widget _buildScannerButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 导航到扫码页面
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QrScannerPage()),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '扫码',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildCreateOptionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ThemeData appTheme = ThemeData(
        primaryColor: const Color(0xFF007AFF),
        hintColor: const Color(0xFFFF9500),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'PingFangSC',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey[700]),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'PingFangSC',
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
            foregroundColor: Colors.black87,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'PingFangSC'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          )
        ),
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.black54, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.white,
          elevation: 0,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[200],
          thickness: 0.5,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF333333),
          primary: Colors.black87,
          secondary: const Color(0xFF007AFF),
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
      );

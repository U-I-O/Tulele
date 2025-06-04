import 'dart:async';
import 'dart:io';
// ignore: unnecessary_import
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../widgets/padded_button.dart';
import 'plugin.dart';

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();


const MethodChannel platform =
    MethodChannel('dexterx.dev/flutter_local_notifications_example');

const String portName = 'notification_send_port';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    this.data,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
  final Map<String, dynamic>? data;
}


String? selectedNotificationPayload;


/// A notification action which triggers a url launch event
const String urlLaunchActionId = 'id_1';//启动URL

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';//导航

/// Defines a iOS/MacOS notification category for text input actions.
const String darwinNotificationCategoryText = 'textCategory';//文本输入

/// Defines a iOS/MacOS notification category for plain actions.
const String darwinNotificationCategoryPlain = 'plainCategory';//普通

/// 后台通知点击事件
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

/// 主函数,需要进行相关的设置。there is
/// setup required for each platform head project.
Future<void> main() async {
  // needed if you intend to initialize in the `main` function
  WidgetsFlutterBinding.ensureInitialized();//确保初始化

  await _configureLocalTimeZone();//配置本地时区

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');//安卓初始化设置

  final List<DarwinNotificationCategory> darwinNotificationCategories =//苹果初始化设置
      <DarwinNotificationCategory>[
    DarwinNotificationCategory(
      darwinNotificationCategoryText,//文本输入
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.text(
          'text_1',//动作1
          'Action 1',//动作1
          buttonTitle: 'Send',//按钮标题
          placeholder: 'Placeholder',//占位符
        ),
      ],
    ),
    DarwinNotificationCategory(
      darwinNotificationCategoryPlain,//普通
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('id_1', 'Action 1'),//动作1
        DarwinNotificationAction.plain(//动作2
          'id_2',
          'Action 2 (destructive)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.destructive,//破坏性
          },
        ),
        DarwinNotificationAction.plain(
          navigationActionId,
          'Action 3 (foreground)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,//前景
          },
        ),
        DarwinNotificationAction.plain(//动作4
          'id_4',
          'Action 4 (auth required)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.authenticationRequired,//认证
          },
        ),
      ],
            options: <DarwinNotificationCategoryOption>{//
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,//隐藏预览显示标题
      },
    )
  ];

  final DarwinInitializationSettings initializationSettingsDarwin =//苹果初始化设置
      DarwinInitializationSettings(
    requestAlertPermission: false,//请求警报权限
    requestBadgePermission: false,//请求徽标权限
    requestSoundPermission: false,//请求声音权限
    notificationCategories: darwinNotificationCategories,//通知类别
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,//安卓初始化设置
    iOS: initializationSettingsDarwin,//苹果初始化设置
    // macOS: initializationSettingsDarwin,//苹果初始化设置
   ///linux: initializationSettingsLinux,//linux初始化设置
    // windows: windows.initSettings,//windows初始化设置
  );

  await flutterLocalNotificationsPlugin.initialize(//插件初始化
    initializationSettings,//初始化设置
    onDidReceiveNotificationResponse: selectNotificationStream.add,//收到通知响应
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,//收到后台通知响应
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
          Platform.isLinux//linux平台需要特殊赋值--null
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();//获取通知应用启动详情

  String initialRoute = HomePage.routeName;//初始路由
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {//应用是否是通过点击一个通知启动的？”
    selectedNotificationPayload =
        notificationAppLaunchDetails!.notificationResponse?.payload;//获取通知响应负载
    initialRoute = SecondPage.routeName;//应用是通过通知启动的，那么初始路由被修改为，同理实现页面跳转？
  }

  runApp(
    MaterialApp(
      initialRoute: initialRoute,//初始路由
      routes: <String, WidgetBuilder>{
        HomePage.routeName: (_) => HomePage(notificationAppLaunchDetails),//主页
        SecondPage.routeName: (_) => SecondPage(selectedNotificationPayload)//次页
      },
    ),
  );
}

/// 配置本地时区
Future<void> _configureLocalTimeZone() async {//配置本地时区
  if (kIsWeb || Platform.isLinux) {//web和linux平台不需要特殊赋值，且不用初始化时区
    return;
  }
  tz.initializeTimeZones();//初始化时区
  if (Platform.isWindows) {//windows平台不需要特殊赋值
    return;
  }
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();//获取本地时区
  tz.setLocalLocation(tz.getLocation(timeZoneName!));//设置本地时区
}

/// 主页
class HomePage extends StatefulWidget {//有状态主页：外观或内部数据可以在其生命周期内发生变化
  const HomePage(//主页构造函数
    this.notificationAppLaunchDetails, {
    Key? key,
  }) : super(key: key);

  static const String routeName = '/';//路由名称

  final NotificationAppLaunchDetails? notificationAppLaunchDetails;//通知应用启动详情

  bool get didNotificationLaunchApp =>
      notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;//是否通知应用启动

  @override
  _HomePageState createState() => _HomePageState();//创建状态， UI 需要根据--存放在与 StatefulWidget 配对的 State 对象中的--内部数据（状态）的变化而更新
}

/// 主页状态
class _HomePageState extends State<HomePage> {//主页状态
  final TextEditingController _linuxIconPathController =
      TextEditingController();//linux图标路径控制器

  bool _notificationsEnabled = false;//通知是否启用

  /// 初始化状态
  @override
  void initState() {//初始化状态
    super.initState();
    _isAndroidPermissionGranted();//安卓权限是否已同意
    _requestPermissions();//请求权限
    _configureSelectNotificationSubject();//配置通知选择：配置和监听一个事件流
  }

  /// 安卓权限是否已同意：只检查安卓权限状态，不发起请求。
  Future<void> _isAndroidPermissionGranted() async {//安卓权限是否已同意
    if (Platform.isAndroid) {//安卓平台判断
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()//安卓插件
              ?.areNotificationsEnabled() ??
          false;//是否启用通知

      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }


  /// 请求权限：用于主动请求在不同平台上的标准通知权限。
  Future<void> _requestPermissions() async {//请求权限
    if (Platform.isIOS || Platform.isMacOS) {//ios和macos平台
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()//ios插件
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()//macos插件
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {//安卓平台
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();//安卓插件

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();//请求通知权限
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }
  
  /// 请求权限：专门用于在 iOS 和 macOS 上请求关键警报 (Critical Alerts) 的权限。
  /// 关键警报是一种特殊类型的 iOS/macOS 通知，即使用户开启了“勿扰模式”或将通知静音，它们也能够播放声音并显示在屏幕上。
  Future<void> _requestPermissionsWithCriticalAlert() async {//请求权限
    if (Platform.isIOS || Platform.isMacOS) {//ios和macos平台
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }
  }

  /// 请求通知策略访问：在即使用户开启了勿扰模式 (Do Not Disturb, DND)”权限时也能发出通知
  Future<void> _requestNotificationPolicyAccess() async {//请求通知策略访问
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();//安卓插件
    await androidImplementation?.requestNotificationPolicyAccess();//请求通知策略访问
  }

  /// 配置通知选择：配置和监听一个事件流，当用户点击通知时（或者通知上的操作按钮），会触发这个事件流。
  /// NotificationResponse? response: 这个 response 对象包含了关于用户与通知交互的详细信息，例如：
  /// response.payload: 创建通知时附加的自定义数据。
  /// response.actionId: 如果用户点击的是通知上的操作按钮，这里会包含该按钮的ID。
  /// response.input: 如果操作按钮带有文本输入，这里会包含用户输入的内容。
  /// response.data: 插件可能传递的其他数据。
  void _configureSelectNotificationSubject() {
    selectNotificationStream.stream
        .listen((NotificationResponse? response) async {//监听通知响应
      await Navigator.of(context).push(MaterialPageRoute<void>(//导航到次页
        builder: (BuildContext context) =>
            SecondPage(response?.payload, data: response?.data),//次页
      ));
    });
  }

  /// 释放资源
  @override
  void dispose() {//用于释放资源，防止内存泄漏，例如取消订阅、关闭流控制器
    selectNotificationStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(//负责描述和构建 Widget 的用户界面。
        appBar: AppBar(//页面的顶部应用栏
          title: const Text('通知插件演示页面'),
        ),
        body: SingleChildScrollView(//滚动来查看所有内容
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Column(//显示在页面上的各种 UI 元素
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child:
                          Text('Tap on a notification when it appears to trigger'
                              ' navigation'),
                    ),
                    _InfoValueString(//用于以 "标题: 值" 的格式显示信息。
                      title: '通知启动了应用?',
                      value: widget.didNotificationLaunchApp,
                    ),
                    if (widget.didNotificationLaunchApp) ...<Widget>[
                        const Text('用于启动的通知详细'),
                      _InfoValueString(
                          title: 'Notification id',
                          value: widget.notificationAppLaunchDetails!
                              .notificationResponse?.id),
                      _InfoValueString(
                          title: 'Action id',
                          value: widget.notificationAppLaunchDetails!
                              .notificationResponse?.actionId),
                      _InfoValueString(
                          title: 'Input',
                          value: widget.notificationAppLaunchDetails!
                              .notificationResponse?.input),
                      _InfoValueString(
                        title: 'Payload:',
                        value: widget.notificationAppLaunchDetails!
                            .notificationResponse?.payload,
                      ),
                    ],
                    //自定义的按钮 Widget                    
                    PaddedElevatedButton(
                      buttonText: 'Show notification with custom sound',
                      onPressed: () async {
                        await _showNotificationCustomSound();
                      },
                    ),
                    if (kIsWeb || !Platform.isLinux) ...<Widget>[
                        PaddedElevatedButton(
                          buttonText:
                              '5秒后显示通知 '
                              '基于本地时间',
                          onPressed: () async {
                            await _zonedScheduleNotification();
                          },
                        ),
                    ],
                    PaddedElevatedButton(
                      buttonText:
                          'Show silent notification from channel with sound',
                      onPressed: () async {
                        await _showNotificationSilently();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: '取消所有通知',
                      onPressed: () async {
                        await _cancelAllNotifications();
                      },
                    ),
                    // if (!Platform.isWindows) ...repeating.examples(context),
                    const Divider(),//绘制一条水平线
                    const Text(
                      'Notifications with actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with plain actions',
                      onPressed: () async {
                        await _showNotificationWithActions();
                      },
                    ),
                    if (!Platform.isLinux)
                    PaddedElevatedButton(
                      buttonText: 'Show notification with text action',
                      onPressed: () async {
                        await _showNotificationWithTextAction();
                      },
                    ),

                    if (!Platform.isLinux)
                    PaddedElevatedButton(
                      buttonText: 'Show notification with text choice',
                      onPressed: () async {
                        await _showNotificationWithTextChoice();
                      },
                    ),
                  const Divider(),
                  if (Platform.isAndroid) ...<Widget>[
                    const Text(
                      '安卓平台示例',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('notifications enabled: $_notificationsEnabled'),
                    PaddedElevatedButton(
                      buttonText:
                          'Show big picture notification, hide large icon '
                          'on expand',
                      onPressed: () async {
                        await _showBigPictureNotificationHiddenLargeIcon();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText:
                          'Show progress notification - updates every second',
                      onPressed: () async {
                        await _showProgressNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText:
                          'Request full-screen intent permission (API 34+)',
                      onPressed: () async {
                        await _requestFullScreenIntentPermission();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show full-screen notification',
                      onPressed: () async {
                        await _showFullScreenNotification();
                      },
                    ),
                  ],

                ],
              ),
            ),
          ),
        ),
      );

  
  Future<void> _showNotificationWithActions() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(//安卓通知详情
      'your channel id',//通道ID
      'your channel name',//通道名称
      channelDescription: 'your channel description',//通道描述
      importance: Importance.max,//重要性
      priority: Priority.high,//优先级
      ticker: 'ticker',//ticker，预览文本
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          urlLaunchActionId,//启动URL
          'Action 1',//动作1
          icon: DrawableResourceAndroidBitmap('food'),//图标
          contextual: true,//上下文
        ),
        AndroidNotificationAction(
          'id_2',
          'Action 2',
          titleColor: Color.fromARGB(255, 255, 0, 0),
          icon: DrawableResourceAndroidBitmap('secondary_icon'),
        ),
        AndroidNotificationAction(
          navigationActionId,
          'Action 3',
          icon: DrawableResourceAndroidBitmap('secondary_icon'),
          showsUserInterface: true,
          // By default, Android plugin will dismiss the notification when the
          // user tapped on a action (this mimics the behavior on iOS).
          cancelNotification: false,
        ),
      ],
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: darwinNotificationCategoryPlain,//通知按钮提前注册过了
    );

    //聚合各个平台（Android, iOS, macOS, Linux, Windows）的特定通知配置。
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
      // macOS: macOSNotificationDetails,
      // linux: linuxNotificationDetails,
      // windows: windowsNotificationsDetails,
    );
    await flutterLocalNotificationsPlugin.show(
        id++, 'plain title', 'plain body', notificationDetails,
        payload: 'item z');
  }

   Future<void> _showNotificationWithTextAction() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'text_id_1',
          'Enter Text',
          icon: DrawableResourceAndroidBitmap('food'),
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Enter a message',
            ),
          ],
        ),
      ],
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: darwinNotificationCategoryText,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      // macOS: darwinNotificationDetails,
      // windows: windowsNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(id++, 'Text Input Notification',
    'Expand to see input action', notificationDetails,
    payload: 'item x');
  }

  Future<void> _showNotificationWithTextChoice() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'text_id_2',
          'Action 2',
          icon: DrawableResourceAndroidBitmap('food'),
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              choices: <String>['ABC', 'DEF'],
              allowFreeFormInput: false,
            ),
          ],
          contextual: true,
        ),
      ],
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: darwinNotificationCategoryText,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      // macOS: darwinNotificationDetails,
      // windows: windowsNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.show(
        id++, 'plain title', 'plain body', notificationDetails,
        payload: 'item x');
  }

  /// 显示自定义声音通知
  Future<void> _showNotificationCustomSound() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your other channel id',
      'your other channel name',
      channelDescription: 'your other channel description',
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
    );
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      sound: 'slow_spring_board.aiff',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      // macOS: darwinNotificationDetails,
      // linux: linuxPlatformChannelSpecifics,
      // windows: windowsNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      id++,
      'custom sound notification title',
      'custom sound notification body',
      notificationDetails,
    );
  }

  Future<void> _zonedScheduleNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'scheduled title',
        'scheduled body',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'your channel id', 'your channel name',
                channelDescription: 'your channel description')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }

  
  Future<void> _showNotificationSilently() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            silent: true);
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentSound: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
        // macOS: darwinNotificationDetails);
        // windows: windowsDetails,
    );
    await flutterLocalNotificationsPlugin.show(
        id++, '<b>silent</b> title', '<b>silent</b> body', notificationDetails);
  }

  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _showBigPictureNotificationHiddenLargeIcon() async {
    final String largeIconPath =
        await _downloadAndSaveFile('https://dummyimage.com/48x48', 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(
        'https://dummyimage.com/400x800', 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath),
            hideExpandedLargeIcon: true,
            contentTitle: 'overridden <b>big</b> content title',
            htmlFormatContentTitle: true,
            summaryText: 'summary <i>text</i>',
            htmlFormatSummaryText: true);
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'big text channel id', 'big text channel name',
            channelDescription: 'big text channel description',
            largeIcon: FilePathAndroidBitmap(largeIconPath),
            styleInformation: bigPictureStyleInformation);
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        id++, 'big text title', 'silent body', notificationDetails);
  }
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> _showProgressNotification() async {
    id++;
    final int progressId = id;
    const int maxProgress = 5;
    for (int i = 0; i <= maxProgress; i++) {
      await Future<void>.delayed(const Duration(seconds: 1), () async {
        final AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails('progress channel', 'progress channel',
                channelDescription: 'progress channel description',
                channelShowBadge: false,
                importance: Importance.max,
                priority: Priority.high,
                onlyAlertOnce: true,
                showProgress: true,
                maxProgress: maxProgress,
                progress: i);
        final NotificationDetails notificationDetails =
            NotificationDetails(android: androidNotificationDetails);
        await flutterLocalNotificationsPlugin.show(
            progressId,
            'progress notification title',
            'progress notification body',
            notificationDetails,
            payload: 'item x');
      });
    }
  }
  
  Future<void> _requestFullScreenIntentPermission() async {
    final bool permissionGranted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestFullScreenIntentPermission() ??
        false;
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              content: Text(
                  'Full screen intent permission granted: $permissionGranted'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ));
  }

  Future<void> _showFullScreenNotification() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Turn off your screen'),
        content: const Text(
            'to see the full-screen intent in 5 seconds, press OK and TURN '
            'OFF your screen. Note that the full-screen intent permission must '
            'be granted for this to work too'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await flutterLocalNotificationsPlugin.zonedSchedule(
                  0,
                  'scheduled title',
                  'scheduled body',
                  tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
                  const NotificationDetails(
                      android: AndroidNotificationDetails(
                          'full screen channel id', 'full screen channel name',
                          channelDescription: 'full screen channel description',
                          priority: Priority.high,
                          importance: Importance.high,
                          fullScreenIntent: true)),
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);

              Navigator.pop(context);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }


}


class SecondPage extends StatefulWidget {
  const SecondPage(
    this.payload, {
    this.data,
    Key? key,
  }) : super(key: key);

  static const String routeName = '/secondPage';

  final String? payload;
  final Map<String, dynamic>? data;

  @override
  State<StatefulWidget> createState() => SecondPageState();
}

class SecondPageState extends State<SecondPage> {
  String? _payload;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
    _data = widget.data;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Second Screen'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('payload ${_payload ?? ''}'),
              Text('data ${_data ?? ''}'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go back!'),
              ),
            ],
          ),
        ),
      );
}

class _InfoValueString extends StatelessWidget {
  const _InfoValueString({
    required this.title,
    required this.value,
    Key? key,
  }) : super(key: key);

  final String title;
  final Object? value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '$title ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '$value',
              )
            ],
          ),
        ),
      );
}

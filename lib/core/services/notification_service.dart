import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For Color
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'plugin.dart'; // 提供了 flutterLocalNotificationsPlugin

// 用于接收通知响应的流控制器
final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

// 方法通道，用于与原生代码通信
const MethodChannel platform =
    MethodChannel('dexterx.dev/flutter_local_notifications_example');

// 用于通知发送的端口名称
const String portName = 'notification_send_port';

String? selectedNotificationPayload; // 由 main.dart 逻辑管理 -> 将通过函数返回值传递

// 通知操作ID
const String urlLaunchActionId = 'id_1'; // URL启动操作ID
const String navigationActionId = 'id_3'; // 导航操作ID

// Darwin (iOS/macOS) 通知分类
const String darwinNotificationCategoryText = 'textCategory'; // 文本输入分类
const String darwinNotificationCategoryPlain = 'plainCategory'; // 普通分类

bool notificationsEnabled = false;

/// 当应用在后台或终止时，通知被点击的回调处理函数
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // 处理后台点击通知的逻辑
  debugPrint('通知服务 (_notificationTapBackground): 后台通知点击回调触发于 ${DateTime.now()}');
  debugPrint('通知服务 (_notificationTapBackground): 接收到通知返回 (background tap) - payload: ${notificationResponse.payload}, actionId: ${notificationResponse.actionId}, input: ${notificationResponse.input}');

  // 如果有 actionId，说明用户点击了通知上的某个操作按钮
  if (notificationResponse.actionId != null && notificationResponse.actionId!.isNotEmpty) {
    debugPrint('通知服务 (_notificationTapBackground): 用户点击了操作按钮: ${notificationResponse.actionId}');
  }
  // 根据 payload 或 actionId 执行特定操作
  if (notificationResponse.payload != null && notificationResponse.payload!.isNotEmpty) {
    debugPrint('通知服务 (_notificationTapBackground): 正在处理 payload: ${notificationResponse.payload}');
  }
  if (notificationResponse.input != null && notificationResponse.input!.isNotEmpty) {
    debugPrint('通知服务 (_notificationTapBackground): 收到用户输入: ${notificationResponse.input}');
  }
  debugPrint('通知服务 (_notificationTapBackground): 后台通知点击处理完毕。');
}

/// 接收到的通知的数据模型
class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    this.data,
  });

  final int id; // 通知ID
  final String? title; // 通知标题
  final String? body; // 通知正文
  final String? payload; // 通知负载数据
  final Map<String, dynamic>? data; // 额外数据
}

// 全局通知ID计数器
int _notificationIdCounter = 0;

// --- 时区配置 ---
/// 配置本地时区
Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    // Web 和 Linux 平台不需要额外配置
    return;
  }
  tz.initializeTimeZones(); // 初始化时区数据
  if (Platform.isWindows) {
    // Windows 平台无需通过 flutter_timezone 获取
    return;
  }
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone(); // 获取本地时区名称
  tz.setLocalLocation(tz.getLocation(timeZoneName!)); // 设置本地时区
}

// 新增的公共初始化函数
Future<NotificationResponse?> initializeNotificationService() async { // 修改返回类型
  // 1. 配置本地时区
  await _configureLocalTimeZone();

  // 2. 定义各种初始化设置
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // 确保这个 drawable 存在

  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
    DarwinNotificationCategory(
      darwinNotificationCategoryText, // 使用 service 内定义的常量
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.text(
          'text_1', // TODO: Consider making this a const in the service
          '回复',
          buttonTitle: '发送',
          placeholder: '请输入回复内容',
        ),
      ],
    ),
    DarwinNotificationCategory(
      darwinNotificationCategoryPlain, // 使用 service 内定义的常量
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('id_1', '动作 1'), // TODO: Consider making this a const
        DarwinNotificationAction.plain(
          'id_2', // TODO: Consider making this a const
          '动作 2 (iOS destructive)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.destructive,
          },
        ),
        DarwinNotificationAction.plain(
          navigationActionId, // 使用 service 内定义的常量
          '导航动作',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    )
  ];

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false, // 权限请求将在下面统一处理
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: darwinNotificationCategories,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  // 3. 初始化插件并设置回调
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      // 应用在前台时点击通知
      debugPrint('通知服务 (onDidReceiveNotificationResponse): 前台通知点击回调触发于 ${DateTime.now()}');
      debugPrint('通知服务 (onDidReceiveNotificationResponse): 接收到通知返回 (foreground tap) - payload: ${notificationResponse.payload}, actionId: ${notificationResponse.actionId}, input: ${notificationResponse.input}');
      if (notificationResponse.input != null && notificationResponse.input!.isNotEmpty) {
        debugPrint('通知服务 (onDidReceiveNotificationResponse): 收到用户输入: ${notificationResponse.input}');
      }
      selectNotificationStream.add(notificationResponse);
    },

    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  debugPrint('通知服务: 初始化插件配置完成');

  // 4. 请求权限
  if (Platform.isAndroid) {
    await requestAndroidNotificationsPermission();
  }
  if (Platform.isIOS || Platform.isMacOS) {
    await requestIOSMacOSPermissions();
  }

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
          Platform.isLinux//linux平台需要特殊赋值--null
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();//获取通知应用启动详情

  NotificationResponse? initialResponse;

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {//应用是否是通过点击一个通知启动的？"
    // selectedNotificationPayload = notificationAppLaunchDetails!.notificationResponse?.payload;//下面的response的payload即可访问这一条
    initialResponse = notificationAppLaunchDetails!.notificationResponse;
    debugPrint('通知服务: 应用通过通知启动。 Payload: ${initialResponse?.payload}, ActionID: ${initialResponse?.actionId}');
  }


  debugPrint('通知服务: 初始化完成');
  return initialResponse; // 返回获取到的响应
}

// --- 权限方法 ---

///检查权限
Future<void> checkAndroidPermission() async {
  if (Platform.isAndroid) {
    final bool granted = await isAndroidPermissionGranted();
    notificationsEnabled = granted;
  }
}

/// 检查 Android 通知权限是否已授予
Future<bool> isAndroidPermissionGranted() async {
  if (Platform.isAndroid) {
    final bool granted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;
    return granted;
  }
  // 其他平台，假设已授予或处理其特定的权限模型
  return true;
}

/// 请求 Android 通知权限
Future<bool?> requestAndroidNotificationsPermission() async {
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await androidImplementation?.requestNotificationsPermission();
  }
  return null;
}

/// 请求 iOS 和 macOS 通知权限
/// [critical] 是否请求紧急通知权限 (iOS)
Future<void> requestIOSMacOSPermissions({bool critical = false}) async {
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true, // 请求显示提醒权限
          badge: true, // 请求应用角标权限
          sound: true, // 请求播放声音权限
          critical: critical, // 是否请求紧急通知权限
        );
  }
  if (Platform.isMacOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: critical,
        );
  }
}

/// (Android 特定) 请求访问通知策略的权限 (例如，勿扰模式)
Future<void> requestNotificationPolicyAccess() async {
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationPolicyAccess();
  }
}

///请求权限
Future<void> requestPermissions() async {
  if (Platform.isIOS || Platform.isMacOS) {
    await requestIOSMacOSPermissions();
  } else if (Platform.isAndroid) {
    final bool? granted = await requestAndroidNotificationsPermission();
    notificationsEnabled = granted ?? false;
  }
}

// --- 通知显示方法 ---
/// 显示带有操作按钮的通知
Future<void> showNotificationWithActions() async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'channel_id_actions', // 渠道ID
    '操作通知渠道', // 渠道名称
    channelDescription: '用于显示带操作按钮的通知', // 渠道描述
    importance: Importance.max,
    priority: Priority.high,
    ticker: '通知来了',
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        urlLaunchActionId,
        '打开链接',
        icon: DrawableResourceAndroidBitmap('food'), // 假设 'food' 是一个有效的 drawable 资源
        contextual: true,
      ),
      AndroidNotificationAction(
        'id_2',
        '动作2',
        titleColor: Color.fromARGB(255, 255, 0, 0),
        icon: DrawableResourceAndroidBitmap('secondary_icon'), // 假设 'secondary_icon' 是一个有效的 drawable 资源
      ),
      AndroidNotificationAction(
        navigationActionId,
        '导航',
        icon: DrawableResourceAndroidBitmap('secondary_icon'),
        showsUserInterface: true, // 点击时显示应用界面
        cancelNotification: false, // 点击时不取消通知
      ),
    ],
  );

  const DarwinNotificationDetails iosNotificationDetails =
      DarwinNotificationDetails(
    categoryIdentifier: darwinNotificationCategoryPlain, // 使用普通分类
  );

  final NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: iosNotificationDetails,
  );
  await flutterLocalNotificationsPlugin.show(
      _notificationIdCounter++, '普通标题', '普通正文', notificationDetails,
      payload: '项目 Z');
}

/// 显示带有文本输入操作的通知
Future<void> showNotificationWithTextAction() async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'channel_id_text_input',//(Android) 区分通知渠道，用户可以在系统设置中管理此渠道的通知行为。
    '文本输入通知渠道',
    channelDescription: '用于显示带文本输入操作的通知',// 用户可见的渠道描述。
    importance: Importance.max,
    priority: Priority.high,
    ticker: '通知来了',
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'text_id_1',//(动作ID): 关键参数。当用户点击这个带输入的按钮并提交后，这个 ID 会包含在 NotificationResponse 的 actionId 字段中。
        '输入文本',//用户在通知上看到的按钮文字。
        icon: DrawableResourceAndroidBitmap('me'),//(Android) 按钮图标。
        inputs: <AndroidNotificationActionInput>[
          AndroidNotificationActionInput(
            label: '请在此输入回复...',
          ),
        ],
      ),
    ],
  );

  const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(
    categoryIdentifier: darwinNotificationCategoryText, // 使用文本输入分类
  );
  
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  debugPrint('通知服务: 显示带有文本输入操作的通知');

  await flutterLocalNotificationsPlugin.show(_notificationIdCounter++, '文本输入通知',
  '展开查看输入操作', notificationDetails,
  payload: '项目 X');//payload 会原样传递到 NotificationResponse 的 payload 字段。您可以用来识别是哪个类型的通知被点击了。 
}

/// 显示带有文本选项的通知
Future<void> showNotificationWithTextChoice() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channel_id_text_choice',
      '文本选择通知渠道',
      channelDescription: '用于显示带文本选项的通知',
      importance: Importance.max,
      priority: Priority.high,
      ticker: '通知来了',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'text_id_2',
          '选择操作',
          icon: DrawableResourceAndroidBitmap('food'),
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              choices: <String>['选项A', '选项B'],
              allowFreeFormInput: false, // 不允许自由输入
            ),
          ],
          contextual: true,
        ),
      ],
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: darwinNotificationCategoryText, // 使用文本输入分类
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    debugPrint('通知服务: 显示带有文本选项的通知');

    await flutterLocalNotificationsPlugin.show(
        _notificationIdCounter++, '普通标题', '普通正文', notificationDetails,
        payload: '项目 X');
  }

/// 显示自定义声音的通知
Future<void> showNotificationCustomSound() async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'channel_id_custom_sound',
    '自定义声音渠道',
    channelDescription: '用于播放自定义声音的通知',
    sound: RawResourceAndroidNotificationSound('slow_spring_board'), // Corrected: No file extension
    importance: Importance.max, // Ensure high importance for sound
    priority: Priority.high,    // Ensure high priority for sound
  );
  const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(
    sound: 'slow_spring_board.aiff', // For iOS, if you have this .aiff file in the bundle
  );

  final NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
    // macOS: darwinNotificationDetails, // If also providing for macOS
  );
  await flutterLocalNotificationsPlugin.show(
    _notificationIdCounter++,
    '自定义声音通知标题',
    '自定义声音通知正文',
    notificationDetails,
  );
}

/// 在指定本地时间安排一个通知
Future<void> zonedScheduleNotification() async {
  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        _notificationIdCounter++,
        '预定通知标题',
        '预定通知正文',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'channel_id_scheduled', '预定通知渠道',
                channelDescription: '用于预定通知的渠道'
                )),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
  } on PlatformException catch (e) {
    if (e.code == 'exact_alarms_not_permitted') {
      debugPrint('错误：无法安排精确闹钟。应用可能缺少 SCHEDULE_EXACT_ALARM 权限，或者用户未授予。');
    } else {
      print('安排预定通知时发生 PlatformException: ${e.message ?? e.details}');
    }
  } catch (e) {
    print('安排预定通知时发生未知错误: $e');
  }
}

/// 静默显示通知 (没有声音或振动)
Future<void> showNotificationSilently() async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails('channel_id_silent', '静默通知渠道',
          channelDescription: '用于静默显示的通知',
          importance: Importance.max,
          priority: Priority.high,
          ticker: '通知来了',
          silent: true); // 设置为静默
  const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(
    presentSound: false, // 不播放声音
  );

  final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
  );
  await flutterLocalNotificationsPlugin.show(
      _notificationIdCounter++, '<b>静默</b> 标题', '<b>静默</b> 正文', notificationDetails);
}

/// 取消所有通知
Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}

/// 显示带有大图片并隐藏展开后的大图标的通知
Future<void> showBigPictureNotificationHiddenLargeIcon() async {
  final String largeIconPath =
      await downloadAndSaveFile('https://dummyimage.com/48x48', 'largeIcon_zh');
  final String bigPicturePath = await downloadAndSaveFile(
      'https://dummyimage.com/400x800', 'bigPicture_zh');
  final BigPictureStyleInformation bigPictureStyleInformation =
      BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath),
          hideExpandedLargeIcon: true, // 展开时隐藏大图标
          contentTitle: '重写的<b>大图</b>内容标题',
          htmlFormatContentTitle: true,
          summaryText: '摘要<i>文本</i>',
          htmlFormatSummaryText: true);
  final AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
          'channel_id_big_picture', '大图通知渠道',
          channelDescription: '用于显示大图的通知',
          largeIcon: FilePathAndroidBitmap(largeIconPath),
          styleInformation: bigPictureStyleInformation);
  final NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
  await flutterLocalNotificationsPlugin.show(
      _notificationIdCounter++, '大图通知标题', '静默正文', notificationDetails);
}

/// 下载文件并保存到应用文档目录
/// [url] 文件下载地址
/// [fileName] 保存的文件名
/// 返回文件的本地路径
Future<String> downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

/// 显示进度条通知
Future<void> showProgressNotification() async {
  final int progressId = _notificationIdCounter++; // 为此系列通知使用唯一的ID
  const int maxProgress = 5;
  for (int i = 0; i <= maxProgress; i++) {
    await Future<void>.delayed(const Duration(seconds: 1), () async {
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails('channel_id_progress', '进度通知渠道',
              channelDescription: '显示进度的通知渠道',
              channelShowBadge: false, // 不显示渠道角标
              importance: Importance.max,
              priority: Priority.high,
              onlyAlertOnce: true, // 仅第一次通知时提醒
              showProgress: true, // 显示进度条
              maxProgress: maxProgress, // 最大进度
              progress: i); // 当前进度
      final NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);
      // 使用相同的 ID (progressId) 来更新通知
      await flutterLocalNotificationsPlugin.show(
          progressId, 
          '进度通知标题',
          '进度通知正文',
          notificationDetails,
          payload: '项目 X');
    });
  }
}

/// (Android 特定) 请求全屏意图权限
Future<bool?> requestAndroidFullScreenIntentPermission() async {
   if (Platform.isAndroid) {
    return await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestFullScreenIntentPermission();
   }
   return null;
}

/// 安排一个可以使用全屏意图的通知 (Android 特定)
Future<void> scheduleFullScreenNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        _notificationIdCounter++, // 此预定通知的唯一ID
        '全屏预定标题',
        '全屏预定正文',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // 5秒后
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'channel_id_fullscreen', '全屏通知渠道',
                channelDescription: '用于全屏意图的通知渠道',
                priority: Priority.high,
                importance: Importance.high,
                fullScreenIntent: true)), // 启用全屏意图
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle); // 允许在低电耗模式下精确执行
} 


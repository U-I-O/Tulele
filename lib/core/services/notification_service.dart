import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:typed_data'; // 添加导入Int32List
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// 添加Android 12+ 的配置
class NotificationConfig {
  // Android 12+ 需要确保PendingIntent的可变性
  static Int32List getAndroidNotificationFlags() {
    if (Platform.isAndroid) {
      try {
        // Bit flags: FLAG_IMMUTABLE(67108864) 或 FLAG_MUTABLE(33554432)，取决于你的需求
        // 对于按钮点击，我们需要MUTABLE确保能接收返回的结果
        return Int32List.fromList([33554432]); // FLAG_MUTABLE 
      } catch (e) {
        debugPrint("通知配置: 获取Android通知flags异常: $e");
      }
    }
    return Int32List.fromList([]);
  }

  // 获取Android通知全局配置
  static AndroidInitializationSettings getAndroidSettings() {
    return const AndroidInitializationSettings('@mipmap/ic_launcher');
  }
}

/// 通知操作按钮定义
class NotificationAction {
  final String id;
  final String title;
  final String? icon;

  NotificationAction({
    required this.id, 
    required this.title, 
    this.icon,
  });
}

/// 通知服务 - 支持Android和iOS平台的锁屏通知、横幅通知和自定义操作按钮
class NotificationService {
  // 单例模式
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 通知插件实例
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // 点击通知时的回调函数 (由 configureNotificationListeners 设置)
  Function(String?)? _onNotificationTapCallback;
  
  // 点击通知操作按钮时的回调函数 (由 configureNotificationListeners 设置)
  Function(String?, String?)? _onActionTapCallback;

  // 用于iOS类别注册时保存主要的回调
  Function(NotificationResponse)? _mainOnDidReceiveNotificationResponseHandler;
  Function(NotificationResponse)? _mainOnDidReceiveBackgroundNotificationResponseHandler;


  // 存储已注册的iOS DarwinNotificationCategory 列表
  final List<DarwinNotificationCategory> _accumulatedDarwinCategories = [];

  /// 内部统一处理通知响应的回调函数
  void _handlePluginNotificationResponse(NotificationResponse details) {
    debugPrint("通知服务: _handlePluginNotificationResponse 已触发!");
    debugPrint("通知服务: 响应类型: ${details.notificationResponseType}");
    debugPrint("通知服务: Payload: ${details.payload}");
    debugPrint("通知服务: ActionID: ${details.actionId}");
    debugPrint("通知服务: 用户输入: ${details.input}");

    if (details.notificationResponseType == NotificationResponseType.selectedNotification) {
      debugPrint("通知服务: 通知被点击 (前台/应用恢复时)");
      if (_onNotificationTapCallback != null) {
        _onNotificationTapCallback!(details.payload);
      } else {
        debugPrint("通知服务: _onNotificationTapCallback 回调未设置!");
      }
    } else if (details.notificationResponseType == NotificationResponseType.selectedNotificationAction) {
      debugPrint("通知服务: 通知操作按钮被点击 (前台/应用恢复时)");
      if (_onActionTapCallback != null) {
        debugPrint("通知服务: 调用 _onActionTapCallback - ActionID: ${details.actionId}, Payload: ${details.payload}");
        _onActionTapCallback!(details.actionId, details.payload);
      } else {
        debugPrint("通知服务: _onActionTapCallback 回调未设置!");
      }
    }
  }

  /// 初始化通知服务
  Future<void> init({Function(NotificationResponse)? onBackgroundResponse}) async {
    tz_data.initializeTimeZones(); 
    
    // 保存后台回调以备后用
    _mainOnDidReceiveBackgroundNotificationResponseHandler = onBackgroundResponse;
    // _mainOnDidReceiveNotificationResponseHandler 将直接使用 _handlePluginNotificationResponse
    
    // 使用全局配置获取Android设置
    final AndroidInitializationSettings androidSettings = NotificationConfig.getAndroidSettings();
    
    // iOS初始化设置
    // 注意：在NotificationService的init中，notificationCategories通常是动态注册的，
    // 所以初始时为空，后续通过registerNotificationCategory添加。
    // 如果有需要在服务初始化时就固定的iOS类别，也可以在这里添加。
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: _accumulatedDarwinCategories, // 初始为空，后续通过 register 更新
    );
    
    // 初始化设置
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // 初始化插件
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handlePluginNotificationResponse, // 使用统一处理函数
      onDidReceiveBackgroundNotificationResponse: _mainOnDidReceiveBackgroundNotificationResponseHandler,
    );

    debugPrint("通知服务: 初始化完成！测试日志输出正常。");

    // (新增) 创建Android通知渠道
    if (Platform.isAndroid) {
      // ... (Android渠道创建逻辑保持不变)
      const AndroidNotificationChannel tripChannel = AndroidNotificationChannel(
        'trip_status_channel', 
        '行程状态通知',        
        description: '用于通知行程的开始、进行中和结束状态。', 
        importance: Importance.max, 
        playSound: true,
      );
      const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
        'default_channel',    // 即时通知使用的渠道 ID
        '默认通知',             // 渠道名称
        description: '应用的默认通知频道。', // 渠道描述
        importance: Importance.high, 
        playSound: true,
      );

      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      try {
        await androidImplementation?.createNotificationChannel(tripChannel);
        await androidImplementation?.createNotificationChannel(defaultChannel); // 创建默认通知渠道
        debugPrint("通知服务: Android通知渠道创建成功");
      } catch (e) {
        debugPrint('通知服务: 创建通知渠道异常: $e');
      }
    }
  }
  
  /// 请求通知权限 (添加详细的权限检查和日志)
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      debugPrint("通知服务: 请求iOS通知权限");
      final bool result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
      debugPrint("通知服务: iOS通知权限请求结果: $result");
      return result;
    } else if (Platform.isAndroid) {
      // Android 13及以上版本需要请求通知权限
      debugPrint("通知服务: 请求Android通知权限");
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool result = await androidImplementation?.requestNotificationsPermission() ?? false;
      debugPrint("通知服务: Android通知权限请求结果: $result");
      return result;
    }
    debugPrint("通知服务: 当前平台不支持请求通知权限");
    return false;
  }

  /// 注册通知操作类别（iOS平台）- 修正版
  Future<void> registerNotificationCategory(String categoryId, List<NotificationAction> actions) async {
    if (Platform.isIOS) {
      debugPrint("通知服务: 开始为iOS注册类别 '$categoryId'");
      
      // 将新的 Category Action 转换为 DarwinNotificationAction
      final List<DarwinNotificationAction> darwinActions = actions.map((action) =>
        DarwinNotificationAction.plain(
          action.id,
          action.title,
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground, // 点击按钮后打开App
          },
        )
      ).toList();

      // 创建新的 DarwinNotificationCategory
      final newCategory = DarwinNotificationCategory(
        categoryId,
        actions: darwinActions,
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      );

      // 添加到累积列表 (如果已存在同名 categoryId，则替换)
      _accumulatedDarwinCategories.removeWhere((cat) => cat.identifier == categoryId);
      _accumulatedDarwinCategories.add(newCategory);
      
      // 重新初始化iOS部分以应用更新的类别列表
      // 注意：Android设置保持不变，iOS权限请求相关的也应设为false，因为权限应在init时请求一次
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher'); // 或保持一个常量实例
      
      final DarwinInitializationSettings updatedIosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // 不再重复请求权限
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: _accumulatedDarwinCategories, // 使用累积的完整列表
      );
      
      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: updatedIosSettings,
      );
      
      // 使用在 init 时保存的主回调函数重新初始化
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handlePluginNotificationResponse, // 使用统一处理函数
        onDidReceiveBackgroundNotificationResponse: _mainOnDidReceiveBackgroundNotificationResponseHandler,
      );
      debugPrint("通知服务: iOS Category '$categoryId' 已注册/更新，当前总类别数: ${_accumulatedDarwinCategories.length}");
    }
  }

  /// 显示通知 (保持showNotification方法结构，内部调用_getAndroidActions)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    List<NotificationAction>? actions,
    String? categoryId, // 用于iOS
    String? androidLargeIconPath, // Android large icon (本地文件路径)
    String? androidBigPicturePath, // Android BigPictureStyle image (本地文件路径)
    String? iOSAttachmentPath,     // iOS attachment image (本地文件路径)
  }) async {
    // 获取Android操作按钮的同时添加详细日志
    final List<AndroidNotificationAction>? androidActions = _getAndroidActions(actions);
    debugPrint("通知服务 showNotification: 准备发送通知 id=$id, 标题=\"$title\"");
    debugPrint("通知服务 showNotification: 准备传递给 AndroidNotificationDetails 的 actions: ${androidActions?.length ?? 0}个");
    
    // 详细记录每个按钮
    if (androidActions != null) {
      for (var action in androidActions) {
        debugPrint("通知服务 showNotification: Android Action: id=${action.id}, title=${action.title}");
      }
    }

    // Android 12+ 特殊处理
    Int32List androidFlags = NotificationConfig.getAndroidNotificationFlags();
    debugPrint("通知服务: 使用Android通知标志: $androidFlags");

    AndroidBitmap<String>? largeIconBitmap = androidLargeIconPath != null && androidLargeIconPath.isNotEmpty 
        ? FilePathAndroidBitmap(androidLargeIconPath) 
        : null;
    
    StyleInformation? styleInformation;
    if (androidBigPicturePath != null && androidBigPicturePath.isNotEmpty) {
      styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(androidBigPicturePath),
        largeIcon: largeIconBitmap, // BigPictureStyle 也可以有自己的 largeIcon
        contentTitle: title, // 可选，覆盖通知标题
        htmlFormatContentTitle: true,
        summaryText: body, // 可选，覆盖通知内容文本
        htmlFormatSummaryText: true,
      );
    }

    // 更新 AndroidNotificationDetails 创建逻辑，添加 flags
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel', 
      '默认通知',
      channelDescription: '应用的默认通知频道。',
      importance: Importance.high,
      priority: Priority.high,
      actions: androidActions,
      largeIcon: largeIconBitmap, // 设置 largeIcon (如果 BigPictureStyle 不用)
      styleInformation: styleInformation, // 设置 styleInformation (如 BigPictureStyle)
      // 添加Android 12+ 支持的flag
      fullScreenIntent: true, // 尝试使用全屏显示通知
      playSound: true, 
      ongoing: false, // 是否持续显示，除非手动清除
      autoCancel: true, // 点击后自动清除
      category: AndroidNotificationCategory.message, // 使用正确的枚举类型
      additionalFlags: androidFlags, // 使用定制的flags
    );

    // iOS通知详情
    List<DarwinNotificationAttachment>? iosAttachments;
    if (iOSAttachmentPath != null && iOSAttachmentPath.isNotEmpty) {
      try {
        iosAttachments = [DarwinNotificationAttachment(iOSAttachmentPath)];
        debugPrint("通知服务: 创建iOS图片附件: $iOSAttachmentPath");
      } catch (e) {
        debugPrint("通知服务: 创建iOS图片附件失败: $e");
      }
    }

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: categoryId, // iOS使用这个来关联已注册的Category
      interruptionLevel: InterruptionLevel.active,
      attachments: iosAttachments ?? [], // 添加附件
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint("通知服务: ID=$id 的通知发送成功");
    } catch (e) {
      debugPrint("通知服务: 发送通知失败: $e");
    }
  }

  /// 取消指定ID的通知 (保持不变)
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// 取消所有通知 (保持不变)
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// 配置通知监听器 (这些回调由 _handlePluginNotificationResponse 内部调用)
  void configureNotificationListeners({
    Function(String?)? onTap,
    Function(String?, String?)? onAction,
  }) {
    _onNotificationTapCallback = onTap;
    _onActionTapCallback = onAction;
    debugPrint("通知服务: 监听器已配置。 onTap: ${onTap!=null}, onAction: ${onAction!=null}");
  }

  /// 获取Android通知操作按钮 (保持不变)
  List<AndroidNotificationAction>? _getAndroidActions(List<NotificationAction>? actions) {
    debugPrint("通知服务: _getAndroidActions 执行，传入的 actions: $actions");
    if (actions == null || actions.isEmpty) {
      debugPrint("通知服务: 未提供 actions 或 actions 列表为空。");
      return null;
    }
    
    final androidActions = actions.map((action) {
      debugPrint("通知服务: 处理 action: id=${action.id}, title=${action.title}, icon=${action.icon}");
      if (action.icon != null) {
        return AndroidNotificationAction(
          action.id,
          action.title,
          icon: DrawableResourceAndroidBitmap(action.icon!),
        );
      } else {
        return AndroidNotificationAction(
          action.id,
          action.title,
        );
      }
    }).toList();
    debugPrint("通知服务: 转换后的 Android actions: $androidActions");
    return androidActions;
  }
} 
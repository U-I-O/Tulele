import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tulele/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulele/profile/presentation/pages/notification_test_page.dart';
import 'package:tulele/trips/presentation/pages/trip_detail_page.dart';

import 'package:tulele/profile/presentation/pages/notification_test_page.dart' 
    show NotificationActionIds, iosSimpleTestCategoryId, iosGeneralCategoryId;

class NotificationInteractionService {
  final NotificationService notificationService;
  final GlobalKey<NavigatorState> navigatorKey;

  static const String prefKeyPendingAction = 'pending_notification_action';
  static const String prefKeyPendingPayload = 'pending_notification_payload';

  NotificationInteractionService({
    required this.notificationService,
    required this.navigatorKey,
  });

  Future<void> init() async {
    _configureListeners();
    await _registerIOSCategories();
  }

  void _configureListeners() {
    notificationService.configureNotificationListeners(
      onTap: _handleNotificationTap,
      onAction: _handleActionTap,
    );
  }

  Future<void> _registerIOSCategories() async {
    if (Platform.isIOS) {
      debugPrint("通知交互服务: 正在注册iOS Categories...");
      
      // 注册极简测试 Category
      await notificationService.registerNotificationCategory(
        iosSimpleTestCategoryId, 
        [
          NotificationAction(id: NotificationActionIds.simpleTestAction, title: '测试按钮'),
        ],
      );
      debugPrint("通知交互服务: 极简Category ('$iosSimpleTestCategoryId') 已注册。");

      // 注册通用 Category - 取消注释并启用
      await notificationService.registerNotificationCategory(
        iosGeneralCategoryId,
        [
          NotificationAction(id: NotificationActionIds.viewImage, title: '查看图片'),
          NotificationAction(id: NotificationActionIds.navigateToDetails, title: '查看行程详情'),
          NotificationAction(id: NotificationActionIds.acceptSuggestion, title: '接受'),
          NotificationAction(id: NotificationActionIds.rejectSuggestion, title: '拒绝'),
        ],
      );
      debugPrint("通知交互服务: 通用Category ('$iosGeneralCategoryId') 已注册。");
    }
  }

  void _handleNotificationTap(String? payload) {
    debugPrint('通知交互服务: 点击事件 - Payload: $payload');
    if (navigatorKey.currentContext == null) {
      debugPrint("通知交互服务: 处理点击事件时，当前无可用 context。");
      return;
    }
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(content: Text('通知被点击! Payload: $payload')),
    );
  }

  void _handleActionTap(String? actionId, String? payload) {
    debugPrint('通知交互服务: 操作按钮点击 - ActionID: $actionId, Payload: $payload');
    final context = navigatorKey.currentContext;

    if (context == null) {
      debugPrint("通知交互服务: 处理操作按钮 $actionId 时，当前无可用 context。将保存操作。");
      _savePendingAction(actionId, payload);
      return;
    }

    // 处理所有操作按钮
    switch (actionId) {
      case NotificationActionIds.simpleTestAction:
        debugPrint("通知交互服务: simpleTestAction 已被触发！");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('极简测试按钮点击成功! Action: $actionId, Payload: $payload')),
        );
        break;
        
      case NotificationActionIds.viewImage:
        debugPrint("通知交互服务: Action - 查看图片");
        _showImageDialog(context, payload);
        break;
        
      case NotificationActionIds.navigateToDetails:
        debugPrint("通知交互服务: Action - 跳转行程详情页");
        String tripIdToNavigate = payload ?? "1";
        _navigateToPage(TripDetailPage(tripId: tripIdToNavigate));
        break;
        
      case NotificationActionIds.acceptSuggestion:
        debugPrint("通知交互服务: Action - 接受建议");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('建议已接受! Payload: $payload')),
        );
        break;
        
      case NotificationActionIds.rejectSuggestion:
        debugPrint("通知交互服务: Action - 拒绝建议");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('建议已拒绝! Payload: $payload')),
        );
        break;
        
      default:
        debugPrint("通知交互服务: 未知ActionID: $actionId");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('未知操作 "$actionId"! Payload: $payload')),
        );
    }
  }

  void _showImageDialog(BuildContext context, String? payload) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('查看图片'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'https://picsum.photos/200',
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.error, size: 100),
            ),
            const SizedBox(height: 10),
            Text('图片详情 (Payload: $payload)'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  void _navigateToPage(Widget page) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => page));
    } else {
       debugPrint("通知交互服务: 无法导航，navigatorKey.currentState 为空");
    }
  }

  Future<void> _savePendingAction(String? actionId, String? payload) async {
    if (actionId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint("通知交互服务: 保存待处理操作: $actionId, payload: $payload");
      await prefs.setString(prefKeyPendingAction, actionId);
      await prefs.setString(prefKeyPendingPayload, payload ?? '');
    } catch (e) {
      debugPrint('通知交互服务: SharedPreferences 操作异常: $e');
    }
  }

  Future<void> checkAndHandlePendingAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingActionId = prefs.getString(prefKeyPendingAction);
      final pendingPayload = prefs.getString(prefKeyPendingPayload);

      if (pendingActionId != null && navigatorKey.currentContext != null) {
        debugPrint("通知交互服务: 检测到待处理操作: $pendingActionId, Payload: $pendingPayload");
        await prefs.remove(prefKeyPendingAction);
        await prefs.remove(prefKeyPendingPayload);
        
        _handleActionTap(pendingActionId, pendingPayload);
      }
    } catch (e) {
      debugPrint('通知交互服务: 检查待处理操作时出错: $e');
    }
  }
}

/// 后台回调函数
@pragma('vm:entry-point')
void notificationTapBackgroundCallback(NotificationResponse notificationResponse) {
  debugPrint('(后台回调) 通知被点击: ${notificationResponse.payload}');
  debugPrint('(后台回调) 操作ID: ${notificationResponse.actionId}');
  
  if (notificationResponse.actionId != null && notificationResponse.actionId!.isNotEmpty) {
    final actionId = notificationResponse.actionId!;
    debugPrint('(后台回调) 处理操作按钮: $actionId');
    
    // 保存操作以供前台处理
    SharedPreferences.getInstance().then((prefs) {
      debugPrint("(后台回调) 保存待处理操作: $actionId");
      prefs.setString(NotificationInteractionService.prefKeyPendingAction, actionId);
      prefs.setString(NotificationInteractionService.prefKeyPendingPayload, 
          notificationResponse.payload ?? '');
    }).catchError((e) {
      debugPrint("(后台回调) SharedPreferences 操作异常: $e");
    });
  }
}
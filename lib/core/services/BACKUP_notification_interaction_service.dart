import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tulele/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulele/profile/presentation/pages/notification_test_page.dart';

//下面这个页面用来测试通知按钮的页面跳转功能。
import 'package:tulele/trips/presentation/pages/trip_detail_page.dart';

// iOS Category ID (可以移到更全局的地方如果多处使用)
import 'package:tulele/profile/presentation/pages/notification_test_page.dart' show NotificationActionIds, iosSimpleTestCategoryId, iosGeneralCategoryId;

class NotificationInteractionService {
  final NotificationService notificationService;
  final GlobalKey<NavigatorState> navigatorKey;

  // 用于从后台交互后传递数据到前台
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
      debugPrint("通知交互服务: 正在注册极简iOS Category...");
      // 仅注册极简测试 Category
      await notificationService.registerNotificationCategory(
        iosSimpleTestCategoryId, 
        [
          NotificationAction(id: NotificationActionIds.simpleTestAction, title: '测试按钮'),
        ],
      );
      debugPrint("通知交互服务: 极简iOS Category ('$iosSimpleTestCategoryId') 已注册。");

      // 暂时注释掉其他 Category 的注册
      /*
      await notificationService.registerNotificationCategory(
        'test_category_page_specific', 
        [
          // 注意：这里的 Action ID 和 Title 需要与 NotificationTestPage 中发送时一致
          // 如果不再使用 test_category_page_specific，可以移除此段注册
          NotificationAction(id: 'view_image_action_old', title: '查看图片(旧)'), 
          NotificationAction(id: 'dismiss_message_action_old', title: '忽略消息(旧)'),
        ],
      );

      // 注册新的通用 Category
      await notificationService.registerNotificationCategory(
        iosGeneralCategoryId, // 直接使用在这里定义的常量
        [
          // 这里需要包含所有可能通过 general_actions_category 发送的按钮
          // 即使一次通知只用其中一个，Category也要定义全
          NotificationAction(id: NotificationActionIds.viewImage, title: '查看图片'),
          NotificationAction(id: NotificationActionIds.navigateToDetails, title: '查看行程详情'),
          NotificationAction(id: NotificationActionIds.acceptSuggestion, title: '接受'),
          NotificationAction(id: NotificationActionIds.rejectSuggestion, title: '拒绝'),
        ],
      );
        debugPrint("通知交互服务: iOS Categories 已注册");
      */
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
    debugPrint('通知交互服务 (极简测试): 操作按钮点击 - ActionID: $actionId, Payload: $payload');
    final context = navigatorKey.currentContext;

    if (actionId == NotificationActionIds.simpleTestAction) {
      debugPrint("通知交互服务 (极简测试): simpleTestAction 已被正确触发！");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('极简测试按钮点击成功! Action: $actionId, Payload: $payload')),
        );
      } else {
         debugPrint("通知交互服务 (极简测试): simpleTestAction 被触发，但 context 为空。");
        _savePendingAction(actionId, payload); // 仍然保存，以防万一
      }
      return; // 直接返回，不处理其他case
    }

    // 暂时注释掉 switch 和其他 case
    /*
    if (context == null) {
      debugPrint("通知交互服务: 处理操作按钮 $actionId 时，当前无可用 context。将尝试保存操作。");
      // 如果没有可用 context (例如应用在后台被终止后通过通知按钮启动)，保存意图
      _savePendingAction(actionId, payload);
      return;
    }

    switch (actionId) {
      case NotificationActionIds.viewImage:
        debugPrint("通知交互服务: Action - 查看图片");
        _showImageDialog(context, payload);
        break;
      case NotificationActionIds.navigateToDetails:
        debugPrint("通知交互服务: Action - 跳转行程详情页");
        String tripIdToNavigate = payload ?? "1"; // 默认跳转到行程ID为"1"的详情，或者从payload获取
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
      // 处理旧的/其他的 actionId (如果还需要兼容的话)
      case 'view_image_action_old': // 假设这是旧测试页的ID
         debugPrint("通知交互服务: Action - 查看图片 (来自旧测试页)");
        _showImageDialog(context, payload);
        break;
      default:
        debugPrint("通知交互服务: 未知或未处理的 ActionID: $actionId");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('未知操作 "$actionId"! Payload: $payload')),
        );
    }
    */
    debugPrint("通知交互服务 (极简测试): Action ID '$actionId' 未匹配到 simpleTestAction。");
  }

  void _showImageDialog(BuildContext context, String? payload) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('查看图片 (来自交互服务)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network('https://picsum.photos/200'), // 示例图片
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
       // 可以考虑保存导航意图，类似 _savePendingAction
    }
  }

  Future<void> _savePendingAction(String? actionId, String? payload) async {
    if (actionId == null) return;
    SharedPreferences.getInstance().then((prefs) { 
      debugPrint("通知交互服务 (极简测试): 保存待处理操作: $actionId, payload: $payload");
      prefs.setString(prefKeyPendingAction, actionId);
      prefs.setString(prefKeyPendingPayload, payload ?? '');
    }).catchError((e) {
        debugPrint('(极简测试 - 无 context 前台处理) SharedPreferences 操作异常: $e');
    });
  }

  Future<void> checkAndHandlePendingAction() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActionId = prefs.getString(prefKeyPendingAction);
    final pendingPayload = prefs.getString(prefKeyPendingPayload);

    if (pendingActionId != null && navigatorKey.currentContext != null) {
      debugPrint("通知交互服务 (极简测试): 检测到待处理操作: $pendingActionId, Payload: $pendingPayload");
      await prefs.remove(prefKeyPendingAction);
      await prefs.remove(prefKeyPendingPayload);
      
      // 重新调用 _handleActionTap 来处理，确保逻辑一致性
      // 注意：这里假设 _handleActionTap 在有 context 时不会再次调用 _savePendingAction
      _handleActionTap(pendingActionId, pendingPayload);
    } else if (pendingActionId != null) {
      debugPrint("通知交互服务 (极简测试): 检测到待处理操作 $pendingActionId，但 context 为空，将保留待下次检查");
    }
  }
}

/// 修改后的后台回调，如果需要，它可以尝试保存信息以供前台处理
@pragma('vm:entry-point')
void notificationTapBackgroundCallback(NotificationResponse notificationResponse) {
  debugPrint('(后台回调 - 极简测试) 通知被点击: ${notificationResponse.payload}');
  if (notificationResponse.actionId != null && notificationResponse.actionId!.isNotEmpty) {
    debugPrint('(后台回调 - 极简测试) 操作按钮ID: ${notificationResponse.actionId}');
    final actionId = notificationResponse.actionId!;
    if (actionId == NotificationActionIds.simpleTestAction) { // 只处理 simpleTestAction
      SharedPreferences.getInstance().then((prefs) {
        debugPrint("(后台回调 - 极简测试) 保存待处理操作: $actionId, payload: ${notificationResponse.payload}");
        prefs.setString(NotificationInteractionService.prefKeyPendingAction, actionId);
        prefs.setString(NotificationInteractionService.prefKeyPendingPayload, notificationResponse.payload ?? '');
      }).catchError((e) {
          debugPrint("(后台回调 - 极简测试) SharedPreferences 操作异常: $e");
      });
    } else {
        debugPrint("(后台回调 - 极简测试) 收到非 simpleTestAction 后台 ActionID: $actionId");
    }
  }
} 
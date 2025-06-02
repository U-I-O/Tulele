# NotificationService 使用指南

本文档介绍了如何在项目中使用 `NotificationService` 来发送和管理本地通知。

## 1. `NotificationService` 概述

`NotificationService` (`lib/core/services/notification_service.dart`) 是一个封装了 `flutter_local_notifications` 插件功能的单例服务，用于在 Android 和 iOS 平台上显示本地通知。

### 主要功能：

*   **初始化服务**: 配置平台特性，设置回调。
*   **请求权限**: 向用户请求通知权限。
*   **显示即时通知**: 发送立即显示的通知，可包含标题、正文、payload、操作按钮，并可控制锁屏显隐。
*   **发送定时通知**: 在预定时间发送通知。
*   **注册 iOS 通知类别**: 为 iOS 定义带有自定义操作按钮的通知。
*   **取消通知**: 取消单个或所有通知。
*   **配置监听器**: 处理用户与通知的交互（点击通知体、点击操作按钮）。

## 2. 初始化和配置

### 2.1. 在 `main.dart` 中初始化

应用启动时，在 `main()` 函数中初始化 `NotificationService`：

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:tulele/core/services/notification_service.dart'; // 您的服务路径
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 用于 NotificationResponse 类型
import 'dart:io'; // 用于 Platform.isIOS

// 后台通知点击处理函数 (保持为顶级函数)
@pragma('vm:entry-point')
void notificationTapBackgroundCallback(NotificationResponse notificationResponse) {
  debugPrint('(Background) notification tapped: ${notificationResponse.payload}');
  if (notificationResponse.actionId == 'ok_action') {
    debugPrint('Background OK action tapped for payload: ${notificationResponse.payload}');
  }
  // ... 其他后台逻辑 ...
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NotificationService notificationService = NotificationService();
  await notificationService.init(
    onBackgroundResponse: notificationTapBackgroundCallback,
  );

  // 配置前台通知监听器
  notificationService.configureNotificationListeners(
    onTap: (payload) {
      debugPrint('NotificationService: Foreground notification tapped with payload: $payload');
      // TODO: 根据 payload 处理通知点击，例如导航
    },
    onAction: (actionId, payload) {
      debugPrint('NotificationService: Foreground action \\'$actionId\\' tapped with payload: $payload');
      // TODO: 根据 actionId 和 payload 处理按钮点击
    },
  );

  // 注册 iOS 通知类别 (示例)
  if (Platform.isIOS) {
    await notificationService.registerNotificationCategory(
      'my_custom_category', // 类别 ID
      [
        NotificationAction(id: 'view_details', title: '查看详情'),
        NotificationAction(id: 'later', title: '稍后提醒'),
      ],
    );
     await notificationService.registerNotificationCategory(
      'trip_started_category', // 来自旧 main.dart 的示例
      [
        NotificationAction(id: 'ok_action', title: '好的'),
        NotificationAction(id: 'cancel_action', title: '取消'),
      ],
    );
  }

  runApp(MyAppEntry(notificationService: notificationService));
}
```

### 2.2. 传递 `NotificationService` 实例

将 `notificationService` 实例通过构造函数传递给需要使用通知功能的 Widget（如页面、子组件等）。

```dart
// MyAppEntry Widget
class MyAppEntry extends StatelessWidget {
  final NotificationService notificationService;
  const MyAppEntry({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      home: MainPageNavigator(notificationService: notificationService),
    );
  }
}

// MainPageNavigator Widget
class MainPageNavigator extends StatefulWidget {
  final NotificationService notificationService;
  const MainPageNavigator({super.key, required this.notificationService});
  // ...
}
```

## 3. 在页面中使用通知功能

### 3.1. 请求权限

在需要发送通知之前（通常在相关页面的 `initState` 或用户触发某个操作时），请求权限：

```dart
// 在某个 StatefulWidget 的 State 中
class _MyPageState extends State<MyPage> {
  @override
  void initState() {
    super.initState();
    _requestPerms();
  }

  Future<void> _requestPerms() async {
    bool? granted = await widget.notificationService.requestPermission();
    debugPrint("Notification permissions granted: $granted");
  }
  // ...
}
```

### 3.2. 发送即时通知

```dart
void sendSimpleNotification() {
  widget.notificationService.showNotification(
    id: 101, // 唯一 ID
    title: "通知标题",
    body: "这是通知的具体内容。",
    payload: "custom_payload_data_for_simple_notification",
  );
}
```

### 3.3. 发送带操作按钮的通知

```dart
void sendNotificationWithActions() {
  // 确保 iOS 类别已注册 (见 2.1)
  widget.notificationService.showNotification(
    id: 102,
    title: "任务提醒",
    body: "您有一个新任务需要处理。",
    payload: "task_id_abc",
    actions: [
      NotificationAction(id: 'view_task', title: '查看任务'),
      NotificationAction(id: 'mark_as_done', title: '标记完成', icon: '@drawable/ic_done'), // Android 可选图标
    ],
    categoryId: 'my_custom_category', // iOS 类别 ID
  );
}
```
**注意 for Android 图标**: `icon: '@drawable/ic_done'` 指向 `android/app/src/main/res/drawable/ic_done.png` (或其他格式)。您需要将图标文件放置在该目录下。

### 3.4. 发送定时通知

```dart
void scheduleFutureNotification() {
  widget.notificationService.scheduleNotification(
    id: 103,
    title: "定时提醒",
    body: "这是1小时后的定时提醒。",
    scheduledTime: DateTime.now().add(const Duration(hours: 1)),
    payload: "scheduled_reminder_payload",
  );
}
```

### 3.5. 取消通知

```dart
void cancelSpecificNotification(int notificationId) {
  widget.notificationService.cancelNotification(notificationId);
}

void cancelAllMyNotifications() {
  widget.notificationService.cancelAllNotifications();
}
```

## 4. 处理通知交互

用户与通知的交互（点击通知本身或操作按钮）主要通过在 `main.dart` 中配置的 `configureNotificationListeners` 和 `init` 方法中的 `onBackgroundResponse` 回调来处理。

*   **`onTap` (来自 `configureNotificationListeners`)**: 应用在前台时，用户点击通知主体。
    *   参数: `String? payload`
*   **`onAction` (来自 `configureNotificationListeners`)**: 应用在前台时，用户点击操作按钮。
    *   参数: `String? actionId`, `String? payload`
*   **`onBackgroundResponse` (来自 `init`)**: 应用在后台或关闭时，用户点击通知或操作按钮。
    *   参数: `NotificationResponse details` (包含 `payload`, `actionId` 等)
    *   **重要**: 此回调在独立的 Isolate 中执行，避免直接的 UI 操作或复杂的异步任务。

**示例 (在 `main.dart` 中已配置):**
```dart
// notificationService.configureNotificationListeners(
//   onTap: (payload) {
//     // 根据 payload 导航或执行操作
//   },
//   onAction: (actionId, payload) {
//     // 根据 actionId 和 payload 执行操作
//     if (actionId == 'view_task') { /* ... */ }
//   },
// );

// @pragma('vm:entry-point')
// void notificationTapBackgroundCallback(NotificationResponse notificationResponse) {
//   // 处理后台交互
// }
```

## 5. iOS 通知类别注册 (重要)

对于需要在 iOS 上显示操作按钮的通知，必须先注册一个包含这些操作的通知类别。

```dart
// 在 main.dart 或应用初始化早期阶段
if (Platform.isIOS) {
  await notificationService.registerNotificationCategory(
    'your_category_id', // 唯一的类别 ID
    [
      NotificationAction(id: 'action1_id', title: '按钮1'),
      NotificationAction(id: 'action2_id', title: '按钮2'),
    ],
  );
}
```
之后，在 `showNotification` 或 `scheduleNotification` 时，通过 `categoryId: 'your_category_id'` 来使用这些按钮。

## 6. `NotificationAction` 类

定义通知操作按钮时使用：
```dart
class NotificationAction {
  final String id;    // 按钮的唯一标识符，用于回调中识别
  final String title; // 按钮上显示的文本
  final String? icon; // (可选, 主要用于 Android) drawable 资源名, e.g., '@mipmap/ic_launcher' or '@drawable/my_icon'

  NotificationAction({required this.id, required this.title, this.icon});
}
```

---

请将此 Markdown 内容保存到您项目中的 `.md` 文件中，例如 `docs/notification_service_usage.md` 或直接在项目根目录。 
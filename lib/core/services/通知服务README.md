# 通知服务使用指南

## 简介

本通知服务旨在提供一个统一的接口来处理 Flutter 应用中的本地通知，包括通知的发送、交互处理（如按钮点击、通知点击导航）、以及特定于平台（如 iOS 的通知类别和 Android 的大图样式）的配置。

## 核心组件

服务主要由以下两个类组成：

1.  **`NotificationService` (`notification_service.dart`)**
    *   **职责**：处理与 `flutter_local_notifications` 插件直接相关的底层通知逻辑。
    *   **功能**：
        *   初始化通知插件 (`init`)。
        *   请求通知权限 (`requestPermission`)。
        *   显示基本通知 (`showNotification`)。
        *   取消通知 (`cancelNotification`, `cancelAllNotifications`)。
        *   配置 Android Channels 和 iOS 通知设置。

2.  **`NotificationInteractionService` (`notification_interaction_service.dart`)**
    *   **职责**：建立在 `NotificationService` 之上，管理通知的交互逻辑、按钮行为、payload 处理和导航。
    *   **功能**：
        *   初始化，包括处理应用因通知启动的情况 (`init`, `checkAndHandlePendingAction`)。
        *   提供发送带操作按钮和图片的通知接口 (`showNotificationWithActions`)。
        *   注册和处理通知按钮的操作回调 (`registerActionCallback`, `handleNotificationResponsePublic`)。
        *   处理通知点击后的默认行为（如根据 payload 导航）。
        *   管理 iOS 的通知类别 (`DarwinNotificationCategory`) 定义。
        *   将 Asset 图片复制到临时文件以供通知使用 (`_copyAssetToTempFile`)。

## 初始化步骤 (`main.dart`)

在您的 `main.dart` 的 `main()` 函数中，按以下顺序初始化服务：

```dart
// 全局 NavigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 全局 NotificationInteractionService 实例
late final NotificationInteractionService notificationInteractionService;

// 后台通知回调 (保持为顶级函数)
@pragma('vm:entry-point')
void notificationTapBackgroundCallback(NotificationResponse notificationResponse) {
  // 简单日志记录，实际处理由 NotificationInteractionService 在应用启动/前台时完成
  debugPrint('notificationTapBackgroundCallback: 通知被点击 (后台/终止)');
  // ... (更多日志)
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 创建 NotificationService 实例
  final NotificationService notificationServiceInstance = NotificationService();

  // 2. 获取 iOS 通知类别 (可选，如果需要自定义按钮等)
  final List<DarwinNotificationCategory> darwinCategories =
      NotificationInteractionService.getDarwinNotificationCategories();

  // 3. 创建 NotificationInteractionService 实例
  // 必须在 notificationService.init() 之前创建并赋值给全局变量，
  // 以便 notificationService.init() 内部的回调可以引用它。
  notificationInteractionService = NotificationInteractionService(
    notificationService: notificationServiceInstance,
    navigatorKey: navigatorKey,
  );

  try {
    // 4. 初始化 NotificationService
    // 将 notificationInteractionService 的公共响应处理器传递给它
    await notificationServiceInstance.init(
      onBackgroundResponse: notificationTapBackgroundCallback,
      darwinNotificationCategories: darwinCategories,
      onForegroundLaunchResponse: notificationInteractionService.handleNotificationResponsePublic,
    );

    // 5. 初始化 NotificationInteractionService
    // (主要处理应用启动时的通知详情)
    await notificationInteractionService.init();

    // 6. 请求通知权限
    await notificationServiceInstance.requestPermission();

    // 7. (可选) 注册通知操作按钮的回调
    notificationInteractionService.registerActionCallback('action_view', (actionId, payload, input) async {
      debugPrint('Callback for action_view: Payload: $payload');
      // ... 实现导航或特定操作 ...
      if (payload != null) {
        final Map<String, dynamic> payloadMap = jsonDecode(payload);
        final String? tripId = payloadMap['tripId'];
        if (tripId != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => TripDetailPage(tripId: tripId)),
          );
        }
      }
    });
    // ... 其他回调注册 ...

  } catch (e, s) {
    debugPrint('初始化通知服务失败: $e\n$s');
  }

  runApp(MyAppEntry(notificationInteractionService: notificationInteractionService));
}
```

## 发送通知

通过全局的 `notificationInteractionService` 实例来发送通知。

### 1. 发送简单通知 (无按钮，无图片)

```dart
notificationInteractionService.notificationService.showNotification(
  id: 1, // 唯一 ID
  title: '简单通知',
  body: '这是一个没有按钮和图片的通知。',
  payload: jsonEncode({'screen': '/default_page'}), // 可选 payload
);
```

### 2. 发送带操作按钮的通知

```dart
final actions = [
  NotificationActionButton(id: 'action_view', text: '查看'),
  NotificationActionButton(id: 'action_dismiss', text: '忽略'),
];

notificationInteractionService.showNotificationWithActions(
  id: 2,
  title: '带操作的通知',
  body: '请选择一个操作。',
  categoryIdentifier: 'example_category', // 对于 iOS，这必须匹配已注册的 DarwinNotificationCategory
  actions: actions,
  payloadData: {'itemId': 'item_001', 'type': 'interactive'},
);
```

### 3. 发送带图片和操作按钮的通知

确保图片已在 `pubspec.yaml` 的 `assets` 中声明，并且文件存在于指定路径。

```dart
const String imagePath = 'assets/images/my_banner.png'; // 示例图片路径

final actions = [
  NotificationActionButton(id: 'action_view_image', text: '查看大图'),
];

notificationInteractionService.showNotificationWithActions(
  id: 3,
  title: '风景图推送',
  body: '快来看看这张美丽的风景图！',
  imageAssetPath: imagePath, // Asset 图片路径
  categoryIdentifier: 'example_category', // iOS 类别
  actions: actions,
  payloadData: {'imageId': 'img_002', 'source': 'gallery'},
);
```

## 处理通知交互

### 1. 点击通知主体

当用户点击通知本身（而不是一个特定的按钮）时：
*   `NotificationInteractionService` 的 `handleNotificationResponsePublic` 方法会被调用。
*   如果 payload 中包含可识别的导航信息（例如 `tripId`，如示例中配置），它会尝试执行导航。
*   您可以根据需要在 `handleNotificationResponsePublic` 中扩展此默认行为。

### 2. 处理按钮回调

使用 `notificationInteractionService.registerActionCallback(actionId, callback)` 注册特定按钮 `actionId` 的回调函数。

*   `actionId`: 与 `NotificationActionButton` 中定义的 `id` 匹配的字符串。
*   `callback`: 一个 `Future<void> Function(String? actionId, String? payload, String? input)` 类型的函数。
    *   `payload`: 通知发送时附加的 JSON 字符串 payload。
    *   `input`: 如果是 iOS 上的文本输入按钮，这里会包含用户的输入。

示例 (已在初始化部分展示)。

## iOS 特定配置：通知类别

对于 iOS，要在通知上显示自定义按钮（包括文本输入按钮），您需要定义并注册 `DarwinNotificationCategory`。

*   **定义**：在 `NotificationInteractionService.getDarwinNotificationCategories()` 中定义您的类别和关联的 `DarwinNotificationAction`。
    ```dart
    static List<DarwinNotificationCategory> getDarwinNotificationCategories() {
      final DarwinNotificationCategory exampleCategory = DarwinNotificationCategory(
        'example_category', // 唯一标识符，在发送通知时使用
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('action_view', '查看', options: {DarwinNotificationActionOption.foreground}),
          DarwinNotificationAction.plain('action_dismiss', '忽略', options: {DarwinNotificationActionOption.destructive}),
          DarwinNotificationAction.text('action_reply', '回复', buttonTitle: '发送', placeholder: '输入内容...', options: {DarwinNotificationActionOption.foreground}),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle, // 锁屏时也显示标题和按钮
        },
      );
      return [exampleCategory];
    }
    ```
*   **注册**：这些类别会在 `NotificationService.init()` 期间自动注册到 iOS 系统。
*   **使用**：在调用 `showNotificationWithActions` 时，提供匹配的 `categoryIdentifier`。

## 测试通知

项目中的 `lib/profile/presentation/pages/notification_test_page.dart` 提供了一个测试页面，其中包含发送各种类型通知的按钮，方便您测试和调试通知功能。

## 注意事项

*   **权限**：确保在应用启动时调用 `notificationService.requestPermission()` 以请求用户授予通知权限。
*   **图片资源**：对于带图片的通知，确保图片资源已在 `pubspec.yaml` 中声明，并且实际存在于项目中。
*   **后台回调 (`notificationTapBackgroundCallback`)**：此函数在独立的 Isolate 中运行，不能直接访问主 Isolate 中的实例或执行 UI 操作。其主要作用是记录或唤醒应用。实际的通知处理（包括启动应用后的导航）由 `NotificationInteractionService` 在应用进入前台时处理。
*   **Payload**：`payload` 通常应为 JSON 字符串，方便解析和传递结构化数据。
*   **唯一 ID**：发送每个通知时，请确保提供一个唯一的 `id`，以便能够更新或取消特定的通知。

---
该文档旨在帮助您快速理解和集成通知服务。如有疑问或需要更高级的定制，请参考 `flutter_local_notifications` 插件的官方文档和本服务的具体实现代码。 
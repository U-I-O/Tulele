import 'package:flutter/material.dart';
// 移除 provider 的导入，因为 NotificationService 实例是直接创建的
// import 'package:provider/provider.dart'; 
import 'package:tulele/core/services/notification_service.dart';
import 'dart:io'; // For File operations
import 'package:flutter/services.dart' show ByteData, rootBundle; // For asset loading
import 'package:path_provider/path_provider.dart'; // For temporary directory



// 定义通用的 Action ID (实际项目中可以放在更全局的位置)
class NotificationActionIds {
  static const String viewImage = 'view_image_action';
  static const String navigateToDetails = 'navigate_to_details_action';
  static const String acceptSuggestion = 'accept_suggestion_action';
  static const String rejectSuggestion = 'reject_suggestion_action';
  static const String simpleTestAction = 'simple_test_action'; // 新增一个极简测试Action ID
}

// 保持 iOS Category ID 定义
const String iosGeneralCategoryId = 'general_actions_category';
const String iosSimpleTestCategoryId = 'simple_test_category'; // 新增一个极简测试Category ID

class NotificationTestPage extends StatelessWidget {
  const NotificationTestPage({super.key});

  // 辅助函数：将 asset 图片复制到临时目录并返回其路径
  Future<String> _getExampleImagePath(BuildContext context, String assetPath) async {
    try {
      // 从 assetPath 中提取文件名，例如 'assets/img/OIP-C.jpg' -> 'OIP-C.jpg'
      final String fileName = assetPath.split('/').last;
      final ByteData byteData = await rootBundle.load(assetPath);
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$fileName');
      
      // 检查文件是否已存在，避免不必要的写入
      if (await file.exists()) {
        // 可选：如果希望每次都用最新的 asset 文件覆盖，可以取消下一行的注释
        // await file.delete(); 
      } else {
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }
      debugPrint("图片已复制到临时路径: ${file.path}");
      return file.path;
    } catch (e) {
      debugPrint("错误: 复制 asset 图片失败: $e");
      // 返回一个空字符串或抛出异常，让调用者知道出错了
      // 这里返回空路径，调用方需要处理这种情况
      return ''; 
    }
  }

  @override
  Widget build(BuildContext context) {
    // 直接实例化 NotificationService，或者通过正确的依赖注入方式获取
    // 这里我们暂时恢复之前的直接实例化方式，以解决 linter error
    // 如果项目中已经有统一的依赖管理方案，请遵循该方案
    final NotificationService notificationService = NotificationService(); 
    const String commonPayload = 'generic_action_payload';

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知操作测试 - 简化版'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView( // 使用 ListView 方便扩展
            children: <Widget>[
              const Text("请先确保在 NotificationInteractionService 中注册了 \'simple_test_category\' 及其 action。"),
              const SizedBox(height: 10),
              ElevatedButton(
                child: const Text('发送极简测试通知 (按钮)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  notificationService.showNotification(
                    id: 99, // 使用新的ID
                    title: '极简测试',
                    body: '点击下方按钮测试回调。',
                    payload: 'simple_test_payload',
                    actions: [
                      NotificationAction(id: NotificationActionIds.simpleTestAction, title: '测试按钮'),
                    ],
                    categoryId: iosSimpleTestCategoryId, // 使用新的Category ID for iOS
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('极简测试通知已发送')),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('发送通知 (按钮: 查看图片)'),
                onPressed: () {
                  notificationService.showNotification(
                    id: 10,
                    title: '操作请求',
                    body: '点击按钮查看一张图片。',
                    payload: commonPayload,
                    actions: [
                      NotificationAction(id: NotificationActionIds.viewImage, title: '查看图片'),
                    ],
                    categoryId: iosGeneralCategoryId, 
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('通知已发送 (操作: 查看图片)')),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                child: const Text('发送通知 (按钮: 跳转行程详情)'),
                onPressed: () {
                  notificationService.showNotification(
                    id: 11,
                    title: '新消息',
                    body: '点击按钮查看行程详情。',
                    payload: "trip_123",
                    actions: [
                      NotificationAction(id: NotificationActionIds.navigateToDetails, title: '查看行程详情'),
                    ],
                    categoryId: iosGeneralCategoryId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('通知已发送 (操作: 跳转行程详情)')),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                child: const Text('发送通知 (按钮: 接受建议)'),
                onPressed: () {
                  notificationService.showNotification(
                    id: 12,
                    title: '建议提醒',
                    body: '您有一个新的建议，是否接受？',
                    payload: commonPayload,
                    actions: [
                      NotificationAction(id: NotificationActionIds.acceptSuggestion, title: '接受'),
                      NotificationAction(id: NotificationActionIds.rejectSuggestion, title: '拒绝'),
                    ],
                    categoryId: iosGeneralCategoryId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('通知已发送 (操作: 接受建议),\n(操作: 拒绝建议)')),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('发送带本地图片通知 (OIP-C.jpg)'),
                onPressed: () async {
                  // 使用您提供的 asset 路径
                  String imagePath = await _getExampleImagePath(context, 'assets/img/OIP-C.jpg'); 
                  if (imagePath.isNotEmpty) { // 确保路径有效
                    notificationService.showNotification(
                      id: 20,
                      title: '本地图片测试',
                      body: '这是来自 assets 的 OIP-C.jpg。',
                      payload: 'local_image_payload',
                      androidBigPicturePath: imagePath,
                      androidLargeIconPath: imagePath, 
                      iOSAttachmentPath: imagePath, 
                      categoryId: iosGeneralCategoryId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('带本地图片的通知已发送')),
                    );
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('错误: 无法获取图片路径')),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('取消所有通知', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  notificationService.cancelAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有通知已取消')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 移除了之前测试用的 _showImageDialog 和 _showIgnoredDialog，
// 因为这些UI响应现在由 NotificationInteractionService 处理 
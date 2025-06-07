import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../core/services/user_service.dart';
import 'trip_detail_page.dart';
import '../../services/trip_sharing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return; // 防止多次扫描同一个码

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      
      if (code != null) {
        setState(() {
          _isScanned = true;
        });
        
        _processQrCode(code);
      }
    }
  }

  void _processQrCode(String code) {
    // 判断是否是邀请链接格式
    if (code.contains('/invite/')) {
      // 提取邀请码
      final invitationCode = code.split('/invite/').last;
      
      if (invitationCode.isNotEmpty) {
        // 直接显示行程规划
        _showInvitationDetails(invitationCode);
      } else {
        _showErrorAndReset('无效的邀请码');
      }
    } else {
      // 尝试直接作为邀请码处理
      if (code.length >= 8) {
        // 直接显示行程规划
        _showInvitationDetails(code);
      } else {
        _showErrorAndReset('无法识别的二维码格式');
      }
    }
  }
  
  // 处理邀请码并显示行程规划
  Future<void> _showInvitationDetails(String invitationCode) async {
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // 获取行程分享服务
      final sharingService = TripSharingService();
      
      // 获取邀请详情
      final invitationData = await sharingService.processReceivedInvitation(invitationCode);
      
      if (!mounted) return;
      
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      // 检查邀请是否有效
      if (invitationData.containsKey('trip_id')) {
        // 获取用户服务，检查登录状态
        final userService = UserService();
        
        // 自动接受邀请
        final success = await sharingService.acceptInvitation(invitationCode);
        
        if (success) {
          // 导航到行程详情页面
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailPage(userTripId: invitationData['trip_id']),
            ),
          );
        } else {
          // 检查是否是因为未登录而失败
          if (userService.currentUser == null) {
            // 用户未登录，显示提示并跳转到登录页面
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('请先登录后再接受邀请'), backgroundColor: Colors.orange),
            );
            
            // 保存邀请码到本地存储，以便登录后使用
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_invitation_code', invitationCode);
            
            // 导航到登录页面，并设置返回处理
            final loginResult = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
            
            // 如果登录成功，重新尝试接受邀请
            if (loginResult != null) {
              // 检查是否直接返回了true (简单的登录成功)
              if (loginResult == true) {
                // 重新获取存储的邀请码
                final savedCode = prefs.getString('pending_invitation_code');
                
                if (savedCode != null) {
                  // 清除存储的邀请码
                  await prefs.remove('pending_invitation_code');
                  
                  // 重新尝试处理邀请
                  await _processInvitationAfterLogin(savedCode, invitationData['trip_id']);
                }
              } 
              // 检查是否返回了包含邀请码的Map
              else if (loginResult is Map && loginResult['success'] == true) {
                final code = loginResult['pendingInvitationCode'];
                if (code != null) {
                  await _processInvitationAfterLogin(code.toString(), invitationData['trip_id']);
                }
              }
            }
          } else {
            _showErrorAndReset('接受邀请失败，请重试');
          }
        }
      } else {
        _showErrorAndReset('无效的邀请信息');
      }
    } catch (e) {
      if (!mounted) return;
      
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      _showErrorAndReset('处理邀请失败: $e');
    }
  }

  // 登录后处理邀请
  Future<void> _processInvitationAfterLogin(String invitationCode, String tripId) async {
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // 获取行程分享服务
      final sharingService = TripSharingService();
      
      // 接受邀请
      final success = await sharingService.acceptInvitation(invitationCode);
      
      if (!mounted) return;
      
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      if (success) {
        // 导航到行程详情页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailPage(userTripId: tripId),
          ),
        );
      } else {
        _showErrorAndReset('登录后接受邀请失败，请重试');
      }
    } catch (e) {
      if (!mounted) return;
      
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      _showErrorAndReset('处理邀请失败: $e');
    }
  }

  void _showErrorAndReset(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    
    // 延迟重置扫描状态，允许再次扫描
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanned = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描邀请二维码'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.off ? Icons.flash_off : Icons.flash_on
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                return Icon(
                  state == CameraFacing.front 
                    ? Icons.camera_front 
                    : Icons.camera_rear
                );
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              color: Colors.black.withOpacity(0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '将二维码放入框内，即可自动扫描',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '支持扫描途乐乐行程邀请二维码',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
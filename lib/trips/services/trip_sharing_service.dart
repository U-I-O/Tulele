import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/user_service.dart';
import '../../core/utils/auth_utils.dart';
import '../data/models/share_invitation_model.dart';

/// 行程分享服务，提供行程分享相关功能
class TripSharingService {
  final ApiService _apiService;
  
  TripSharingService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  /// 创建行程分享邀请
  Future<ShareInvitation> createShareInvitation({
    required String tripId,
    required String tripName,
    String? inviteeEmail,
    ShareInvitationType type = ShareInvitationType.edit,
    int expireDays = 7,
  }) async {
    String? userId;
    String? username;
    String? avatarUrl;
    
    try {
      // 尝试从UserService获取用户信息 - 更可靠的方式
      final userService = UserService();
      if (userService.currentUser != null) {
        userId = userService.currentUser!.id;
        username = userService.currentUser!.username;
        avatarUrl = userService.currentUser!.avatarUrl;
        
        // 同步到AuthUtils
        await AuthUtils.saveTokens(
          accessToken: await AuthUtils.getAccessToken() ?? '',
          refreshToken: await AuthUtils.getRefreshToken() ?? '',
          userId: userId,
          username: username,
          avatarUrl: avatarUrl,
        );
      } else {
        // 尝试从本地存储获取
        userId = await AuthUtils.getCurrentUserId();
        username = await AuthUtils.getCurrentUsername();
        avatarUrl = await AuthUtils.getCurrentAvatarUrl();
        
        // 如果本地存储也没有用户信息，抛出异常
        if (userId == null || username == null) {
          throw Exception('用户未登录');
        }
      }
      
      // 生成唯一邀请码
      final invitationCode = _generateInvitationCode();
      
      // 计算过期时间，以ISO 8601标准格式发送，明确指定UTC时区
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(Duration(days: expireDays));
      final expiresAtStr = expiresAt.toUtc().toIso8601String();
      
      // 准备邀请数据
      final invitationData = {
        'trip_id': tripId,
        'sender_user_id': userId,
        'sender_name': username,
        'invitee_email': inviteeEmail,
        'invitation_code': invitationCode,
        'type': type.name,
        'expires_at': expiresAtStr,
      };
      
      // 调用API创建邀请
      final responseData = await _apiService.createTripShareInvitation(tripId, invitationData);
      
      // 返回邀请模型
      return ShareInvitation.fromJson(responseData);
    } catch (e) {
      print('创建邀请失败: $e');
      throw Exception('生成二维码失败: $e');
    }
  }
  
  /// 获取行程所有分享邀请
  Future<List<ShareInvitation>> getTripInvitations(String tripId) async {
    final invitationsData = await _apiService.getTripInvitations(tripId);
    return invitationsData.map((data) => ShareInvitation.fromJson(data)).toList();
  }
  
  /// 取消行程邀请
  Future<bool> cancelInvitation(String tripId, String invitationId) async {
    return await _apiService.cancelInvitation(tripId, invitationId);
  }
  
  /// 分享行程链接
  Future<void> shareLink({
    required String tripId,
    required String tripName,
    BuildContext? context,
  }) async {
    // 创建分享邀请
    final invitation = await createShareInvitation(
      tripId: tripId,
      tripName: tripName,
    );
    
    // 构建分享文本和完整链接URL
    final String baseUrl = _apiService.getBaseUrl();
    final String fullShareLink = baseUrl + invitation.shareLink;
    final shareText = '我邀请你一起编辑"$tripName"，点击链接加入: $fullShareLink';
    
    // 调用系统分享
    await Share.share(shareText);
  }
  
  /// 复制分享链接到剪贴板
  Future<String> copyShareLink({
    required String tripId,
    required String tripName,
    BuildContext? context,
  }) async {
    // 创建分享邀请
    final invitation = await createShareInvitation(
      tripId: tripId,
      tripName: tripName,
    );
    
    // 构建完整链接URL
    final String baseUrl = _apiService.getBaseUrl();
    final String fullShareLink = baseUrl + invitation.shareLink;
    
    // 复制到剪贴板
    await Clipboard.setData(ClipboardData(text: fullShareLink));
    
    // 显示提示
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('链接已复制到剪贴板'))
      );
    }
    
    return fullShareLink;
  }
  
  /// 生成二维码并返回图片Widget
  Widget generateQrCodeWidget(String content) {
    return QrImageView(
      data: content,
      version: QrVersions.auto,
      size: 200,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
    );
  }
  
  /// 生成并分享二维码图片
  Future<void> shareQrCode({
    required String tripId,
    required String tripName,
    required BuildContext context,
  }) async {
    // 创建分享邀请
    final invitation = await createShareInvitation(
      tripId: tripId,
      tripName: tripName,
    );
    
    // 构建完整链接URL
    final String baseUrl = _apiService.getBaseUrl();
    final String fullShareLink = baseUrl + invitation.shareLink;
    
    // 显示二维码对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('扫描二维码加入行程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              child: QrImageView(
                data: fullShareLink,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '将二维码分享给朋友',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              // 分享链接
              Share.share('我邀请你一起编辑"$tripName"，点击链接加入: $fullShareLink');
              Navigator.pop(context);
            },
            child: const Text('分享链接'),
          ),
        ],
      ),
    );
  }
  
  /// 处理接收到的邀请
  Future<Map<String, dynamic>> processReceivedInvitation(String invitationCode) async {
    final invitationData = await _apiService.getInvitationByCode(invitationCode);
    return invitationData;
  }
  
  /// 接受邀请
  Future<bool> acceptInvitation(String invitationCode) async {
    try {
      // 获取UserService实例，用于检查用户是否登录
      final userService = UserService();
      Map<String, dynamic> acceptData;
      
      if (userService.currentUser != null) {
        // 使用UserService中的用户信息
        final userId = userService.currentUser!.id;
        final userName = userService.currentUser!.username;
        final avatarUrl = userService.currentUser!.avatarUrl;
        
        // 同步用户信息到AuthUtils
        await AuthUtils.saveTokens(
          accessToken: await AuthUtils.getAccessToken() ?? '',
          refreshToken: await AuthUtils.getRefreshToken() ?? '',
          userId: userId,
          username: userName,
          avatarUrl: avatarUrl,
        );
        
        acceptData = {
          'user_id': userId,
          'user_name': userName,
          'avatar_url': avatarUrl,
        };
      } else {
        // 尝试从AuthUtils获取用户信息
        final userId = await AuthUtils.getCurrentUserId();
        final userName = await AuthUtils.getCurrentUsername();
        final avatarUrl = await AuthUtils.getCurrentAvatarUrl();
        
        if (userId == null || userName == null) {
          // 用户未登录，保存邀请码以便登录后使用
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_invitation_code', invitationCode);
          
          print('接受邀请失败：用户未登录');
          return false;
        }
        
        acceptData = {
          'user_id': userId,
          'user_name': userName,
          'avatar_url': avatarUrl,
        };
      }
      
      // 调用API接受邀请
      return await _apiService.acceptInvitation(invitationCode, acceptData);
    } catch (e) {
      print('接受邀请出错: $e');
      return false;
    }
  }
  
  /// 拒绝邀请
  Future<bool> rejectInvitation(String invitationCode) async {
    return await _apiService.rejectInvitation(invitationCode);
  }
  
  /// 生成随机邀请码
  String _generateInvitationCode() {
    const uuid = Uuid();
    return uuid.v4().replaceAll('-', '').substring(0, 8);
  }
} 
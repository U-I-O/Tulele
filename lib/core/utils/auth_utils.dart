// lib/core/utils/auth_utils.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUtils {
  // 密钥常量
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _avatarUrlKey = 'avatar_url';
  
  // 获取访问令牌
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // 获取刷新令牌
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // 获取当前用户ID
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  // 获取当前用户名
  static Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }
  
  // 获取当前用户头像URL
  static Future<String?> getCurrentAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarUrlKey);
  }
  
  /// 获取当前登录用户的头像URL
  static Future<String?> getCurrentUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_avatar');
  }
  
  // 保存认证令牌和用户基本信息
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? username,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userIdKey, userId);
    
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }
    
    if (avatarUrl != null) {
      await prefs.setString(_avatarUrlKey, avatarUrl);
    }
    
    // 记录登录时间，用于判断令牌是否需要刷新
    await prefs.setInt('last_auth_time', DateTime.now().millisecondsSinceEpoch);
  }
  
  // 更新用户基本信息
  static Future<void> updateUserInfo({
    String? username,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }
    if (avatarUrl != null) {
      await prefs.setString(_avatarUrlKey, avatarUrl);
    }
  }
  
  // 清除认证令牌和用户信息
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_avatarUrlKey);
  }
}
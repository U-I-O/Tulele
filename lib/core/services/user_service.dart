import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  static const String _currentUserKey = 'current_user';
  
  static final UserService _instance = UserService._internal();
  
  // 单例模式
  factory UserService() => _instance;
  
  UserService._internal();
  
  // API服务
  final _apiService = ApiService();
  
  // 用户状态控制器
  final _userController = StreamController<User?>.broadcast();
  Stream<User?> get userStream => _userController.stream;
  
  // 当前登录用户
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  // 是否已初始化
  bool _initialized = false;
  
  // 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);
    
    if (currentUserJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(currentUserJson));
        _userController.add(_currentUser);
        
        // 尝试验证用户令牌是否有效
        try {
          final userData = await _apiService.getCurrentUser();
          _updateCurrentUser(User.fromBackend(userData['user']));
        } catch (e) {
          // 令牌可能已过期，尝试刷新
          final refreshed = await _apiService.refreshToken();
          if (refreshed) {
            try {
              final userData = await _apiService.getCurrentUser();
              _updateCurrentUser(User.fromBackend(userData['user']));
            } catch (e) {
              // 刷新失败，清除本地用户
              await logout();
            }
          } else {
            // 刷新令牌失败，清除本地用户
            await logout();
          }
        }
      } catch (e) {
        debugPrint('Failed to parse current user: $e');
      }
    }
    
    _initialized = true;
  }
  
  // 更新当前用户
  void _updateCurrentUser(User user) async {
    _currentUser = user;
    _userController.add(_currentUser);
    
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }
  
  // 注册新用户
  Future<User> register({
    required String email,
    required String username,
    required String password,
  }) async {
    // 调用API服务注册用户
    final result = await _apiService.register(
      username: username,
      email: email,
      password: password,
    );
    
    // 转换并保存用户信息
    final user = User.fromBackend(result['user']);
    _updateCurrentUser(user);
    
    return user;
  }
  
  // 用户登录
  Future<User> login({
    required String email,
    required String password,
  }) async {
    // 调用API服务登录
    final result = await _apiService.login(
      email: email,
      password: password,
    );
    
    // 转换并保存用户信息
    final user = User.fromBackend(result['user']);
    _updateCurrentUser(user);
    
    return user;
  }
  
  // 退出登录
  Future<void> logout() async {
    // 调用API服务登出
    await _apiService.logout();
    
    _currentUser = null;
    _userController.add(null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
  
  // 更新用户信息
  Future<User> updateUser(User updatedUser) async {
    // 调用API服务更新用户资料
    final result = await _apiService.updateProfile(updatedUser.toBackendJson());
    
    // 转换并保存用户信息
    final user = User.fromBackend(result['user']);
    _updateCurrentUser(user);
    
    return user;
  }
  
  // 添加共享行程
  Future<User> addSharedTrip(String tripId) async {
    if (_currentUser == null) {
      throw Exception('用户未登录');
    }
    
    final updatedUser = _currentUser!.addSharedTrip(tripId);
    return await updateUser(updatedUser);
  }
  
  // 移除共享行程
  Future<User> removeSharedTrip(String tripId) async {
    if (_currentUser == null) {
      throw Exception('用户未登录');
    }
    
    final updatedUser = _currentUser!.removeSharedTrip(tripId);
    return await updateUser(updatedUser);
  }
  
  // 修改已登录用户密码
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _apiService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
  
  // 发送重置密码验证码
  Future<void> sendPasswordResetCode(String email) async {
    await _apiService.sendVerificationCode(
      email: email,
      purpose: 'reset_password',
    );
  }
  
  // 验证邮箱验证码
  Future<bool> verifyEmailCode(String email, String code, String purpose) async {
    try {
      await _apiService.verifyEmailCode(
        email: email,
        code: code,
        purpose: purpose,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 重置密码
  Future<void> resetPassword(String email, String newPassword, String verificationCode) async {
    await _apiService.resetPassword(
      email: email,
      newPassword: newPassword,
      verificationCode: verificationCode,
    );
  }
  
  // 以下方法为兼容旧代码而保留，未来会逐步替换为新的API调用
  
  // 验证邮箱是否已注册
  Future<bool> isEmailRegistered(String email) async {
    try {
      // 使用API尝试检查邮箱是否存在
      // 这里可能需要后端提供一个专门的API端点
      // 临时实现，假设API还未实现此功能
      await Future.delayed(const Duration(milliseconds: 300));
      return false; // 默认假设邮箱未注册，避免阻断用户体验
    } catch (e) {
      debugPrint('检查邮箱是否注册时出错: $e');
      return false;
    }
  }
  
  // 生成随机验证码
  String generateVerificationCode() {
    // 生成6位数字验证码
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  // 释放资源
  void dispose() {
    _userController.close();
  }
} 
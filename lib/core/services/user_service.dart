import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static const String _usersKey = 'users_data';
  static const String _currentUserKey = 'current_user';
  
  static final UserService _instance = UserService._internal();
  
  // 单例模式
  factory UserService() => _instance;
  
  UserService._internal();
  
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
      } catch (e) {
        debugPrint('Failed to parse current user: $e');
      }
    }
    
    _initialized = true;
  }
  
  // 注册新用户
  Future<User> register({
    required String email,
    required String username,
    required String password,
  }) async {
    // 检查邮箱是否已被注册
    final existingUser = await getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('该邮箱已被注册');
    }
    
    // 创建新用户
    final newUser = User(
      id: _generateUuid(),
      email: email,
      username: username,
    );
    
    // 存储用户信息和密码
    await _saveUser(newUser, password);
    
    // 自动登录
    await login(email: email, password: password);
    
    return newUser;
  }
  
  // 用户登录
  Future<User> login({
    required String email,
    required String password,
  }) async {
    // 获取用户
    final user = await getUserByEmail(email);
    if (user == null) {
      throw Exception('邮箱或密码不正确');
    }
    
    // 验证密码
    final isPasswordValid = await _verifyPassword(email, password);
    if (!isPasswordValid) {
      throw Exception('邮箱或密码不正确');
    }
    
    // 设置当前用户
    _currentUser = user;
    _userController.add(_currentUser);
    
    // 保存当前用户到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    
    return user;
  }
  
  // 退出登录
  Future<void> logout() async {
    _currentUser = null;
    _userController.add(null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
  
  // 根据邮箱获取用户
  Future<User?> getUserByEmail(String email) async {
    final users = await _loadUsers();
    
    for (final userData in users.entries) {
      final user = User.fromJson(jsonDecode(userData.value['user']));
      if (user.email.toLowerCase() == email.toLowerCase()) {
        return user;
      }
    }
    
    return null;
  }
  
  // 更新用户信息
  Future<User> updateUser(User updatedUser) async {
    if (_currentUser == null) {
      throw Exception('用户未登录');
    }
    
    final users = await _loadUsers();
    final userEntry = users[updatedUser.id];
    
    if (userEntry == null) {
      throw Exception('用户不存在');
    }
    
    // 保存密码
    final password = userEntry['password'];
    
    // 更新用户信息
    await _saveUser(updatedUser, password);
    
    // 更新当前用户
    _currentUser = updatedUser;
    _userController.add(_currentUser);
    
    // 更新本地存储中的当前用户
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
    
    return updatedUser;
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
  
  // 生成随机验证码
  String generateVerificationCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString(); // 4位数验证码
  }
  
  // 验证邮箱是否已注册
  Future<bool> isEmailRegistered(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }
  
  // 修改密码
  Future<void> changePassword(String email, String newPassword) async {
    final user = await getUserByEmail(email);
    if (user == null) {
      throw Exception('用户不存在');
    }
    
    await _saveUser(user, newPassword);
  }
  
  // 加载所有用户
  Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) {
      return {};
    }
    
    try {
      return Map<String, dynamic>.from(jsonDecode(usersJson));
    } catch (e) {
      debugPrint('Failed to parse users data: $e');
      return {};
    }
  }
  
  // 保存用户信息和密码
  Future<void> _saveUser(User user, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers();
    
    users[user.id] = {
      'user': jsonEncode(user.toJson()),
      'password': password, // 实际项目中应该进行加密处理
    };
    
    await prefs.setString(_usersKey, jsonEncode(users));
  }
  
  // 验证密码
  Future<bool> _verifyPassword(String email, String password) async {
    final users = await _loadUsers();
    
    for (final userData in users.entries) {
      final user = User.fromJson(jsonDecode(userData.value['user']));
      if (user.email.toLowerCase() == email.toLowerCase()) {
        return userData.value['password'] == password;
      }
    }
    
    return false;
  }
  
  // 生成UUID
  String _generateUuid() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // 释放资源
  void dispose() {
    _userController.close();
  }
} 
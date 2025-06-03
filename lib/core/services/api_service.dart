import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal();

  // 后端API地址，实际开发中应从环境变量获取
  // Android模拟器访问本机地址是10.0.2.2，而不是localhost
  static const String baseUrl = 'http://192.168.75.89:5000/api';
  
  // 令牌存储键
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // 获取存储的令牌
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // 保存令牌
  Future<void> setTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // 清除令牌
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // 处理HTTP响应
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? '请求失败，请稍后再试';
        throw Exception(errorMessage);
      } catch (e) {
        // 如果响应体不是有效的JSON，则抛出一个通用错误
        throw Exception('服务器错误，请稍后再试。状态码: ${response.statusCode}');
      }
    }
  }

  // 构建请求头
  Future<Map<String, String>> _buildHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requireAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // 用户注册
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _buildHeaders(requireAuth: false),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);
    
    // 保存令牌
    if (data['access_token'] != null && data['refresh_token'] != null) {
      await setTokens(data['access_token'], data['refresh_token']);
    }
    
    return data;
  }

  // 用户登录
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _buildHeaders(requireAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = _handleResponse(response);
      
      // 保存令牌
      if (data['access_token'] != null && data['refresh_token'] != null) {
        await setTokens(data['access_token'], data['refresh_token']);
      }
      
      return data;
    } catch (e) {
      debugPrint('登录失败: $e');
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  // 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _buildHeaders(),
    );

    return _handleResponse(response);
  }

  // 更新用户资料
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/update-profile'),
      headers: await _buildHeaders(),
      body: jsonEncode(userData),
    );

    return _handleResponse(response);
  }

  // 修改密码
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: await _buildHeaders(),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  // 重置密码 (无需登录状态)
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String verificationCode,
  }) async {
    // 记录请求详情
    final requestBody = {
      'email': email,
      'new_password': newPassword,
      'verification_code': verificationCode,
    };
    
    debugPrint('发送重置密码请求: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: await _buildHeaders(requireAuth: false),
      body: jsonEncode(requestBody),
    );
    
    debugPrint('重置密码响应状态码: ${response.statusCode}, 响应体: ${response.body}');
    
    return _handleResponse(response);
  }

  // 发送验证码 (无需登录状态)
  Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
    required String purpose, // 'reset_password', 'register', etc.
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-verification-code'),
      headers: await _buildHeaders(requireAuth: false),
      body: jsonEncode({
        'email': email,
        'purpose': purpose,
      }),
    );

    return _handleResponse(response);
  }

  // 验证邮箱验证码 (无需登录状态)
  Future<Map<String, dynamic>> verifyEmailCode({
    required String email,
    required String code,
    required String purpose,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-code'),
      headers: await _buildHeaders(requireAuth: false),
      body: jsonEncode({
        'email': email,
        'code': code,
        'purpose': purpose,
      }),
    );

    return _handleResponse(response);
  }

  // 退出登录
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _buildHeaders(),
      );
    } catch (e) {
      debugPrint('退出登录时发生错误: $e');
    } finally {
      // 无论如何都清除本地令牌
      await clearTokens();
    }
  }

  // 刷新访问令牌（当令牌过期时使用）
  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    
    if (refreshToken == null) {
      return false;
    }
    
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: headers,
      );
      
      final data = _handleResponse(response);
      
      if (data['access_token'] != null) {
        await prefs.setString(_accessTokenKey, data['access_token']);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('刷新令牌失败: $e');
      return false;
    }
  }
} 
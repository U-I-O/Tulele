import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/user_service.dart';
import 'verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    _debounce?.cancel();
    super.dispose();
  }

  // 检查邮箱是否已注册
  Future<bool> _checkEmailRegistered(String email) async {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return false;
    
    setState(() {
      _isCheckingEmail = true;
    });
    
    try {
      final isRegistered = await UserService().isEmailRegistered(email);
      return isRegistered;
    } catch (e) {
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  // 处理邮箱输入变化
  void _handleEmailChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final isRegistered = await _checkEmailRegistered(value);
      if (isRegistered && mounted) {
        _formKey.currentState?.validate();
      }
    });
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 检查邮箱是否已被注册
      final isRegistered = await _checkEmailRegistered(_emailController.text);
      if (isRegistered) {
        throw Exception('该邮箱已被注册');
      }
      
      // 模拟生成验证码
      final verificationCode = UserService().generateVerificationCode();
      
      // 导航到验证页面
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerificationPage(
              email: _emailController.text,
              verificationCode: verificationCode,
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          ),
        );
        
        // 如果验证成功，返回登录页
        if (result == true && mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('注册新账号'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!.replaceAll('Exception: ', ''),
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Email field
                  CustomTextField(
                    label: '邮箱',
                    hint: '请输入有效的邮箱地址',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    suffixIcon: _isCheckingEmail ? Icons.sync : null,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _usernameFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱';
                      }
                      
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return '请输入有效的邮箱地址';
                      }
                      
                      // 邮箱格式验证通过，其他验证在提交时进行
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Username field
                  CustomTextField(
                    label: '用户名',
                    hint: '请设置您的用户名',
                    controller: _usernameController,
                    prefixIcon: Icons.person_outline,
                    focusNode: _usernameFocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      if (value.length < 2) {
                        return '用户名长度不能少于2位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Password field
                  CustomTextField(
                    label: '密码',
                    hint: '请设置登录密码',
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixIconPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    focusNode: _passwordFocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请设置密码';
                      }
                      if (value.length < 6) {
                        return '密码长度不能少于6位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm password field
                  CustomTextField(
                    label: '确认密码',
                    hint: '请再次输入密码',
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _isConfirmPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixIconPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    focusNode: _confirmPasswordFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendVerificationCode(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Register button
                  CustomButton(
                    text: '获取验证码',
                    onPressed: _sendVerificationCode,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),
                  
                  // Terms and conditions
                  Center(
                    child: Text(
                      '注册即表示您同意途乐乐的服务条款和隐私政策',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
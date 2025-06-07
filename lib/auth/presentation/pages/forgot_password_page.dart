import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/user_service.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void dispose() {
    _emailController.dispose();
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
      if (!isRegistered && mounted) {
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
      // 调用API发送验证码
      await UserService().sendPasswordResetCode(_emailController.text);
      
      // 导航到重置密码页面
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(
              email: _emailController.text,
              // 不再传入本地验证码，用户从邮件中获取验证码
            ),
          ),
        );
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
        title: const Text('忘记密码'),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Lock icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.lock_reset_outlined,
                      size: 48,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title and instructions
                  Text(
                    '重置密码',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '请输入您注册时使用的邮箱，我们将向该邮箱发送验证码',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
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
                    hint: '请输入您的注册邮箱',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    suffixIcon: _isCheckingEmail ? Icons.sync : null,
                    textInputAction: TextInputAction.done,
                    onChanged: _handleEmailChanged,
                    onSubmitted: (_) => _sendVerificationCode(),
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
                  const SizedBox(height: 32),
                  
                  // Send verification code button
                  CustomButton(
                    text: '获取验证码',
                    onPressed: _sendVerificationCode,
                    isLoading: _isLoading,
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
  import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/user_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  
  const ResetPasswordPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isVerifyingCode = false;
  bool _isResettingPassword = false;
  bool _isResending = false;
  bool _isCodeVerified = false;
  String? _errorMessage;
  Timer? _timer;
  int _resendCooldown = 60;
  bool _canResend = false;
  
  // 验证成功后的验证码
  String _verifiedCode = '';
  
  String get _enteredCode {
    return _codeControllers.map((c) => c.text).join();
  }

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }
  
  void _startResendCooldown() {
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }
  
  Future<void> _resendVerificationCode() async {
    if (!_canResend || _isResending) return;
    
    setState(() {
      _isResending = true;
    });
    
    try {
      // 调用API发送新验证码
      await UserService().sendPasswordResetCode(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('新的验证码已发送到您的邮箱'),
            backgroundColor: Colors.green[700],
          ),
        );
        
        // 开始新的倒计时
        _startResendCooldown();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '重新发送验证码失败，请稍后再试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }
  
  Future<void> _verifyCode() async {
    if (_enteredCode.length != 6) {
      setState(() {
        _errorMessage = '请输入完整的验证码';
      });
      return;
    }
    
    setState(() {
      _isVerifyingCode = true;
      _errorMessage = null;
    });
    
    try {
      // 通过API验证验证码
      bool isValid = await UserService().verifyEmailCode(
        widget.email, 
        _enteredCode, 
        'reset_password'
      );
      
      if (!isValid) {
        throw Exception('验证码不正确，请重新输入');
      }
      
      setState(() {
        _isCodeVerified = true;
        _verifiedCode = _enteredCode; // 保存验证通过的验证码
      });
      
      // 将焦点移到密码输入框
      _passwordFocusNode.requestFocus();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingCode = false;
        });
      }
    }
  }
  
  Future<void> _resetPassword() async {
    if (!_isCodeVerified) {
      setState(() {
        _errorMessage = '请先验证邮箱验证码';
      });
      return;
    }
    
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isResettingPassword = true;
      _errorMessage = null;
    });
    
    try {
      // 打印调试信息
      debugPrint('准备重置密码: 邮箱=${widget.email}, 验证码=${_verifiedCode}, 新密码长度=${_passwordController.text.length}');
      
      // 重置密码 (使用API) - 使用保存的已验证通过的验证码
      await UserService().resetPassword(
        widget.email,
        _passwordController.text,
        _verifiedCode,
      );
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('密码重置成功，请使用新密码登录'),
            backgroundColor: Colors.green[700],
          ),
        );
        
        // 返回到登录页
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('重置密码失败: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('重置密码'),
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
                  const SizedBox(height: 20),
                  
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
                  
                  // Step 1: Verify Code
                  Text(
                    '第一步: 验证邮箱',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '请输入发送至 ${widget.email} 的6位验证码',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Verification code input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 40,
                        height: 55,
                        child: TextFormField(
                          controller: _codeControllers[index],
                          focusNode: _codeFocusNodes[index],
                          enabled: !_isCodeVerified,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: _isCodeVerified
                                ? Colors.green[50]
                                : Colors.grey[100],
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _isCodeVerified
                                    ? Colors.green[300]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _isCodeVerified
                                    ? Colors.green[300]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _isCodeVerified
                                    ? Colors.green[500]!
                                    : theme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.green[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 5) {
                                _codeFocusNodes[index + 1].requestFocus();
                              } else {
                                FocusScope.of(context).unfocus();
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Verify code button / Resend code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Resend code
                      TextButton(
                        onPressed: _canResend && !_isCodeVerified
                            ? _resendVerificationCode
                            : null,
                        child: Text(
                          _canResend
                              ? '重新发送验证码'
                              : '重新发送 (${_resendCooldown}s)',
                          style: TextStyle(
                            color: (_canResend && !_isCodeVerified)
                                ? theme.primaryColor
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                      
                      // Verify button
                      if (!_isCodeVerified)
                        SizedBox(
                          width: 120,
                          child: CustomButton(
                            text: '验证',
                            onPressed: _verifyCode,
                            isLoading: _isVerifyingCode,
                            height: 40,
                          ),
                        ),
                        
                      // Verified indicator
                      if (_isCodeVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '已验证',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  // Step 2: Reset Password
                  Text(
                    '第二步: 设置新密码',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isCodeVerified
                          ? theme.colorScheme.onBackground
                          : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // New password field
                  CustomTextField(
                    label: '新密码',
                    hint: '请设置新密码',
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
                        return '请设置新密码';
                      }
                      if (value.length < 6) {
                        return '密码长度不能少于6位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm new password field
                  CustomTextField(
                    label: '确认新密码',
                    hint: '请再次输入新密码',
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
                    onSubmitted: (_) => _resetPassword(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认新密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Reset password button
                  CustomButton(
                    text: '重置密码',
                    onPressed: _isCodeVerified ? _resetPassword : () {
                      setState(() {
                        _errorMessage = '请先验证邮箱验证码';
                      });
                    },
                    isLoading: _isResettingPassword,
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
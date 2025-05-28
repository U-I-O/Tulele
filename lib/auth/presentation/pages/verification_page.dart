import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/user_service.dart';

class VerificationPage extends StatefulWidget {
  final String email;
  final String verificationCode;
  final String username;
  final String password;
  
  const VerificationPage({
    Key? key,
    required this.email,
    required this.verificationCode,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  Timer? _timer;
  int _resendCooldown = 60;
  bool _canResend = false;
  
  String get _enteredCode {
    return _controllers.map((c) => c.text).join();
  }

  @override
  void initState() {
    super.initState();
    
    // 开始倒计时
    _startResendCooldown();
    
    // 显示验证码 (实际项目中应该通过邮件发送)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showVerificationCodeDialog();
    });
  }
  
  void _showVerificationCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '模拟验证码',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '实际项目中，验证码应该通过邮件发送，这里是模拟效果。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '您的验证码是：',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.verificationCode,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('好的，我知道了'),
          ),
        ],
      ),
    );
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
      // 生成新的验证码
      final newVerificationCode = UserService().generateVerificationCode();
      
      // 在实际项目中，这里应该调用API发送邮件
      // 这里我们只是模拟
      await Future.delayed(const Duration(seconds: 1));
      
      // 显示新验证码
      if (mounted) {
        _showVerificationCodeDialog();
        
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
    if (_enteredCode.length != 4) {
      setState(() {
        _errorMessage = '请输入完整的验证码';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // 验证码验证
      if (_enteredCode != widget.verificationCode) {
        throw Exception('验证码不正确，请重新输入');
      }
      
      // 注册用户
      await UserService().register(
        email: widget.email,
        username: widget.username,
        password: widget.password,
      );
      
      // 注册成功，返回
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('验证邮箱'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Email icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title and instructions
                Text(
                  '验证您的邮箱',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '我们已向 ${widget.email} 发送了一个4位数的验证码',
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
                
                // Verification code input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
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
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 3) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              FocusScope.of(context).unfocus();
                            }
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                
                // Verify button
                CustomButton(
                  text: '验证',
                  onPressed: _verifyCode,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                
                // Resend code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '没有收到验证码? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _canResend ? _resendVerificationCode : null,
                      child: Text(
                        _canResend
                            ? '重新发送'
                            : '重新发送 (${_resendCooldown}s)',
                        style: TextStyle(
                          color: _canResend
                              ? theme.primaryColor
                              : Colors.grey[400],
                          fontWeight: _canResend ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
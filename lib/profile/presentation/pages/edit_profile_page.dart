import 'package:flutter/material.dart';
import '../../../core/services/user_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _userService = UserService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  User? get _currentUser => _userService.currentUser;
  String? _selectedAvatarUrl;
  
  // 预设头像列表
  final List<String> _avatarOptions = [
    'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    'https://images.unsplash.com/photo-1639149888905-fb39731f2e6c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTd8fGF2YXRhcnxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fGF2YXRhcnxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    'https://images.unsplash.com/photo-1607746882042-944635dfe10e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fGF2YXRhcnxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8YXZhdGFyfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
  ];

  @override
  void initState() {
    super.initState();
    
    // 初始化用户名和头像
    if (_currentUser != null) {
      _usernameController.text = _currentUser!.username;
      _selectedAvatarUrl = _currentUser!.avatarUrl;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
  
  // 保存用户资料
  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_currentUser == null) {
        throw Exception('用户未登录');
      }
      
      // 创建更新后的用户对象
      final updatedUser = _currentUser!.copyWith(
        username: _usernameController.text,
        avatarUrl: _selectedAvatarUrl,
      );
      
      // 更新用户信息
      await _userService.updateUser(updatedUser);
      
      // 更新成功，返回上一页
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Current avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        backgroundImage: _selectedAvatarUrl != null
                            ? NetworkImage(_selectedAvatarUrl!)
                            : null,
                        child: _selectedAvatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: theme.primaryColor,
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _showAvatarPicker(),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
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
                    const SizedBox(height: 20),
                  ],
                  
                  // Username field
                  CustomTextField(
                    label: '用户名',
                    hint: '请输入您的用户名',
                    controller: _usernameController,
                    prefixIcon: Icons.person_outline,
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
                  const SizedBox(height: 40),
                  
                  // Save button
                  CustomButton(
                    text: '保存',
                    onPressed: _saveProfile,
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
  
  // 显示头像选择器
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '选择头像',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  final avatarUrl = _avatarOptions[index];
                  final isSelected = avatarUrl == _selectedAvatarUrl;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAvatarUrl = avatarUrl;
                      });
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: NetworkImage(avatarUrl),
                        ),
                        if (isSelected)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('取消'),
              ),
            ),
          ],
        );
      },
    );
  }
} 
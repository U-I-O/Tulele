import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/auth_utils.dart';
import '../../services/trip_sharing_service.dart';
import '../../data/models/share_invitation_model.dart';

class TripInvitationPage extends StatefulWidget {
  final String invitationCode;

  const TripInvitationPage({Key? key, required this.invitationCode}) : super(key: key);

  @override
  State<TripInvitationPage> createState() => _TripInvitationPageState();
}

class _TripInvitationPageState extends State<TripInvitationPage> {
  final TripSharingService _sharingService = TripSharingService();
  
  bool _isLoading = true;
  bool _isProcessing = false;
  String _errorMessage = '';
  Map<String, dynamic>? _invitationData;

  @override
  void initState() {
    super.initState();
    _loadInvitationDetails();
  }

  Future<void> _loadInvitationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final invitationData = await _sharingService.processReceivedInvitation(widget.invitationCode);
      
      setState(() {
        _invitationData = invitationData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '无法加载邀请详情: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      // 确保用户已登录
      final String? userId = await AuthUtils.getCurrentUserId();
      final String? userName = await AuthUtils.getCurrentUsername();
      
      if (userId == null || userName == null) {
        // 用户未登录，跳转到登录页面
        // TODO: 实现跳转到登录页面的逻辑
        setState(() {
          _errorMessage = '请先登录后再接受邀请';
          _isProcessing = false;
        });
        return;
      }

      // 接受邀请
      final success = await _sharingService.acceptInvitation(widget.invitationCode);
      
      if (success) {
        // 成功接受邀请，跳转到相关行程页面
        if (!mounted) return;
        
        final tripId = _invitationData!['trip_info']['id'];
        final tripName = _invitationData!['trip_info']['name'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已成功加入行程: $tripName')),
        );
        
        // 跳转到行程详情页
        Navigator.pop(context); // 关闭当前页面
        // TODO: 替换为实际的行程导航逻辑
        // Navigator.pushReplacementNamed(context, '/trips/detail/$tripId');
      } else {
        setState(() {
          _errorMessage = '接受邀请失败';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '处理邀请时出错: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectInvitation() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      final success = await _sharingService.rejectInvitation(widget.invitationCode);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已拒绝邀请')),
          );
          Navigator.pop(context); // 返回上一页
        } else {
          setState(() {
            _errorMessage = '拒绝邀请失败';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '处理邀请时出错: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('行程邀请'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildInvitationView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            '出错了',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInvitationDetails,
            child: const Text('重试'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationView() {
    // 检查邀请是否有效
    final isExpired = _invitationData!['is_expired'] == true;
    final status = _invitationData!['status'];
    final isAlreadyAccepted = status == 'accepted';
    final isAlreadyRejected = status == 'rejected';
    final isInvitationValid = !isExpired && !isAlreadyAccepted && !isAlreadyRejected;

    // 获取邀请详情
    final senderName = _invitationData!['sender_name'];
    final String? tripName = _invitationData!['trip_info']?['name'] ?? '未命名行程';
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.group_add,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isInvitationValid
                        ? '邀请加入行程'
                        : isExpired
                            ? '邀请已过期'
                            : isAlreadyAccepted
                                ? '已加入行程'
                                : '已拒绝邀请',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isInvitationValid
                        ? '$senderName 邀请您加入行程 "$tripName"'
                        : isExpired
                            ? '该邀请已过期，请联系 $senderName 重新邀请'
                            : isAlreadyAccepted
                                ? '您已成功加入行程 "$tripName"'
                                : '您已拒绝加入行程 "$tripName"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (isInvitationValid) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _isProcessing ? null : _rejectInvitation,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('拒绝'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _acceptInvitation,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('接受邀请'),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('返回首页'),
                    ),
                  ],
                ],
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 
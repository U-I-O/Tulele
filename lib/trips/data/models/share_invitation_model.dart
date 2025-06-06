import 'package:flutter/foundation.dart';

/// 分享邀请类型
enum ShareInvitationType {
  /// 仅查看权限
  view,
  /// 编辑权限
  edit,
  /// 管理员权限
  admin,
}

/// 分享邀请状态
enum ShareInvitationStatus {
  /// 待接受
  pending,
  /// 已接受
  accepted,
  /// 已拒绝
  rejected,
  /// 已过期
  expired,
}

/// 行程分享邀请模型
class ShareInvitation {
  /// 分享邀请ID
  final String id;
  
  /// 关联的行程ID
  final String tripId;
  
  /// 邀请发送者ID
  final String senderUserId;
  
  /// 邀请发送者名称
  final String senderName;
  
  /// 被邀请者ID（可选，通过链接邀请时可能不存在）
  final String? inviteeUserId;
  
  /// 被邀请者邮箱（可选，通过链接邀请时可能不存在）
  final String? inviteeEmail;
  
  /// 邀请码，用于生成分享链接或二维码
  final String invitationCode;
  
  /// 分享邀请类型，表示被邀请人将获得的权限
  final ShareInvitationType type;
  
  /// 邀请状态
  final ShareInvitationStatus status;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 过期时间
  final DateTime expiresAt;
  
  /// 是否已过期
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// 分享链接
  String get shareLink => '/invite/$invitationCode';

  ShareInvitation({
    required this.id,
    required this.tripId,
    required this.senderUserId,
    required this.senderName,
    this.inviteeUserId,
    this.inviteeEmail,
    required this.invitationCode,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });
  
  /// 从JSON创建邀请对象
  factory ShareInvitation.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(String? dateString) {
      if (dateString == null) {
        return DateTime.now().toUtc();
      }
      
      try {
        // 确保日期时间包含时区信息
        String fixedDateString = dateString;
        if (!dateString.endsWith('Z') && !dateString.contains('+')) {
          fixedDateString = dateString + 'Z'; // 添加UTC标识
        }
        return DateTime.parse(fixedDateString).toUtc();
      } catch (e) {
        print('日期解析错误: $e, 日期字符串: $dateString');
        return DateTime.now().toUtc();
      }
    }
    
    // 从不同可能的键名获取值
    String getId() {
      if (json.containsKey('id')) {
        return json['id'].toString();
      } else if (json.containsKey('_id')) {
        return json['_id'].toString();
      }
      return '';
    }
    
    return ShareInvitation(
      id: getId(),
      tripId: json['trip_id'] ?? '',
      senderUserId: json['sender_user_id'] ?? '',
      senderName: json['sender_name'] ?? '未知用户',
      inviteeUserId: json['invitee_user_id'],
      inviteeEmail: json['invitee_email'],
      invitationCode: json['invitation_code'] ?? '',
      type: _parseInvitationType(json['type']),
      status: _parseInvitationStatus(json['status']),
      createdAt: parseDateTime(json['created_at']),
      expiresAt: parseDateTime(json['expires_at']),
    );
  }
  
  /// 解析邀请类型
  static ShareInvitationType _parseInvitationType(String? typeStr) {
    if (typeStr == null) return ShareInvitationType.view;
    
    try {
      return ShareInvitationType.values.byName(typeStr);
    } catch (e) {
      print('无效的邀请类型: $typeStr');
      return ShareInvitationType.view;
    }
  }
  
  /// 解析邀请状态
  static ShareInvitationStatus _parseInvitationStatus(String? statusStr) {
    if (statusStr == null) return ShareInvitationStatus.pending;
    
    try {
      return ShareInvitationStatus.values.byName(statusStr);
    } catch (e) {
      print('无效的邀请状态: $statusStr');
      return ShareInvitationStatus.pending;
    }
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'sender_user_id': senderUserId,
      'sender_name': senderName,
      'invitee_user_id': inviteeUserId,
      'invitee_email': inviteeEmail,
      'invitation_code': invitationCode,
      'type': type.name,
      'status': status.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }
  
  /// 创建一个副本，可选择性地覆盖某些字段
  ShareInvitation copyWith({
    String? id,
    String? tripId,
    String? senderUserId,
    String? senderName,
    ValueGetter<String?>? inviteeUserId,
    ValueGetter<String?>? inviteeEmail,
    String? invitationCode,
    ShareInvitationType? type,
    ShareInvitationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return ShareInvitation(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      senderUserId: senderUserId ?? this.senderUserId,
      senderName: senderName ?? this.senderName,
      inviteeUserId: inviteeUserId != null ? inviteeUserId() : this.inviteeUserId,
      inviteeEmail: inviteeEmail != null ? inviteeEmail() : this.inviteeEmail,
      invitationCode: invitationCode ?? this.invitationCode,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
} 
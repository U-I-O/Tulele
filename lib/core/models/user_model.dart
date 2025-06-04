import 'dart:convert';

class User {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final List<String> sharedTripIds; // 用户有权限编辑的行程ID列表
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    List<String>? sharedTripIds,
    DateTime? createdAt,
  }) : 
    this.sharedTripIds = sharedTripIds ?? [],
    this.createdAt = createdAt ?? DateTime.now();
  
  // 从JSON创建用户对象 (本地存储格式)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
      sharedTripIds: List<String>.from(json['sharedTripIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  
  // 从后端API返回的用户数据创建用户对象
  factory User.fromBackend(Map<String, dynamic> json) {
    return User(
      // 后端返回的MongoDB _id字段需要转换为前端的id
      id: json['_id'] ?? json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      // 可能需要根据后端字段结构调整
      sharedTripIds: json['shared_trip_ids'] != null 
          ? List<String>.from(json['shared_trip_ids'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
  
  // 转换为JSON (本地存储格式)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'sharedTripIds': sharedTripIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // 转换为发送给后端API的JSON格式
  Map<String, dynamic> toBackendJson() {
    return {
      // 通常不需要发送ID，后端会根据认证令牌识别用户
      'username': username,
      'avatar_url': avatarUrl,
      // 其他需要更新的字段根据API需求添加
    };
  }
  
  // 创建更新后的用户对象
  User copyWith({
    String? username,
    String? avatarUrl,
    List<String>? sharedTripIds,
  }) {
    return User(
      id: this.id,
      email: this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sharedTripIds: sharedTripIds ?? this.sharedTripIds,
      createdAt: this.createdAt,
    );
  }
  
  // 添加共享行程
  User addSharedTrip(String tripId) {
    if (!sharedTripIds.contains(tripId)) {
      final newSharedTrips = List<String>.from(sharedTripIds)..add(tripId);
      return copyWith(sharedTripIds: newSharedTrips);
    }
    return this;
  }
  
  // 移除共享行程
  User removeSharedTrip(String tripId) {
    if (sharedTripIds.contains(tripId)) {
      final newSharedTrips = List<String>.from(sharedTripIds)..remove(tripId);
      return copyWith(sharedTripIds: newSharedTrips);
    }
    return this;
  }
} 
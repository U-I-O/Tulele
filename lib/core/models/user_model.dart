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
  
  // 从JSON创建用户对象
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
  
  // 转换为JSON
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
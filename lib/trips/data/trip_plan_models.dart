import 'package:flutter/material.dart';

/// 旅行规划（TripPlan）：用于描述一个可被复用的旅行方案
class TripPlan {
  final String id;
  final String name;
  final String origin;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> tags;
  final List<TripDay> days;
  final String description;

  TripPlan({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.tags,
    required this.days,
    required this.description,
  });
}

/// 单日行程
class TripDay {
  final DateTime date;
  final List<TripActivity> activities;

  TripDay({required this.date, required this.activities});
}

/// 行程活动
class TripActivity {
  final String id;
  final String title;
  final String location;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String note;

  TripActivity({
    required this.id,
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.note,
  });
}

/// 用户旅行方案（UserTrip）：基于TripPlan，包含用户个性化内容
class UserTrip {
  final String id;
  final TripPlan plan;
  final List<UserTripMember> members;
  final List<UserTripMessage> messages;
  final List<UserTicket> tickets;
  final String status;
  final List<UserTripFeed> feeds;
  final List<UserTripNote> notes;

  UserTrip({
    required this.id,
    required this.plan,
    required this.members,
    required this.messages,
    required this.tickets,
    required this.status,
    required this.feeds,
    required this.notes,
  });
}

/// 用户成员
class UserTripMember {
  final String userId;
  final String name;
  final String avatarUrl;
  final String role;

  UserTripMember({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.role,
  });
}

/// 消息流（AI对话、推送等）
class UserTripMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String type; // ai, system, user

  UserTripMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}

/// 票务凭证
class UserTicket {
  final String id;
  final String type; // flight, train, hotel, etc.
  final String title;
  final String code;
  final DateTime date;
  final String details;

  UserTicket({
    required this.id,
    required this.type,
    required this.title,
    required this.code,
    required this.date,
    required this.details,
  });
}

/// 信息流（如AI推送、动态等）
class UserTripFeed {
  final String id;
  final String content;
  final DateTime timestamp;
  final String type;

  UserTripFeed({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}

/// 用户笔记
class UserTripNote {
  final String id;
  final String content;
  final DateTime timestamp;

  UserTripNote({
    required this.id,
    required this.content,
    required this.timestamp,
  });
}
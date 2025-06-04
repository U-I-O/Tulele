// lib/core/models/api_user_trip_model.dart
import 'dart:convert';
import './api_trip_plan_model.dart'; // 用于 planDetails 和转换

// Helper functions
List<ApiUserTrip> apiUserTripListFromJson(String str) =>
    List<ApiUserTrip>.from(json.decode(str).map((x) => ApiUserTrip.fromJson(x)));
String apiUserTripToJson(ApiUserTrip data) => json.encode(data.toJson());

class ApiUserTrip {
    String id; // Corresponds to _id

    String? planId; // Corresponds to plan_id (ObjectId as String)
    String? userTripNameOverride; // Corresponds to user_trip_name_override

    String creatorId;    // Corresponds to creator_id
    String? creatorName;  // Corresponds to creator_name
    String? creatorAvatar;// Corresponds to creator_avatar

    // UserTrip 自身的行程核心信息 (可以与 plan_id 指向的 TripPlan 不同)
    // 注意：ApiUserTrip 中不再直接有 name 字段，显示时用 userTripNameOverride 或 planDetails.name
    String? origin;
    String? destination;
    DateTime? startDate;
    DateTime? endDate;
    List<String> tags;
    String? description;
    String? coverImage; // 用户为此实例设置的封面
    List<ApiDayFromUserTrip> days;

    // UserTrip 特有的协作和辅助信息
    List<ApiMember> members;
    List<ApiMessage> messages;
    List<ApiTicket> tickets;
    // List<ApiFeed> feeds; // 根据你的要求移除了 feeds
    List<ApiNote> userNotes; // Corresponds to user_notes (行程级笔记)

    String publishStatus; // Corresponds to publish_status
    String travelStatus;  // Corresponds to travel_status

    // 用户对此行程实例的个人反馈
    double? userPersonalRating; // Corresponds to user_personal_rating
    String? userPersonalReview; // Corresponds to user_personal_review
    
    // 新增的审核流程字段
    String? submissionNotesToAdmin; // Corresponds to submission_notes_to_admin
    String? adminFeedbackOnReview;  // Corresponds to admin_feedback_on_review

    ApiTripPlan? planDetails; // 填充的原始 TripPlan 详细信息

    DateTime? createdAt; // Corresponds to created_at
    DateTime? updatedAt; // Corresponds to updated_at


    ApiUserTrip({
        required this.id,
        this.planId,
        this.userTripNameOverride,
        required this.creatorId,
        this.creatorName,
        this.creatorAvatar,
        this.origin,
        this.destination,
        this.startDate,
        this.endDate,
        required this.tags,
        this.description,
        this.coverImage,
        required this.days,
        required this.members,
        required this.messages,
        required this.tickets,
        required this.userNotes, //
        required this.publishStatus,
        required this.travelStatus,
        this.userPersonalRating,
        this.userPersonalReview,
        this.submissionNotesToAdmin,
        this.adminFeedbackOnReview,
        this.planDetails,
        this.createdAt,
        this.updatedAt,
    });

    // Getter for display name to simplify UI logic
    String get displayName => userTripNameOverride ?? planDetails?.name ?? '未命名行程';


    factory ApiUserTrip.fromJson(Map<String, dynamic> json) {
      ApiTripPlan? populatedPlanDetails;
      if (json["plan_details"] != null && json["plan_details"] is Map) {
          populatedPlanDetails = ApiTripPlan.fromJson(json["plan_details"] as Map<String, dynamic>);
      }

      return ApiUserTrip(
        id: json["_id"] ?? json["id"],
        planId: json["plan_id"],
        userTripNameOverride: json["user_trip_name_override"],
        creatorId: json["creator_id"] ?? '',
        creatorName: json["creator_name"],
        creatorAvatar: json["creator_avatar"],

        origin: json["origin"] ?? populatedPlanDetails?.origin,
        destination: json["destination"] ?? populatedPlanDetails?.destination,
        startDate: json["startDate"] == null 
            ? populatedPlanDetails?.startDate 
            : DateTime.tryParse(json["startDate"]),
        endDate: json["endDate"] == null 
            ? populatedPlanDetails?.endDate 
            : DateTime.tryParse(json["endDate"]),
        tags: json["tags"] == null 
            ? (populatedPlanDetails?.tags ?? []) 
            : List<String>.from(json["tags"]!.map((x) => x)),
        description: json["description"] ?? populatedPlanDetails?.description,
        coverImage: json["coverImage"] ?? populatedPlanDetails?.coverImage, // 优先用UserTrip的，再用planDetails的
        
        days: json["days"] == null 
            // 如果 UserTrip 本身没有 days，且 planDetails 存在，则从 planDetails 转换
            ? (populatedPlanDetails?.days.map((pd) => ApiDayFromUserTrip.fromPlanDay(pd)).toList() ?? [])
            : List<ApiDayFromUserTrip>.from(json["days"]!.map((x) => ApiDayFromUserTrip.fromJson(x))),

        members: json["members"] == null ? [] : List<ApiMember>.from(json["members"]!.map((x) => ApiMember.fromJson(x))),
        messages: json["messages"] == null ? [] : List<ApiMessage>.from(json["messages"]!.map((x) => ApiMessage.fromJson(x))),
        tickets: json["tickets"] == null ? [] : List<ApiTicket>.from(json["tickets"]!.map((x) => ApiTicket.fromJson(x))),
        userNotes: json["user_notes"] == null ? [] : List<ApiNote>.from(json["user_notes"]!.map((x) => ApiNote.fromJson(x))), // 对应 user_notes
        
        publishStatus: json["publish_status"] ?? 'draft',
        travelStatus: json["travel_status"] ?? 'planning',

        userPersonalRating: (json["user_personal_rating"] as num?)?.toDouble(),
        userPersonalReview: json["user_personal_review"],
        submissionNotesToAdmin: json["submission_notes_to_admin"],
        adminFeedbackOnReview: json["admin_feedback_on_review"],
        
        planDetails: populatedPlanDetails,

        createdAt: json["created_at"] == null ? null : DateTime.tryParse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.tryParse(json["updated_at"]),
      );
    }

    Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = {
            // "_id": id, // 通常不发送ID，除非是特定场景
            "plan_id": planId,
            "user_trip_name_override": userTripNameOverride,
            "creator_id": creatorId,
            // "creator_name": creatorName, // 后端填充
            // "creator_avatar": creatorAvatar, // 后端填充

            "origin": origin,
            "destination": destination,
            "startDate": startDate?.toIso8601String().substring(0,10),
            "endDate": endDate?.toIso8601String().substring(0,10),
            "tags": List<dynamic>.from(tags.map((x) => x)),
            "description": description,
            "coverImage": coverImage,
            "days": List<dynamic>.from(days.map((d) => d.toJson())), // 确保 ApiDayFromUserTrip 有 toJson
            
            "members": List<dynamic>.from(members.map((x) => x.toJson())),
            "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
            "tickets": List<dynamic>.from(tickets.map((x) => x.toJson())),
            "user_notes": List<dynamic>.from(userNotes.map((x) => x.toJson())), // 对应 user_notes
            
            "publish_status": publishStatus,
            "travel_status": travelStatus,

            "user_personal_rating": userPersonalRating,
            "user_personal_review": userPersonalReview,
            "submission_notes_to_admin": submissionNotesToAdmin,
            // "admin_feedback_on_review": adminFeedbackOnReview, // 通常不由前端发送
        };
        return data;
    }
}

// ApiDayFromUserTrip 对应 userTrips.days
class ApiDayFromUserTrip {
    int? dayNumber;    // Corresponds to day_number
    DateTime? date;    // Corresponds to date (用户行程的实际日期)
    String? title;     // Corresponds to title (当日主题，用户可改)
    String? description; // Corresponds to description (当日描述，用户可改)
    List<ApiActivityFromUserTrip> activities;
    String? notes;     // Corresponds to user_daily_notes (用户当日笔记)

    ApiDayFromUserTrip({
        this.dayNumber,
        this.date,
        this.title,
        this.description,
        required this.activities,
        this.notes,
    });

    factory ApiDayFromUserTrip.fromJson(Map<String, dynamic> json) => ApiDayFromUserTrip(
        dayNumber: json["day_number"],
        date: json["date"] == null ? null : DateTime.tryParse(json["date"]),
        title: json["title"],
        description: json["description"],
        activities: json["activities"] == null ? [] : List<ApiActivityFromUserTrip>.from(json["activities"]!.map((x) => ApiActivityFromUserTrip.fromJson(x))),
        notes: json["user_daily_notes"] ?? json["notes"], // 兼容旧 "notes" 和新 "user_daily_notes"
    );

    // 用于从 ApiPlanDay (来自模板) 转换为 UserTrip 的 Day 结构
    factory ApiDayFromUserTrip.fromPlanDay(ApiPlanDay planDay) => ApiDayFromUserTrip(
        dayNumber: planDay.dayNumber,
        date: planDay.date, // 模板的日期作为初始日期
        title: planDay.title, // 模板的当日主题作为初始主题
        description: planDay.description, // 模板的当日描述作为初始描述
        activities: planDay.activities.map((pa) => ApiActivityFromUserTrip.fromPlanActivity(pa)).toList(),
        notes: planDay.notes, // 模板的每日备注作为用户每日笔记的初始值
    );


    Map<String, dynamic> toJson() => {
        "day_number": dayNumber,
        "date": date?.toIso8601String().substring(0,10),
        "title": title,
        "description": description,
        "activities": List<dynamic>.from(activities.map((x) => x.toJson())),
        "user_daily_notes": notes, // 对应后端的 user_daily_notes
    };
}

// ApiActivityFromUserTrip 对应 userTrips.days.activities
class ApiActivityFromUserTrip {
    String? id;          // Corresponds to user_activity_id (后端生成，前端更新时可能需要)
    String? originalPlanActivityId; // Corresponds to original_plan_activity_id
    String title;
    String? description; // Corresponds to description (用户可改的活动描述)
    String? location;    // Corresponds to location_name
    String? address;
    // Map<String, double>? coordinates;
    String? startTime;
    String? endTime;
    String? transportation;
    int? durationMinutes;
    String? type;
    double? actualCost;   // Corresponds to actual_cost
    String? bookingInfo;  // Corresponds to booking_info (用户自己的)
    String? note;         // Corresponds to user_activity_notes
    String? userStatus;   // Corresponds to user_status ('todo', 'done', 'skipped')
    String? icon;

    ApiActivityFromUserTrip({
        this.id,
        this.originalPlanActivityId,
        required this.title,
        this.description,
        this.location,
        this.address,
        // this.coordinates,
        this.startTime,
        this.endTime,
        this.transportation,
        this.durationMinutes,
        this.type,
        this.actualCost,
        this.bookingInfo,
        this.note,
        this.userStatus,
        this.icon,
    });

    factory ApiActivityFromUserTrip.fromJson(Map<String, dynamic> json) => ApiActivityFromUserTrip(
        id: json["user_activity_id"] ?? json["id"],
        originalPlanActivityId: json["original_plan_activity_id"],
        title: json["title"] ?? '未命名活动',
        description: json["description"],
        location: json["location_name"] ?? json["location"],
        address: json["address"],
        // coordinates: json["coordinates"] == null ? null : Map<String, double>.from(json["coordinates"]),
        startTime: json["start_time"],
        endTime: json["end_time"],
        transportation: json["transportation"], 
        durationMinutes: json["duration_minutes"],
        type: json["type"],
        actualCost: (json["actual_cost"] as num?)?.toDouble(),
        bookingInfo: json["booking_info"],
        note: json["user_activity_notes"] ?? json["note"],
        userStatus: json["user_status"],
        icon: json["icon"],
    );
    
    // 用于从 ApiPlanActivity (来自模板) 转换为 UserTrip 的 Activity 结构
    factory ApiActivityFromUserTrip.fromPlanActivity(ApiPlanActivity planActivity) => ApiActivityFromUserTrip(
        // id: null, // UserTrip 中的活动应该有新的 user_activity_id，不由模板的 id 直接决定
        originalPlanActivityId: planActivity.id, // 记录它源自哪个模板活动
        title: planActivity.title,
        description: planActivity.description,
        location: planActivity.location,
        address: planActivity.address,
        // coordinates: planActivity.coordinates,
        startTime: planActivity.startTime,
        endTime: planActivity.endTime,
        transportation: planActivity.transportation,
        durationMinutes: planActivity.durationMinutes,
        type: planActivity.type,
        // actualCost: null, // 用户行程的实际花费初始为空
        // bookingInfo: planActivity.bookingInfo, // 可以继承模板的预订信息
        note: planActivity.note, // 模板的活动备注作为用户活动备注的初始值
        userStatus: 'todo', // 用户感知状态初始为待办
        icon: planActivity.icon,
    );

    Map<String, dynamic> toJson() => {
        "user_activity_id": id, // 发送时用 user_activity_id
        "original_plan_activity_id": originalPlanActivityId,
        "title": title,
        "description": description,
        "location_name": location, // 发送时用 location_name
        "address": address,
        // "coordinates": coordinates,
        "start_time": startTime,
        "end_time": endTime,
        "transportation": transportation,
        "duration_minutes": durationMinutes,
        "type": type,
        "actual_cost": actualCost,
        "booking_info": bookingInfo,
        "user_activity_notes": note, // 发送时用 user_activity_notes
        "user_status": userStatus,
        "icon": icon,
    };

    // *** 新增 copyWith 方法 ***
    ApiActivityFromUserTrip copyWith({
        String? id,
        String? originalPlanActivityId,
        String? title,
        String? description,
        String? location,
        String? address,
        // Map<String, double>? coordinates,
        String? startTime,
        String? endTime,
        String? transportation,
        int? durationMinutes,
        String? type,
        double? actualCost,
        String? bookingInfo,
        String? note,
        String? userStatus,
        String? icon,
    }) {
        return ApiActivityFromUserTrip(
            id: id ?? this.id,
            originalPlanActivityId: originalPlanActivityId ?? this.originalPlanActivityId,
            title: title ?? this.title,
            description: description ?? this.description,
            location: location ?? this.location,
            address: address ?? this.address,
            // coordinates: coordinates ?? this.coordinates,
            startTime: startTime ?? this.startTime,
            endTime: endTime ?? this.endTime,
            transportation: transportation ?? this.transportation,
            durationMinutes: durationMinutes ?? this.durationMinutes,
            type: type ?? this.type,
            actualCost: actualCost ?? this.actualCost,
            bookingInfo: bookingInfo ?? this.bookingInfo,
            note: note ?? this.note,
            userStatus: userStatus ?? this.userStatus,
            icon: icon ?? this.icon,
        );
    }
}

// --- ApiMember, ApiMessage, ApiTicket, ApiNote 类定义 ---
// 确保这些类的字段与后端 userTrips 集合中对应数组内对象的字段一致

class ApiMember {
    String userId;      // Corresponds to members.userId
    String name;        // Corresponds to members.name
    String? avatarUrl;  // Corresponds to members.avatarUrl
    String role;        // Corresponds to members.role
    DateTime? joinedAt; // Corresponds to members.joined_at

    ApiMember({
        required this.userId,
        required this.name,
        this.avatarUrl,
        required this.role,
        this.joinedAt,
    });

    factory ApiMember.fromJson(Map<String, dynamic> json) => ApiMember(
        userId: json["userId"] ?? '',
        name: json["name"] ?? '未知成员',
        avatarUrl: json["avatarUrl"],
        role: json["role"] ?? 'member',
        joinedAt: json["joined_at"] == null ? null : DateTime.tryParse(json["joined_at"]),
    );

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "name": name,
        "avatarUrl": avatarUrl,
        "role": role,
        "joined_at": joinedAt?.toIso8601String(),
    };
}

class ApiMessage {
    String? id;         // Corresponds to messages.message_id
    String senderId;    // Corresponds to messages.sender_id
    String? senderName; // Corresponds to messages.sender_name
    String content;
    String? type;       // Corresponds to messages.type
    DateTime? timestamp;

    ApiMessage({
        this.id,
        required this.senderId,
        this.senderName,
        required this.content,
        this.type,
        this.timestamp,
    });

    factory ApiMessage.fromJson(Map<String, dynamic> json) => ApiMessage(
        id: json["message_id"] ?? json["id"],
        senderId: json["sender_id"] ?? 'system',
        senderName: json["sender_name"],
        content: json["content"] ?? '',
        type: json["type"] ?? 'text',
        timestamp: json["timestamp"] == null ? null : DateTime.tryParse(json["timestamp"]),
    );

    Map<String, dynamic> toJson() => {
        "message_id": id,
        "sender_id": senderId,
        "sender_name": senderName,
        "content": content,
        "type": type,
        "timestamp": timestamp?.toIso8601String(),
    };
}

class ApiTicket {
    String? id;     // Corresponds to tickets.ticket_id
    String type;    // Corresponds to tickets.type
    String title;
    String? details; // Corresponds to tickets.details
    String? date;    // Corresponds to tickets.date (String "YYYY-MM-DD")
    String? fileUrl; // Corresponds to tickets.file_url
    String? notes;   // Corresponds to tickets.notes (用户备注)
    // 后端示例数据中 tickets 有个 code 字段，但第二次修订的表设计中没有，这里根据表设计来
    // String? code; 

    ApiTicket({
        this.id,
        required this.type,
        required this.title,
        this.details,
        this.date,
        this.fileUrl,
        this.notes,
        // this.code,
    });

    factory ApiTicket.fromJson(Map<String, dynamic> json) => ApiTicket(
        id: json["ticket_id"] ?? json["id"],
        type: json["type"] ?? '其他',
        title: json["title"] ?? '未命名票务',
        details: json["details"],
        date: json["date"],
        fileUrl: json["file_url"],
        notes: json["notes"],
        // code: json["code"],
    );

    Map<String, dynamic> toJson() => {
        "ticket_id": id,
        "type": type,
        "title": title,
        "details": details,
        "date": date, // "YYYY-MM-DD"
        "file_url": fileUrl,
        "notes": notes,
        // "code": code,
    };
}

class ApiNote { // 行程级笔记，对应 userTrips.user_notes
    String? id;         // Corresponds to user_notes.note_id
    String content;
    DateTime? createdAt;  // Corresponds to user_notes.created_at
    DateTime? updatedAt;  // Corresponds to user_notes.updated_at

    ApiNote({
        this.id, 
        required this.content, 
        this.createdAt, 
        this.updatedAt
    });

    factory ApiNote.fromJson(Map<String, dynamic> json) => ApiNote(
        id: json["note_id"] ?? json["id"],
        content: json["content"] ?? '',
        createdAt: json["created_at"] == null ? null : DateTime.tryParse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.tryParse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "note_id": id,
        "content": content,
        // "created_at": createdAt?.toIso8601String(), // 后端管理
        // "updated_at": updatedAt?.toIso8601String(), // 后端管理
    };
}

// ApiFeed 类被移除了，因为 userTrips 集合中不再包含 feeds 字段
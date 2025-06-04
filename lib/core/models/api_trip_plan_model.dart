// lib/core/models/api_trip_plan_model.dart
import 'dart:convert';

// Helper functions for list (de)serialization
ApiTripPlan apiTripPlanFromJson(String str) => ApiTripPlan.fromJson(json.decode(str));
String apiTripPlanToJson(ApiTripPlan data) => json.encode(data.toJson());

List<ApiTripPlan> apiTripPlanListFromJson(String str) =>
    List<ApiTripPlan>.from(json.decode(str).map((x) => ApiTripPlan.fromJson(x)));

class ApiTripPlan {
    String? id;         // Corresponds to _id
    String name;        // Corresponds to name
    String? creatorId;  // Corresponds to creator_id
    String? creatorName;// Corresponds to creator_name
    String? origin;
    String? destination;
    DateTime? startDate; // Corresponds to startDate (ISODate)
    DateTime? endDate;   // Corresponds to endDate (ISODate)
    int? durationDays; // Corresponds to duration_days
    List<String> tags;
    String? description;
    String? coverImage;
    List<ApiPlanDay> days;

    // Market-related fields from the new design
    double? platformPrice;      // Corresponds to platform_price
    double? averageRating;      // Corresponds to average_rating
    int? reviewCount;          // Corresponds to review_count
    int? salesVolume;          // Corresponds to sales_volume
    int? usageCount;           // Corresponds to usage_count
    int? version;              // Corresponds to version
    String? estimatedCostRange; // Corresponds to estimated_cost_range
    List<String>? suitability;   // Corresponds to suitability
    List<String>? highlights;    // Corresponds to highlights
    bool? isFeaturedOnMarket;  // Corresponds to is_featured_on_market

    DateTime? createdAt; // Corresponds to created_at
    DateTime? updatedAt; // Corresponds to updated_at

    ApiTripPlan({
        this.id,
        required this.name,
        this.creatorId,
        this.creatorName,
        this.origin,
        this.destination,
        this.startDate,
        this.endDate,
        this.durationDays,
        required this.tags,
        this.description,
        this.coverImage,
        required this.days,
        this.platformPrice,
        this.averageRating,
        this.reviewCount,
        this.salesVolume,
        this.usageCount,
        this.version,
        this.estimatedCostRange,
        this.suitability,
        this.highlights,
        this.isFeaturedOnMarket,
        this.createdAt,
        this.updatedAt,
    });

    factory ApiTripPlan.fromJson(Map<String, dynamic> json) {
      return ApiTripPlan(
        id: json["_id"], // MongoDB ID
        name: json["name"] ?? '未命名计划模板',
        creatorId: json["creator_id"],
        creatorName: json["creator_name"],
        origin: json["origin"],
        destination: json["destination"],
        startDate: json["startDate"] == null ? null : DateTime.tryParse(json["startDate"]),
        endDate: json["endDate"] == null ? null : DateTime.tryParse(json["endDate"]),
        durationDays: json["duration_days"],
        tags: json["tags"] == null ? [] : List<String>.from(json["tags"]!.map((x) => x)),
        description: json["description"],
        coverImage: json["coverImage"],
        days: json["days"] == null ? [] : List<ApiPlanDay>.from(json["days"]!.map((x) => ApiPlanDay.fromJson(x))),
        
        platformPrice: (json["platform_price"] as num?)?.toDouble(),
        averageRating: (json["average_rating"] as num?)?.toDouble(),
        reviewCount: json["review_count"],
        salesVolume: json["sales_volume"],
        usageCount: json["usage_count"],
        version: json["version"],
        estimatedCostRange: json["estimated_cost_range"],
        suitability: json["suitability"] == null ? null : List<String>.from(json["suitability"]!.map((x) => x)),
        highlights: json["highlights"] == null ? null : List<String>.from(json["highlights"]!.map((x) => x)),
        isFeaturedOnMarket: json["is_featured_on_market"],

        createdAt: json["created_at"] == null ? null : DateTime.tryParse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.tryParse(json["updated_at"]),
      );
    }

    Map<String, dynamic> toJson() => {
        // "_id": id, // 通常不由前端发送，除非是特定更新场景
        "name": name,
        "creator_id": creatorId,
        // "creator_name": creatorName, // 通常由后端根据 creator_id 填充，发送时可省略
        "origin": origin,
        "destination": destination,
        "startDate": startDate?.toIso8601String().substring(0,10), // 发送 YYYY-MM-DD
        "endDate": endDate?.toIso8601String().substring(0,10),   // 发送 YYYY-MM-DD
        "duration_days": durationDays,
        "tags": List<dynamic>.from(tags.map((x) => x)),
        "description": description,
        "coverImage": coverImage,
        "days": List<dynamic>.from(days.map((x) => x.toJson())),

        "platform_price": platformPrice,
        "average_rating": averageRating, // 这些字段通常由后端更新，前端发送时可能不需要
        "review_count": reviewCount,     // 同上
        "sales_volume": salesVolume,     // 同上
        "usage_count": usageCount,       // 同上
        "version": version,
        "estimated_cost_range": estimatedCostRange,
        "suitability": suitability == null ? null : List<dynamic>.from(suitability!.map((x) => x)),
        "highlights": highlights == null ? null : List<dynamic>.from(highlights!.map((x) => x)),
        "is_featured_on_market": isFeaturedOnMarket,
        // "created_at": createdAt?.toIso8601String(), // 后端自动管理
        // "updated_at": updatedAt?.toIso8601String(), // 后端自动管理
    };
}

class ApiPlanDay { // 对应 tripPlans.days
    int? dayNumber;    // Corresponds to day_number
    String? title;     // Corresponds to title (当日主题)
    String? description; // Corresponds to description (当日描述)
    DateTime? date;    // 模板中的参考日期 (虽然数据库中 days 结构没直接放 date, 但模型中保留方便处理)
                       // 后端实际存储时，可能是根据 TripPlan 的 startDate 和 day_number 计算
    List<ApiPlanActivity> activities;
    String? notes;     // Corresponds to daily_notes (模板的当日备注)

    ApiPlanDay({
        this.dayNumber,
        this.title,
        this.description,
        this.date, 
        required this.activities,
        this.notes,
    });

    factory ApiPlanDay.fromJson(Map<String, dynamic> json) => ApiPlanDay(
        dayNumber: json["day_number"],
        title: json["title"],
        description: json["description"],
        date: json["date"] == null ? null : DateTime.tryParse(json["date"]), // 假设后端在days内也返回了具体date
        activities: json["activities"] == null ? [] : List<ApiPlanActivity>.from(json["activities"]!.map((x) => ApiPlanActivity.fromJson(x))),
        notes: json["daily_notes"] ?? json["notes"], // 兼容旧的 "notes" 和新的 "daily_notes"
    );

    Map<String, dynamic> toJson() => {
        "day_number": dayNumber,
        "title": title,
        "description": description,
        "date": date?.toIso8601String().substring(0,10), // 如果需要发送日期
        "activities": List<dynamic>.from(activities.map((x) => x.toJson())),
        "daily_notes": notes, // 对应后端的 daily_notes
    };
}

class ApiPlanActivity { // 对应 tripPlans.days.activities
    String? id;             // Corresponds to activity_id (后端生成，前端发送更新时可能需要)
    String title;
    String? description;    // Corresponds to description (活动描述)
    String? location;       // Corresponds to location_name
    String? address;        // Corresponds to address
    // Map<String, double>? coordinates; // Example: {"latitude": 39.9, "longitude": 116.3}
    String? startTime;      // Corresponds to start_time
    String? endTime;        // Corresponds to end_time
    String? transportation;
    int? durationMinutes;   // Corresponds to duration_minutes
    String? type;           // Corresponds to type
    double? estimatedCost;  // Corresponds to estimated_cost
    String? bookingInfo;    // Corresponds to booking_info
    String? note;           // Corresponds to activity_notes
    String? icon;           // Corresponds to icon

    ApiPlanActivity({
        this.id,
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
        this.estimatedCost,
        this.bookingInfo,
        this.note,
        this.icon,
    });

    factory ApiPlanActivity.fromJson(Map<String, dynamic> json) => ApiPlanActivity(
        id: json["activity_id"] ?? json["id"],
        title: json["title"] ?? '未命名活动',
        description: json["description"],
        location: json["location_name"] ?? json["location"],
        address: json["address"],
        // coordinates: json["coordinates"] == null ? null : Map<String,double>.from(json["coordinates"]),
        startTime: json["start_time"],
        endTime: json["end_time"],
        transportation: json["transportation"],
        durationMinutes: json["duration_minutes"],
        type: json["type"],
        estimatedCost: (json["estimated_cost"] as num?)?.toDouble(),
        bookingInfo: json["booking_info"],
        note: json["activity_notes"] ?? json["note"], // 兼容旧 "note" 和新 "activity_notes"
        icon: json["icon"],
    );

    Map<String, dynamic> toJson() => {
        "activity_id": id, // 发送时用 activity_id
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
        "estimated_cost": estimatedCost,
        "booking_info": bookingInfo,
        "activity_notes": note, // 发送时用 activity_notes
        "icon": icon,
    };
}
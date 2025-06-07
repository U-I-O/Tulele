// lib/core/models/api_user_trip_model.dart
import 'dart:convert';
import './api_trip_plan_model.dart'; // 用于 planDetails 和转换
import 'dart:math';
import 'package:intl/intl.dart';
import '../../trips/services/geo_service.dart';
import 'package:flutter/foundation.dart';

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

    /// 从AI生成的文本解析行程
    factory ApiUserTrip.fromAiGeneratedPlan(
      String planText,
      {
        String? name,
        String? creatorId,
        String? destination,
      }
    ) {
      // 预设值初始化
      DateTime now = DateTime.now();
      String generatedDestination = destination ?? '';
      String description = '';
      List<ApiDayFromUserTrip> parsedDays = [];
      List<String> parsedTags = [];
      
      // 解析AI生成文本
      List<String> lines = planText.split('\n');
      
      // 查找目的地
      for (String line in lines) {
        if (line.contains('兰州') || line.contains('城市') || line.contains('旅行')) {
          generatedDestination = '兰州';
          break;
        }
      }
      
      // 提取描述
      for (String line in lines) {
        if (line.contains('日游') || line.contains('天行程') || line.contains('深度')) {
          description = line.trim();
          break;
        }
      }
      
      if (description.isEmpty && lines.isNotEmpty) {
        // 用第一行或者合成描述
        description = '基于AI生成的${generatedDestination}行程方案';
      }
      
      // 查找行程总天数
      int totalDays = 1;  // 默认至少一天
      RegExp dayRegex = RegExp(r'(\d+)\s*[天日]游');
      for (String line in lines) {
        var match = dayRegex.firstMatch(line);
        if (match != null) {
          totalDays = int.tryParse(match.group(1) ?? '1') ?? 1;
          if (totalDays > 1) break;  // 找到多日游就停止
        }
      }
      
      print('检测到AI行程总天数: $totalDays');
      
      // 提取每天的内容块
      Map<int, List<String>> dayContentBlocks = {};
      // 将文本分割成每天的块
      int currentDay = 0;
      List<String> currentDayLines = [];
      
      // 首先，确定每一天的内容块
      for (String line in lines) {
        // 使用更强的正则表达式匹配各种"第X天"格式
        RegExp dayStartRegex = RegExp(r'第\s*(\d+)\s*[天日]|Day\s*(\d+)|(\d+)[天日]行程');
        var dayMatch = dayStartRegex.firstMatch(line);
        
        if (dayMatch != null) {
          // 找到新的一天
          String dayNumStr = dayMatch.group(1) ?? dayMatch.group(2) ?? dayMatch.group(3) ?? '1';
          int dayNum = int.tryParse(dayNumStr) ?? 1;
          
          // 如果当前已经在记录某天，保存之前的内容
          if (currentDay > 0 && currentDayLines.isNotEmpty) {
            dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
          }
          
          // 开始记录新的一天
          currentDay = dayNum;
          currentDayLines = [line]; // 开始新的一天，包含当前行
        } else if (currentDay > 0) {
          // 如果已经确定了当前天，继续添加内容
          currentDayLines.add(line);
        }
      }
      
      // 保存最后一天的内容
      if (currentDay > 0 && currentDayLines.isNotEmpty) {
        dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
      }
      
      // 如果没有按天分割成功，尝试其他分割方法
      if (dayContentBlocks.isEmpty) {
        // 先尝试更宽松的日期模式匹配
        currentDay = 0;
        currentDayLines = [];
        
        for (String line in lines) {
          if (line.contains('第1天') || line.contains('Day 1') || line.contains('第一天') || 
              (currentDay == 0 && (line.contains('早上') || line.contains('上午') || line.contains('酒店')))) {
            if (currentDay > 0 && currentDayLines.isNotEmpty) {
              dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
            }
            currentDay = 1;
            currentDayLines = [line];
          } else if ((line.contains('第2天') || line.contains('Day 2') || line.contains('第二天')) && currentDay >= 1) {
            if (currentDayLines.isNotEmpty) {
              dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
            }
            currentDay = 2;
            currentDayLines = [line];
          } else if ((line.contains('第3天') || line.contains('Day 3') || line.contains('第三天')) && currentDay >= 2) {
            if (currentDayLines.isNotEmpty) {
              dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
            }
            currentDay = 3;
            currentDayLines = [line];
          } else if ((line.contains('第4天') || line.contains('Day 4') || line.contains('第四天')) && currentDay >= 3) {
            if (currentDayLines.isNotEmpty) {
              dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
            }
            currentDay = 4;
            currentDayLines = [line];
          } else if ((line.contains('第5天') || line.contains('Day 5') || line.contains('第五天')) && currentDay >= 4) {
            if (currentDayLines.isNotEmpty) {
              dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
            }
            currentDay = 5;
            currentDayLines = [line];
          } else if (currentDay > 0) {
            currentDayLines.add(line);
          }
        }
        
        // 保存最后一天的内容
        if (currentDay > 0 && currentDayLines.isNotEmpty) {
          dayContentBlocks[currentDay] = List<String>.from(currentDayLines);
        }
      }
      
      // 如果仍然没有分割成功，强制分割为等长的天数
      if (dayContentBlocks.isEmpty && totalDays > 1) {
        print('没有检测到明确的天数分割，强制分割为 $totalDays 天');
        int linesPerDay = (lines.length / totalDays).ceil();
        for (int day = 1; day <= totalDays; day++) {
          int startIdx = (day - 1) * linesPerDay;
          int endIdx = day * linesPerDay;
          if (endIdx > lines.length) endIdx = lines.length;
          
          if (startIdx < lines.length) {
            List<String> dayLines = lines.sublist(startIdx, endIdx);
            dayContentBlocks[day] = dayLines;
          }
        }
      }
      
      // 分析每日行程和活动
      Map<int, List<ApiActivityFromUserTrip>> activitiesByDay = {};
      Map<int, String> dayTitles = {};
      Map<int, String> dayDescriptions = {};
      
      // 添加函数用于生成更自然的时间
      int _generateRandomMinute() {
        // 生成更自然的时间，如8:00, 8:15, 8:30, 8:45，而不是8:37这样奇怪的时间
        List<int> naturalMinutes = [0, 15, 30, 45];
        return naturalMinutes[Random().nextInt(naturalMinutes.length)];
      }

      // 处理每一天的内容
      dayContentBlocks.forEach((day, dayLines) {
        // 提取标题和描述
        String title = '第${day}天：${generatedDestination}游';
        String description = '';
        
        if (dayLines.isNotEmpty) {
          // 提取更有特色的标题
          RegExp titleRegex = RegExp(r'主题.*:|.*探访|.*体验|.*之旅', caseSensitive: false);
          for (String line in dayLines) {
            final titleMatch = titleRegex.firstMatch(line);
            if (titleMatch != null) {
              title = '第${day}天：${titleMatch.group(0)!.replaceAll("主题：", "").trim()}';
              break;
            }
          }

          // 第一行通常是标题
          if (dayLines.first.contains('第${day}天') || dayLines.first.contains('Day ${day}')) {
            title = dayLines.first.trim();
          }
          
          // 尝试提取描述
          for (String line in dayLines) {
            if (line.length > 10 && !line.contains('**') && !line.contains('--')) {
              description = line.trim();
              break;
            }
          }
        }
        
        dayTitles[day] = title;
        dayDescriptions[day] = description;
        
        // 提取活动
        List<ApiActivityFromUserTrip> dayActivities = [];
        
        // 生成这一天的起始时间（比较合理的早晨时间）
        int startHour = 7 + Random().nextInt(3); // 7:00-9:59之间
        int startMinute = _generateRandomMinute();
        DateTime currentTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
        
        // 遍历每一行，提取活动
        bool foundActivity = false;
        for (String line in dayLines) {
          // 匹配时间段格式，如 "09:00"或"**09:00**"
          RegExp timeRegex = RegExp(r'(\d{1,2}[:：]\d{2})');
          var timeMatches = timeRegex.allMatches(line).toList();
          
          if (timeMatches.isNotEmpty) {
            // 找到了时间格式
            String timeText = line.substring(timeMatches.first.start, timeMatches.first.end).replaceAll('：', ':');
            List<String> timeParts = timeText.split(':');
            int activityHour = int.tryParse(timeParts[0]) ?? currentTime.hour;
            int activityMinute = int.tryParse(timeParts[1]) ?? currentTime.minute;
            
            // 更新当前时间
            currentTime = DateTime(now.year, now.month, now.day, activityHour, activityMinute);
            
            // 提取活动标题
            String activityTitle = line.replaceAll(timeText, '').replaceAll('**', '').trim();
            if (activityTitle.startsWith("-")) {
              activityTitle = activityTitle.substring(1).trim();
            }
            
            // 默认活动时长为1-2小时
            int activityDuration = 60 + Random().nextInt(60);
            
            // 根据活动类型调整时长
            if (activityTitle.contains("餐") || activityTitle.contains("吃饭")) {
              activityDuration = 60 + Random().nextInt(30); // 用餐时间约1-1.5小时
            } else if (activityTitle.contains("游览") || activityTitle.contains("参观")) {
              activityDuration = 120 + Random().nextInt(60); // 游览时间约2-3小时
            }
            
            // 计算结束时间
            DateTime endTime = currentTime.add(Duration(minutes: activityDuration));
            String endTimeText = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
            
            // 提取地点信息（在当前行或后续几行中寻找）
            String location = "";
            String description = "";

            
            int lineIndex = dayLines.indexOf(line);
            for (int j = lineIndex; j < lineIndex + 3 && j < dayLines.length; j++) {
              String checkLine = dayLines[j];
              if (checkLine.contains('地点') && checkLine.contains(':')) {
                location = checkLine.split(':')[1].trim();
              } else if (checkLine.contains('描述') && checkLine.contains(':')) {
                description = checkLine.split(':')[1].trim();
              }
            }
            
            // 如果没有找到地点，生成一个默认地点
            if (location.isEmpty && activityTitle.isNotEmpty) {
              if (activityTitle.contains("餐")) {
                location = "$generatedDestination美食街";
              } else if (activityTitle.contains("景点") || activityTitle.contains("游览")) {
                location = "$generatedDestination${activityTitle.replaceAll("游览", "").replaceAll("参观", "").trim()}景区";
              } else {
                location = "$generatedDestination${activityTitle.split(" ").first}";
              }
            }
            
            // 创建活动对象
            ApiActivityFromUserTrip activity = ApiActivityFromUserTrip(
              title: activityTitle,
              description: description,
              location: location,
              startTime: timeText,
              endTime: endTimeText,
              type: _determineActivityType(activityTitle),
              userStatus: 'todo',
              // 添加经纬度字段，后续可以通过地理编码服务获取
              coordinates: null, // 初始为空，需要在后续异步获取
              // 如果不是第一个活动，添加交通方式和时间
              transportation: dayActivities.isEmpty ? null : "步行",
              durationMinutes: dayActivities.isEmpty ? null : 15 + Random().nextInt(30),
            );
            
            dayActivities.add(activity);
            foundActivity = true;
            
            // 如果有地点名称，可以尝试在后台异步获取经纬度
            // TODO: 实现地理编码服务调用或使用百度地图API获取经纬度
            // 可以使用以下伪代码实现：
            /*
            if (location.isNotEmpty) {
              getLocationCoordinates(location).then((coordinates) {
                if (coordinates != null) {
                  activity.coordinates = {
                    "latitude": coordinates.latitude,
                    "longitude": coordinates.longitude
                  };
                }
              });
            }
            */
            
            // 更新当前时间为结束时间加30分钟（活动之间的缓冲）
            currentTime = endTime.add(const Duration(minutes: 30));
          } else if (line.contains('兰州') || line.contains('参观') || 
              line.contains('游览') || line.contains('购物') || line.contains('午餐') || 
              line.contains('晚餐') || line.contains('用餐')) {
            
            // 没有时间的活动，根据当前时间设置
            String activityTitle = line.trim();
            
            // 根据活动类型设置合理的时间
            if (activityTitle.contains("早餐")) {
              currentTime = DateTime(now.year, now.month, now.day, 8, 0);
            } else if (activityTitle.contains("午餐")) {
              currentTime = DateTime(now.year, now.month, now.day, 12, 30);
            } else if (activityTitle.contains("晚餐")) {
              currentTime = DateTime(now.year, now.month, now.day, 18, 30);
            }
            
            // 默认活动时长
            int activityDuration = 60 + Random().nextInt(60);
            
            // 根据活动调整时长
            if (activityTitle.contains("餐")) {
              activityDuration = 60 + Random().nextInt(30); // 用餐时间约1-1.5小时
            } else if (activityTitle.contains("游览") || activityTitle.contains("参观")) {
              activityDuration = 120 + Random().nextInt(60); // 游览时间约2-3小时
            }
            
            // 计算结束时间
            DateTime endTime = currentTime.add(Duration(minutes: activityDuration));
            
            // 创建活动对象
            ApiActivityFromUserTrip activity = ApiActivityFromUserTrip(
              title: activityTitle,
              startTime: "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}",
              endTime: "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}",
              type: _determineActivityType(activityTitle),
              userStatus: 'todo',
              // 如果不是第一个活动，添加交通方式和时间
              transportation: dayActivities.isEmpty ? null : "步行",
              durationMinutes: dayActivities.isEmpty ? null : 15 + Random().nextInt(30),
            );
            
            dayActivities.add(activity);
            foundActivity = true;
            
            // 更新当前时间为结束时间加30分钟（活动之间的缓冲）
            currentTime = endTime.add(const Duration(minutes: 30));
          }
        }
        
        // 如果这一天没有找到活动，创建默认活动
        if (!foundActivity) {
          List<ApiActivityFromUserTrip> defaultActivities = [];
          
          // 早餐 (8:00-9:00)
          defaultActivities.add(ApiActivityFromUserTrip(
            title: "酒店早餐",
            description: "享用酒店早餐，开始美好的一天",
            location: "$generatedDestination酒店餐厅",
            startTime: "08:00",
            endTime: "09:00",
            type: "food",
            userStatus: "todo",
          ));
          
          // 上午活动 (9:30-12:00)
          defaultActivities.add(ApiActivityFromUserTrip(
            title: "$generatedDestination景点游览",
            description: "游览$generatedDestination著名景点",
            location: "$generatedDestination景区",
            startTime: "09:30",
            endTime: "12:00",
            type: "attraction",
            userStatus: "todo",
            transportation: "出租车",
            durationMinutes: 20,
          ));
          
          // 午餐 (12:30-14:00)
          defaultActivities.add(ApiActivityFromUserTrip(
            title: "当地特色午餐",
            description: "品尝$generatedDestination特色美食",
            location: "$generatedDestination美食街",
            startTime: "12:30",
            endTime: "14:00",
            type: "food",
            userStatus: "todo",
            transportation: "步行",
            durationMinutes: 15,
          ));
          
          // 下午活动 (14:30-17:30)
          defaultActivities.add(ApiActivityFromUserTrip(
            title: "文化体验活动",
            description: "体验$generatedDestination特色文化活动",
            location: "$generatedDestination文化中心",
            startTime: "14:30",
            endTime: "17:30",
            type: "activity",
            userStatus: "todo",
            transportation: "公交",
            durationMinutes: 25,
          ));
          
          // 晚餐 (18:00-19:30)
          defaultActivities.add(ApiActivityFromUserTrip(
            title: "$generatedDestination特色晚餐",
            description: "享用当地特色晚餐",
            location: "$generatedDestination特色餐厅",
            startTime: "18:00",
            endTime: "19:30",
            type: "food",
            userStatus: "todo",
            transportation: "出租车",
            durationMinutes: 15,
          ));
          
          dayActivities.addAll(defaultActivities);
        }
        
        activitiesByDay[day] = dayActivities;
      });
      
      // 辅助方法：生成随机交通方式
      String _generateRandomTransportation() {
        List<String> transportModes = ["步行", "公交", "出租车", "地铁", "共享单车"];
        return transportModes[Random().nextInt(transportModes.length)];
      }
      
      // 确保至少有一天
      if (dayContentBlocks.isEmpty) {
        // 如果没有分出天数，创建默认的一天行程
        List<ApiActivityFromUserTrip> activities = [];
        
        // 早餐 (7:30-8:30)
        DateTime breakfastTime = DateTime(now.year, now.month, now.day, 7, 30);
        activities.add(ApiActivityFromUserTrip(
          title: "酒店早餐",
          description: "在酒店享用丰盛的早餐",
          location: "$generatedDestination酒店餐厅",
          startTime: "${breakfastTime.hour}:${breakfastTime.minute.toString().padLeft(2, '0')}",
          endTime: "${breakfastTime.hour + 1}:${breakfastTime.minute.toString().padLeft(2, '0')}",
          type: "food",
          userStatus: "todo",
        ));
        
        // 上午活动 (9:00-11:30)
        DateTime morningTime = DateTime(now.year, now.month, now.day, 9, 0);
        activities.add(ApiActivityFromUserTrip(
          title: "景点游览",
          description: "参观$generatedDestination著名的旅游胜地",
          location: "$generatedDestination景区",
          startTime: "${morningTime.hour}:${morningTime.minute.toString().padLeft(2, '0')}",
          endTime: "11:30",
          type: "attraction",
          userStatus: "todo",
          transportation: "出租车",
          durationMinutes: 20,
        ));
        
        // 午餐 (12:00-13:30)
        activities.add(ApiActivityFromUserTrip(
          title: "$generatedDestination特色午餐",
          description: "品尝当地美食",
          location: "$generatedDestination美食街",
          startTime: "12:00",
          endTime: "13:30",
          type: "food",
          userStatus: "todo",
          transportation: "步行",
          durationMinutes: 15,
        ));
        
        // 下午活动 (14:00-17:00)
        activities.add(ApiActivityFromUserTrip(
          title: "文化体验活动",
          description: "体验当地特色文化活动",
          location: "$generatedDestination文化中心",
          startTime: "14:00",
          endTime: "17:00",
          type: "activity",
          userStatus: "todo",
          transportation: "公交",
          durationMinutes: 25,
        ));
        
        // 晚餐 (18:00-19:30)
        activities.add(ApiActivityFromUserTrip(
          title: "晚餐",
          description: "享用当地特色美食",
          location: "$generatedDestination餐厅",
          startTime: "18:00",
          endTime: "19:30",
          type: "food",
          userStatus: "todo",
          transportation: "出租车",
          durationMinutes: 15,
        ));
        
        activitiesByDay[1] = activities;
        dayTitles[1] = '第1天：${generatedDestination}一日游';
        dayDescriptions[1] = '探索${generatedDestination}的精彩景点与美食';
      }
      
      // 提取或创建标签
      if (generatedDestination.isNotEmpty) {
        parsedTags.add(generatedDestination);
      }
      parsedTags.add('AI生成');
      if (totalDays > 1) {
        parsedTags.add('${totalDays}日游');
      }
      
      // 确保天数与输入匹配
      int actualDays = dayContentBlocks.length > 0 ? dayContentBlocks.length : totalDays;
      if (actualDays < totalDays) {
        print('警告: 实际解析出的天数($actualDays)小于检测的总天数($totalDays)');
        actualDays = totalDays; // 以输入的天数为准
      }
      
      // 为每一天创建ApiDayFromUserTrip对象
      for (int day = 1; day <= actualDays; day++) {
        // 确保有活动列表，即使为空
        List<ApiActivityFromUserTrip> dayActivities = activitiesByDay[day] ?? [];
        
        // 创建标题
        String dayTitle = dayTitles[day] ?? '第${day}天：${generatedDestination}游';
        
        // 创建描述
        String dayDescription = dayDescriptions[day] ?? '第${day}天 ${generatedDestination}行程';
        
        // 创建日期
        DateTime dayDate = now.add(Duration(days: day - 1));
        
        // 添加到days列表
        ApiDayFromUserTrip dayObj = ApiDayFromUserTrip(
          dayNumber: day,
          date: dayDate,
          title: dayTitle,
          description: dayDescription,
          activities: dayActivities,
        );
        
        parsedDays.add(dayObj);
      }
      
      // 打印最终的天数信息
      print('最终生成的行程天数: ${parsedDays.length}');
      
      // 设置生成的天，并添加获取经纬度的处理
      Future<void> processActivitiesCoordinates(List<ApiDayFromUserTrip> days, String destination) async {
        final geoService = GeoService();
        
        for (var day in days) {
          for (var activity in day.activities) {
            if (activity.coordinates == null && activity.location != null && activity.location!.isNotEmpty) {
              // 使用城市+地点名进行地理编码查询，提高准确度
              final coordinates = await geoService.getCoordinatesFromName(
                activity.location!,
                city: destination
              );
              
              if (coordinates != null) {
                activity.coordinates = coordinates;
                debugPrint('已获取活动[${activity.title}]的经纬度: (${coordinates['latitude']}, ${coordinates['longitude']})');
              }
            }
          }
        }
      }

      // 创建最终的ApiUserTrip对象
      ApiUserTrip trip = ApiUserTrip(
        id: 'temp_${now.millisecondsSinceEpoch}', // 临时ID，后端会替换
        creatorId: creatorId ?? "",
        userTripNameOverride: '${generatedDestination}${actualDays > 1 ? "${actualDays}日" : ""}游行程',
        destination: generatedDestination,
        startDate: now,
        endDate: now.add(Duration(days: parsedDays.length - 1)),
        tags: parsedTags,
        description: description,
        days: parsedDays,
        members: [],
        messages: [],
        tickets: [],
        userNotes: [],
        publishStatus: 'draft',
        travelStatus: 'planning',
      );
      
      // 异步处理活动经纬度，不阻塞创建过程
      // 由于异步处理，在实际使用时经纬度可能尚未完全加载
      processActivitiesCoordinates(parsedDays, generatedDestination);
      
      return trip;
    }
    
    // 辅助方法：根据活动标题确定活动类型
    static String _determineActivityType(String title) {
      title = title.toLowerCase();
      
      if (title.contains('餐') || title.contains('吃') || title.contains('美食')) {
        return 'food';
      } else if (title.contains('购物') || title.contains('商场')) {
        return 'shopping';
      } else if (title.contains('景点') || title.contains('游览') || title.contains('参观')) {
        return 'attraction';
      } else if (title.contains('交通') || title.contains('车站') || title.contains('机场')) {
        return 'transport';
      } else if (title.contains('住宿') || title.contains('酒店') || title.contains('民宿')) {
        return 'accommodation';
      } else {
        return 'activity';
      }
    }


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
    Map<String, double>? coordinates;
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
        this.coordinates,
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
        coordinates: json["coordinates"] == null 
            ? null 
            : Map<String, double>.from(json["coordinates"].map((k, v) => MapEntry<String, double>(k, (v as num).toDouble()))),
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
        coordinates: planActivity.coordinates,
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
        "coordinates": coordinates,
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
        Map<String, double>? coordinates,
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
            coordinates: coordinates ?? this.coordinates,
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

// 定义一个辅助方法，用于尝试解析AI返回的JSON格式数据
// 如果能成功解析为JSON，则直接使用JSON结构
Map<String, dynamic>? _tryParseJson(String text) {
  try {
    // 尝试查找文本中的JSON部分（通常在```json和```之间）
    final jsonRegex = RegExp(r'```json([\s\S]*?)```');
    final jsonMatch = jsonRegex.firstMatch(text);
    
    String jsonText;
    if (jsonMatch != null && jsonMatch.groupCount >= 1) {
      jsonText = jsonMatch.group(1)!.trim();
    } else {
      // 也可能不带语言标识符，只用```包围
      final basicJsonRegex = RegExp(r'```([\s\S]*?)```');
      final basicJsonMatch = basicJsonRegex.firstMatch(text);
      
      if (basicJsonMatch != null && basicJsonMatch.groupCount >= 1) {
        jsonText = basicJsonMatch.group(1)!.trim();
      } else {
        // 没有找到包围的JSON内容，尝试直接解析整个文本
        jsonText = text;
      }
    }
    
    final data = json.decode(jsonText) as Map<String, dynamic>;
    debugPrint('成功解析到JSON数据，字段: ${data.keys.join(', ')}');
    return data;
  } catch (e) {
    debugPrint('JSON解析失败: $e');
    return null;
  }
}
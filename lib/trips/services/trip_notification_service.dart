// lib/trips/services/trip_notification_service.dart

import 'package:flutter/material.dart';
import 'dart:math'; // 添加导入min函数
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:tulele/core/services/plugin.dart'; // 提供了 flutterLocalNotificationsPlugin
import 'dart:io';


// 从main.dart导入全局通知插件实例

import '../../../core/services/notification_service.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/enums/trip_enums.dart';
import '../../../core/services/api_service.dart';

class TripNotificationService {
  // 单例模式
  static final TripNotificationService _instance = TripNotificationService._internal();
  factory TripNotificationService() => _instance;
  TripNotificationService._internal();
  
  final ApiService _apiService = ApiService();
  
  // 存储当前活跃的旅行ID
  String? _activeTripId;
  ApiUserTrip? _activeTrip;
  Map<String, ActivityStatus> _activityStatusMap = {};
  
  // 启动旅行模式通知
  Future<void> activateTripMode(String tripId) async {
    _activeTripId = tripId;
    await _loadTripData();
    await _setupTripNotifications();
  }
  
  // 结束旅行模式通知
  Future<void> deactivateTripMode() async {
    if (_activeTripId != null) {
      await cancelAllNotifications();
      _showTripCompletedNotification();
      _activeTripId = null;
      _activeTrip = null;
    }
  }
  
  // 加载旅行数据
  Future<void> _loadTripData() async {
    if (_activeTripId == null) return;
    
    try {
      _activeTrip = await _apiService.getUserTripById(_activeTripId!, populatePlan: true);
      // 初始化活动状态映射
      _initializeActivityStatusMap();
    } catch (e) {
      debugPrint('TripNotificationService: 加载旅行数据失败 - $e');
    }
  }
  
  // 初始化活动状态映射
  void _initializeActivityStatusMap() {
    _activityStatusMap = {};
    if (_activeTrip == null) return;
    
    for (final day in _activeTrip!.days) {
      for (final activity in day.activities) {
        if (activity.id != null) {
          // 默认状态为待处理
          _activityStatusMap[activity.id!] = ActivityStatus.pending;
        }
      }
    }
  }
  
  // 设置旅行通知
  Future<void> _setupTripNotifications() async {
    if (_activeTrip == null) return;
    
    // 1. 清除之前的通知
    await _cancelTripRelatedNotifications();
    
    // 2. 发送旅行开始通知
    await _showTripStartedNotification();
    
    // 3. 设置当日行程通知
    await _scheduleDailyItineraryNotifications();
    
    // 4. 设置活动提醒通知
    await _scheduleActivityNotifications();
  }
  
  // 旅行开始通知
  Future<void> _showTripStartedNotification() async {
    if (_activeTrip == null) return;
    
    final String tripName = _activeTrip!.displayName;
    final String destination = _activeTrip!.destination ?? '目的地';
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'trip_status_channel',
      '行程状态通知',
      channelDescription: '用于通知行程的开始、进行中和结束状态',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await flutterLocalNotificationsPlugin.show(
      1001,
      '旅行开始了',
      '您的$tripName之旅已经启动，目的地: $destination。祝您旅途愉快！',
      details,
      payload: 'trip_started:${_activeTrip!.id}',
    );
  }
  
  // 旅行结束通知
  Future<void> _showTripCompletedNotification() async {
    if (_activeTrip == null) return;
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'trip_status_channel',
      '行程状态通知',
      channelDescription: '用于通知行程的开始、进行中和结束状态',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await flutterLocalNotificationsPlugin.show(
      1002,
      '旅行结束',
      '${_activeTrip!.displayName}之旅已结束。感谢您使用途乐乐，期待您的回顾和分享！',
      details,
      payload: 'trip_ended:${_activeTrip!.id}',
    );
  }
  
  // 设置每日行程概览通知
  Future<void> _scheduleDailyItineraryNotifications() async {
    if (_activeTrip == null) return;
    
    final now = DateTime.now();
    
    for (final day in _activeTrip!.days) {
      if (day.date == null) continue;
      
      // 如果日期是今天或未来的日期
      if (!day.date!.isBefore(DateTime(now.year, now.month, now.day))) {
        // 设置当天早上8点的概览通知
        final notificationDate = DateTime(
          day.date!.year,
          day.date!.month,
          day.date!.day,
          8, // 早上8点
          0,
        );
        
        // 如果通知时间已经过了，跳过
        if (notificationDate.isBefore(now)) continue;
        
        // 准备活动概览文本
        String activitiesSummary = '今日暂无活动安排';
        if (day.activities.isNotEmpty) {
          activitiesSummary = '今日安排: ';
          for (int i = 0; i < min(3, day.activities.length); i++) {
            final activity = day.activities[i];
            // 假设startTime是DateTime类型或能获取时间的对象
            final timeStr = activity.startTime != null 
                ? _formatTime(activity.startTime!)
                : '全天';
            activitiesSummary += '${i > 0 ? ', ' : ''}$timeStr ${activity.title}';
          }
          if (day.activities.length > 3) {
            activitiesSummary += ' 等${day.activities.length}个活动';
          }
        }
        
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'daily_itinerary_channel',
          '每日行程概览',
          channelDescription: '每日行程概览和提醒',
          importance: Importance.high,
          priority: Priority.high,
        );
        
        final NotificationDetails details = NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(),
        );
        
        // 安排通知
        await flutterLocalNotificationsPlugin.zonedSchedule(
          2000 + day.dayNumber!, // 使用日期序号作为ID的一部分
          '第${day.dayNumber}天行程 · ${_activeTrip!.displayName}',
          activitiesSummary,
          tz.TZDateTime.from(notificationDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'daily_overview:${_activeTrip!.id}:${day.dayNumber}',
        );
      }
    }
  }
  
  // 格式化时间
  String _formatTime(dynamic time) {
    if (time is DateTime) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (time is String) {
      // 假设字符串是HH:MM格式
      return time;
    }
    return '全天';
  }
  
  // 安排活动提醒通知
  Future<void> _scheduleActivityNotifications() async {
    if (_activeTrip == null) return;
    
    final now = DateTime.now();
    
    for (final day in _activeTrip!.days) {
      if (day.date == null) continue;
      
      for (final activity in day.activities) {
        if (activity.startTime == null || activity.id == null) continue;
        
        // 合并日期和时间 - 处理startTime可能是字符串的情况
        final activityDateTime = _getActivityDateTime(day.date!, activity.startTime!);
        if (activityDateTime == null) continue;
        
        // 只为未来的活动安排通知
        if (activityDateTime.isAfter(now)) {
          // 安排活动前30分钟的提醒
          final notificationTime = activityDateTime.subtract(const Duration(minutes: 30));
          
          // 如果提醒时间已过，则跳过
          if (notificationTime.isBefore(now)) continue;
          
          final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'activity_reminder_channel',
            '活动提醒',
            channelDescription: '即将开始的活动提醒',
            importance: Importance.max,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction('check_in', '签到'),
              AndroidNotificationAction('navigate', '导航'),
            ],
          );
          
          final NotificationDetails details = NotificationDetails(
            android: androidDetails,
            iOS: const DarwinNotificationDetails(
              categoryIdentifier: darwinNotificationCategoryPlain,
            ),
          );
          
          // 生成通知ID
          final int notificationId = 3000 + activity.id.hashCode % 1000;
          
          // 安排通知
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            '即将开始: ${activity.title}',
            '您的活动将在30分钟后开始${activity.location != null ? ' 在 ${activity.location}' : ''}',
            tz.TZDateTime.from(notificationTime, tz.local),
            details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: 'activity_reminder:${_activeTrip!.id}:${day.dayNumber}:${activity.id}',
          );
        }
      }
    }
  }
  
  // 处理活动时间，兼容不同类型
  DateTime? _getActivityDateTime(DateTime dayDate, dynamic startTime) {
    if (startTime is DateTime) {
      return DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
        startTime.hour,
        startTime.minute,
      );
    } else if (startTime is String) {
      try {
        // 假设格式为"HH:MM"
        final parts = startTime.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            return DateTime(
              dayDate.year,
              dayDate.month,
              dayDate.day,
              hour,
              minute,
            );
          }
        }
      } catch (e) {
        debugPrint('解析活动时间出错: $e');
      }
    }
    return null;
  }
  
  // 更新活动状态
  Future<void> updateActivityStatus(String activityId, ActivityStatus newStatus) async {
    // 检查活动是否存在
    if (!_activityStatusMap.containsKey(activityId)) return;
    
    final oldStatus = _activityStatusMap[activityId];
    _activityStatusMap[activityId] = newStatus;
    
    // 如果状态发生变化，发送通知
    if (oldStatus != newStatus) {
      _notifyActivityStatusChange(activityId, newStatus);
    }
  }
  
  // 活动状态变更通知
  Future<void> _notifyActivityStatusChange(String activityId, ActivityStatus newStatus) async {
    if (_activeTrip == null) return;
    
    // 查找活动
    ApiActivityFromUserTrip? activity;
    ApiDayFromUserTrip? activityDay;
    
    for (final day in _activeTrip!.days) {
      final found = day.activities.firstWhere(
        (a) => a.id == activityId,
        orElse: () => ApiActivityFromUserTrip(title: '', id: ''), // 创建一个空的活动对象
      );
      if (found.id == activityId) {
        activity = found;
        activityDay = day;
        break;
      }
    }
    
    if (activity == null || activity.id!.isEmpty) return;
    
    // 根据新状态发送不同的通知
    if (newStatus == ActivityStatus.completed) {
      // 找出下一个活动
      ApiActivityFromUserTrip? nextActivity;
      
      if (activityDay != null) {
        final currentIndex = activityDay.activities.indexWhere((a) => a.id == activityId);
        if (currentIndex != -1 && currentIndex < activityDay.activities.length - 1) {
          nextActivity = activityDay.activities[currentIndex + 1];
        }
      }
      
      // 活动完成通知
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'activity_status_channel',
        '活动状态变更',
        channelDescription: '活动完成、取消等状态变更通知',
        importance: Importance.low, // 修改default为low
        priority: Priority.low, // 修改default为low
      );
      
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );
      
      String notificationBody;
      if (nextActivity != null) {
        final nextTimeStr = nextActivity.startTime != null 
            ? _formatTime(nextActivity.startTime!)
            : '';
        notificationBody = '下一项: ${nextActivity.title} ${nextTimeStr.isNotEmpty ? '($nextTimeStr)' : ''}';
      } else {
        notificationBody = '今日行程已全部完成';
      }
      
      await flutterLocalNotificationsPlugin.show(
        4000 + activityId.hashCode % 1000,
        '已完成: ${activity.title}',
        notificationBody,
        details,
        payload: 'activity_completed:${_activeTrip!.id}:$activityId',
      );
    } else if (newStatus == ActivityStatus.ongoing) {
      // 活动开始通知
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'activity_status_channel',
        '活动状态变更',
        channelDescription: '活动完成、取消等状态变更通知',
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('check_in', '签到'),
          AndroidNotificationAction('take_photo', '拍照'),
        ],
      );
      
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: darwinNotificationCategoryPlain,
        ),
      );
      
      await flutterLocalNotificationsPlugin.show(
        4000 + activityId.hashCode % 1000,
        '正在进行: ${activity.title}',
        activity.location != null ? '地点: ${activity.location}' : '享受当下的美好时光',
        details,
        payload: 'activity_ongoing:${_activeTrip!.id}:$activityId',
      );
    }
  }
  
  // 智能位置通知 (此功能需要配合位置服务实现)
  Future<void> processLocationUpdate(double latitude, double longitude) async {
    // 如果没有活跃的旅行，直接返回
    if (_activeTrip == null) return;
    
    // 这里可以集成位置服务，检查用户是否接近某个活动地点
    // 如果是，则发送接近通知
    
    // 示例代码（实际实现需要配合地理位置服务）
    // 1. 遍历当天的所有活动
    // 2. 计算用户当前位置与活动地点的距离
    // 3. 如果距离小于特定阈值（如1公里），发送接近通知
  }
  
  // 处理通知响应
  void handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    
    final parts = payload.split(':');
    if (parts.isEmpty) return;
    
    final notificationType = parts[0];
    
    // 根据通知类型处理
    switch (notificationType) {
      case 'trip_started':
        // 处理旅行开始通知响应
        // 可能打开旅行概览页面
        break;
        
      case 'activity_reminder':
      case 'activity_ongoing':
        // 处理活动提醒/进行中通知响应
        if (parts.length >= 4) {
          final tripId = parts[1];
          final dayNumber = int.tryParse(parts[2]);
          final activityId = parts[3];
          // 可以返回这些信息给UI层进行处理
        }
        break;
        
      case 'activity_completed':
        // 处理活动完成通知响应
        if (parts.length >= 3) {
          final tripId = parts[1];
          final activityId = parts[2];
          // 可以返回这些信息给UI层进行处理
        }
        break;
    }
    
    // 处理操作按钮
    if (response.actionId != null) {
      switch (response.actionId) {
        case 'check_in':
          // 处理签到操作
          break;
          
        case 'navigate':
          // 处理导航操作
          break;
          
        case 'take_photo':
          // 处理拍照操作
          break;
      }
    }
  }
  
  // 添加这个新方法:
  Future<void> _cancelTripRelatedNotifications() async {
    // 方法1: 按照频道组取消
    final tripChannelGroups = [
      'trip_status_channel',
      'daily_itinerary_channel', 
      'activity_reminder_channel',
      'activity_status_channel'
    ];
    
    // 对于Android，可以利用cancelNotificationChannel方法
    if (Platform.isAndroid) {
      for (final channelId in tripChannelGroups) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.deleteNotificationChannel(channelId);
      }
    }
    
  }
  // 刷新活动数据和通知
  Future<void> refreshTripData() async {
    await _loadTripData();
    await _setupTripNotifications();
  }

    // 替换simulateDayNotifications方法，使用更完整的流程
  Future<void> simulateDayNotifications() async {
    await simulateFirstDayCompleteTripFlow();
  }

  // 新增方法：模拟旅行第一天完整通知流程
  Future<void> simulateFirstDayCompleteTripFlow() async {
    if (_activeTrip == null || _activeTrip!.days.isEmpty) {
      debugPrint('无法模拟：未设置旅行数据或无行程天数');
      return;
    }
    
    final firstDay = _activeTrip!.days[0];
    debugPrint('开始模拟第${firstDay.dayNumber}天完整旅行体验...');
    
    // 1. 早晨唤醒通知
    await _showMorningWakeupNotification(firstDay);
    await Future.delayed(const Duration(seconds: 3));
    
    // 2. 行程概览通知
    await _showDayItineraryOverview(firstDay);
    await Future.delayed(const Duration(seconds: 3));
    
    // 3. 出行前天气提醒
    await _showWeatherForecastNotification();
    await Future.delayed(const Duration(seconds: 3));
    
    // 4. 出门前准备提醒
    await _showDeparturePreparationNotification(firstDay);
    await Future.delayed(const Duration(seconds: 3));
    
    // 5. 按顺序模拟每个活动的完整流程
    for (int i = 0; i < firstDay.activities.length; i++) {
      final activity = firstDay.activities[i];
      
      // 5.1 出发前往活动地点
      await _showTransportToActivityNotification(activity);
      await Future.delayed(const Duration(seconds: 3));
      
      // 5.2 交通状况更新
      await _showTransportationUpdateNotification();
      await Future.delayed(const Duration(seconds: 3));
      
      // 5.3 抵达附近通知
      await _showArrivingNearbyNotification(activity);
      await Future.delayed(const Duration(seconds: 3));
      
      // 5.4 活动即将开始通知
      await _showActivityStartingSoonNotification(activity);
      await Future.delayed(const Duration(seconds: 3));
      
      // 5.5 票务提醒（如果需要）
      if (Random().nextBool()) {
        await _showTicketReminderNotification(activity);
        await Future.delayed(const Duration(seconds: 3));
      }
      
      // 5.6 团队成员消息
      await _showTeamMemberMessage();
      await Future.delayed(const Duration(seconds: 3));
      
      // 5.7 活动中智能提示
      await _showDuringActivityNotification(activity);
      await Future.delayed(const Duration(seconds: 3));
      
      // 5.8 活动完成通知
      if (activity.id != null) {
        await updateActivityStatus(activity.id!, ActivityStatus.completed);
      }
      await Future.delayed(const Duration(seconds: 3));
      
      // 如果不是最后一个活动，显示下一个活动的提醒
      if (i < firstDay.activities.length - 1) {
        await _showNextActivityReminderNotification(firstDay.activities[i+1]);
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    
    // 6. 晚间行程总结通知
    await _showEveningTripSummaryNotification(firstDay);
  }

  // 早晨唤醒通知
  Future<void> _showMorningWakeupNotification(ApiDayFromUserTrip day) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'morning_wakeup_channel',
      '早晨唤醒',
      channelDescription: '旅行日早晨唤醒提醒',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    final destination = _activeTrip!.destination ?? '目的地';
    final dayNumber = day.dayNumber ?? 1;
    
    await flutterLocalNotificationsPlugin.show(
      10000,
      '早安！$destination之旅第$dayNumber天开始了',
      '今天将是精彩的一天，点击查看您的行程安排',
      details,
      payload: 'morning_wakeup:${_activeTrip!.id}:$dayNumber',
    );
  }

  // 行程概览通知
  Future<void> _showDayItineraryOverview(ApiDayFromUserTrip day) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'day_overview_channel',
      '日程概览',
      channelDescription: '当日行程概览通知',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    String activitiesSummary = '';
    if (day.activities.isNotEmpty) {
      for (int i = 0; i < min(4, day.activities.length); i++) {
        final activity = day.activities[i];
        final timeStr = activity.startTime != null 
            ? _formatTime(activity.startTime!)
            : '全天';
        activitiesSummary += '\n· $timeStr ${activity.title}';
      }
      if (day.activities.length > 4) {
        activitiesSummary += '\n· ...等${day.activities.length}个活动';
      }
    } else {
      activitiesSummary = '\n今日暂无活动安排';
    }
    
    await flutterLocalNotificationsPlugin.show(
      10001,
      '今日行程安排',
      '${day.date != null ? _formatDate(day.date!) : ""}${activitiesSummary}',
      details,
      payload: 'day_overview:${_activeTrip!.id}:${day.dayNumber}',
    );
  }

  // 天气预报通知
  Future<void> _showWeatherForecastNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weather_forecast_channel',
      '天气预报',
      channelDescription: '旅行目的地天气预报',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    final destination = _activeTrip!.destination ?? '目的地';
    final weatherTypes = ['晴朗', '多云', '小雨', '阴天'];
    final temperatures = ['22°C-28°C', '18°C-25°C', '15°C-20°C', '25°C-32°C'];
    final suggestions = [
      '天气炎热，建议穿轻薄衣物，带好防晒用品',
      '天气宜人，建议穿舒适衣物',
      '有雨，请携带雨伞',
      '紫外线强，请做好防晒措施'
    ];
    
    final index = Random().nextInt(weatherTypes.length);
    
    await flutterLocalNotificationsPlugin.show(
      10002,
      '$destination今日天气：${weatherTypes[index]}',
      '温度：${temperatures[index]}\n${suggestions[index]}',
      details,
      payload: 'weather_forecast:${_activeTrip!.id}',
    );
  }

  // 出发准备提醒
  Future<void> _showDeparturePreparationNotification(ApiDayFromUserTrip day) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'departure_prep_channel',
      '出发准备',
      channelDescription: '出发前物品和准备提醒',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('check_list', '查看清单'),
      ],
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        categoryIdentifier: darwinNotificationCategoryPlain,
      ),
    );
    
    final firstActivity = day.activities.isNotEmpty ? day.activities[0] : null;
    final firstActivityTime = firstActivity?.startTime != null 
        ? _formatTime(firstActivity!.startTime!)
        : '上午';
    
    await flutterLocalNotificationsPlugin.show(
      10003,
      '行程准备提醒',
      '您的第一个活动将在$firstActivityTime开始，请检查您的行程物品清单',
      details,
      payload: 'departure_prep:${_activeTrip!.id}',
    );
  }

  // 抵达附近通知
  Future<void> _showArrivingNearbyNotification(ApiActivityFromUserTrip activity) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'arriving_nearby_channel',
      '抵达附近',
      channelDescription: '接近目的地的位置通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    final location = activity.location ?? '目的地';
    
    await flutterLocalNotificationsPlugin.show(
      10004 + activity.hashCode % 1000,
      '即将抵达: $location',
      '您距离${activity.title}只有约300米，步行约5分钟可到达',
      details,
      payload: 'arriving_nearby:${activity.id}',
    );
  }

  // 交通状况更新
  Future<void> _showTransportationUpdateNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'transport_update_channel',
      '交通更新',
      channelDescription: '实时交通状况更新',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    final updates = [
      '前方道路施工，建议改走东侧道路',
      '目的地附近停车位紧张，建议提前寻找停车场',
      '公交车将在2分钟后到达，请做好准备',
      '地铁站口改为东南出口，请注意引导牌',
    ];
    
    await flutterLocalNotificationsPlugin.show(
      10005,
      '交通状况更新',
      updates[Random().nextInt(updates.length)],
      details,
      payload: 'transport_update:${_activeTrip!.id}',
    );
  }

  // 票务提醒
  Future<void> _showTicketReminderNotification(ApiActivityFromUserTrip activity) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ticket_channel',
      '票务提醒',
      channelDescription: '票务、预订和入场提醒',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('show_ticket', '显示门票'),
        AndroidNotificationAction('share_ticket', '分享给同伴'),
      ],
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        categoryIdentifier: darwinNotificationCategoryPlain,
      ),
    );
    
    await flutterLocalNotificationsPlugin.show(
      10006 + activity.hashCode % 1000,
      '${activity.title}入场提醒',
      '请准备好您的电子门票，点击查看二维码',
      details,
      payload: 'ticket_reminder:${activity.id}',
    );
  }

  // 团队成员消息
  Future<void> _showTeamMemberMessage() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'team_message_channel',
      '团队消息',
      channelDescription: '团队成员消息通知',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('reply', '回复'),
        AndroidNotificationAction('locate', '查看位置'),
      ],
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        categoryIdentifier: darwinNotificationCategoryText,
      ),
    );
    
    final messages = [
      '我已经到达入口处，你们在哪里？',
      '这边有特色小吃，一起来尝尝吧！',
      '帮我拍张照片好吗？',
      '我找到了一条捷径，发位置给你们',
    ];
    
    final senders = ['小明', '小红', '小李', '小张'];
    final index = Random().nextInt(senders.length);
    
    await flutterLocalNotificationsPlugin.show(
      10007,
      '${senders[index]}发来消息',
      messages[index],
      details,
      payload: 'team_message:${_activeTrip!.id}:${senders[index]}',
    );
  }

  // 下一个活动提醒
  Future<void> _showNextActivityReminderNotification(ApiActivityFromUserTrip nextActivity) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'next_activity_channel',
      '下一活动提醒',
      channelDescription: '下一个行程活动提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    final timeStr = nextActivity.startTime != null 
        ? _formatTime(nextActivity.startTime!)
        : '即将';
    
    await flutterLocalNotificationsPlugin.show(
      10008 + nextActivity.hashCode % 1000,
      '下一个活动提醒',
      '$timeStr将前往${nextActivity.title}${nextActivity.location != null ? " 在${nextActivity.location}" : ""}',
      details,
      payload: 'next_activity:${nextActivity.id}',
    );
  }

  // 晚间行程总结
  Future<void> _showEveningTripSummaryNotification(ApiDayFromUserTrip day) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'evening_summary_channel',
      '晚间总结',
      channelDescription: '一天行程的总结和回顾',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    int completedCount = 0;
    for (final activity in day.activities) {
      if (activity.id != null && _activityStatusMap[activity.id!] == ActivityStatus.completed) {
        completedCount++;
      }
    }
    
    final destination = _activeTrip!.destination ?? '目的地';
    
    await flutterLocalNotificationsPlugin.show(
      10009,
      '$destination之旅第${day.dayNumber ?? 1}天总结',
      '今天您完成了$completedCount/${day.activities.length}个活动。\n\n明天将继续精彩的旅程，请及时休息，准备迎接新的一天！',
      details,
      payload: 'evening_summary:${_activeTrip!.id}:${day.dayNumber}',
    );
  }

  // 添加格式化日期的辅助方法
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // 活动即将开始通知
  Future<void> _showActivityStartingSoonNotification(ApiActivityFromUserTrip activity) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'activity_start_channel',
      '活动开始提醒',
      channelDescription: '活动即将开始的提醒',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('check_in', '签到'),
        AndroidNotificationAction('show_ticket', '显示门票'),
      ],
    );
    
    final NotificationDetails details = const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        categoryIdentifier: darwinNotificationCategoryPlain,
      ),
    );
    
    await flutterLocalNotificationsPlugin.show(
      8000 + activity.hashCode % 1000,
      '即将开始: ${activity.title}',
      '${activity.startTime != null ? _formatTime(activity.startTime!) : "即将"}在${activity.location ?? "当前位置"}开始，请做好准备',
      details,
      payload: 'activity_starting:${activity.id}',
    );
  }

  // 活动中提醒
  Future<void> _showDuringActivityNotification(ApiActivityFromUserTrip activity) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'during_activity_channel',
      '活动中提醒',
      channelDescription: '活动进行中的智能提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final NotificationDetails details = const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    final suggestions = [
      '周围有热门拍照点，向右走50米可以看到',
      '此处有特色纪念品，可以考虑购买',
      '附近有免费WiFi: "${activity.location ?? "景点"}_Free"',
      '据其他游客反馈，这里的${_getRandomFoodOrItem()}非常值得尝试'
    ];
    
    await flutterLocalNotificationsPlugin.show(
      9000 + activity.hashCode % 1000,
      '${activity.title}小贴士',
      suggestions[Random().nextInt(suggestions.length)],
      details,
      payload: 'during_activity:${activity.id}',
    );
  }

  // 生成随机美食或物品
  String _getRandomFoodOrItem() {
    final items = ['冰淇淋', '特色小吃', '手工艺品', '当地特产', '观景台', '互动体验'];
    return items[Random().nextInt(items.length)];
  }

  // 交通前往通知
  Future<void> _showTransportToActivityNotification(ApiActivityFromUserTrip activity) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'transportation_channel',
      '交通状况通知',
      channelDescription: '前往活动的交通信息',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final NotificationDetails details = const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await flutterLocalNotificationsPlugin.show(
      7000 + activity.hashCode % 1000,
      '前往${activity.title}',
      '建议现在出发前往${activity.location ?? "目的地"}，预计路程15分钟',
      details,
      payload: 'transport_to:${activity.id}',
    );
  }

  // 直接设置旅行数据，便于测试或模拟
  Future<void> setTripData(ApiUserTrip tripData) async {
    _activeTrip = tripData;
    _activeTripId = tripData.id;
    _initializeActivityStatusMap();
    debugPrint('旅行数据已设置：${_activeTrip?.displayName}，共${_activeTrip?.days.length}天，${_getActivitiesCount()}个活动');
  }


  // 辅助方法：获取今日活动数量
  int _getActivitiesCount() {
    if (_activeTrip == null || _activeTrip!.days.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    for (final day in _activeTrip!.days) {
      if (day.date != null) {
        final dayDate = DateTime(day.date!.year, day.date!.month, day.date!.day);
        if (dayDate.isAtSameMomentAs(todayDate)) {
          return day.activities.length;
        }
      }
    }
    
    return 0;
  }

  
}
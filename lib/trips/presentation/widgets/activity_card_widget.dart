// lib/trips/presentation/widgets/activity_card_widget.dart
import 'package:flutter/material.dart';
import '../../../core/models/api_user_trip_model.dart';
// 确保 TripMode 和 ActivityStatus 枚举从正确的位置导入
import '../../../core/enums/trip_enums.dart'; // 假设枚举已移至此处

// LineConnectorPainter 保持不变 (来自你提供的 activity_card_widget.dart)
// 它用于在 TransportConnectorWidget 内部绘制带文本的连接线
class LineConnectorPainter extends CustomPainter {
  final Color lineColor;
  final String? transportText;
  final String? durationText;

  LineConnectorPainter({required this.lineColor, this.transportText, this.durationText});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

    const double linePadding = 0; // 连接线应该从顶部到底部
    canvas.drawLine(Offset(size.width / 2, linePadding), Offset(size.width / 2, size.height - linePadding), paint);

    if (transportText != null || durationText != null) {
      final textStyle = TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w500);
      final iconColor = Colors.grey[700];
      double offsetY = size.height / 2 - 15; // 初始偏移量，可能需要调整
      const double textOffsetFromLine = 8.0; // 图标和文字离中心线的距离
      const double iconTextSpacing = 3.0;

      List<Widget> displayItems = [];
      String fullText = "";

      if (transportText != null) {
        final IconData transportIconData = transportText == '打车' ? Icons.local_taxi_outlined :
                                          transportText == '公交' ? Icons.directions_bus_outlined :
                                          transportText == '步行' ? Icons.directions_walk_outlined :
                                          transportText == '驾车' ? Icons.drive_eta_outlined : // 增加驾车图标
                                          transportText == '飞机' ? Icons.flight_takeoff_outlined :
                                          transportText == '火车' ? Icons.train_outlined :
                                          Icons.moving_rounded; // 默认图标

        final iconPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(transportIconData.codePoint),
            style: TextStyle(fontSize: 14, fontFamily: transportIconData.fontFamily, package: transportIconData.fontPackage, color: iconColor),
          ),
          textDirection: TextDirection.ltr,
        );
        iconPainter.layout();
        // 图标绘制位置调整到更中心
        iconPainter.paint(canvas, Offset(size.width / 2 + textOffsetFromLine, size.height / 2 - iconPainter.height / 2 - (durationText != null ? 8 : 0) ));
        
        fullText += "$transportText ";
      }

      if (durationText != null) {
        fullText += durationText ?? '';
      }
      
      if (fullText.isNotEmpty) {
         final textContentPainter = TextPainter(
          text: TextSpan(text: fullText.trim(), style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textContentPainter.layout(maxWidth: size.width / 2 - textOffsetFromLine - 5); // 限制文本宽度
        // 文本绘制位置调整到更中心
        textContentPainter.paint(canvas, Offset(
            size.width / 2 + textOffsetFromLine + (transportText != null ? 14 + iconTextSpacing : 0), // 如果有图标，文本向右偏移
            size.height / 2 - textContentPainter.height / 2 + (transportText != null && durationText != null ? 8 : 0) // 如果两者都有，持续时间文字向下一点
        ));
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineConnectorPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.transportText != transportText ||
        oldDelegate.durationText != durationText;
  }
}


/// 新的活动卡片 Widget，用于展示单个活动的详细信息
class ActivityDisplayCard extends StatelessWidget {
  final ApiActivityFromUserTrip activity;
  final TripMode mode;
  final VoidCallback? onEdit; // 编辑回调
  final ActivityStatus? uiStatus; // 前端管理的UI状态，主要用于旅行模式
  final ValueChanged<ActivityStatus>? onStatusChange; // 旅行模式下状态改变的回调

  const ActivityDisplayCard({
    super.key,
    required this.activity,
    required this.mode,
    this.onEdit,
    this.uiStatus,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    bool isOngoing = mode == TripMode.travel && uiStatus == ActivityStatus.ongoing;
    bool isCompleted = mode == TripMode.travel && uiStatus == ActivityStatus.completed;
    
    // 确定卡片的颜色主题
    Color cardBackground = Colors.white;
    Color accentColor = Theme.of(context).primaryColor;
    Color timeColor = Colors.grey.shade800;
    Color borderColor = Colors.transparent;
    double elevation = 2.0;
    
    // 根据活动类型设置不同的颜色主题
    switch (activity.type) {
      case "food":
        accentColor = Colors.orange.shade700;
        break;
      case "attraction":
        accentColor = Colors.blue.shade600;
        break;
      case "accommodation":
        accentColor = Colors.purple.shade500;
        break;
      case "transport":
        accentColor = Colors.green.shade600;
        break;
      case "shopping":
        accentColor = Colors.pink.shade400;
        break;
      default:
        accentColor = Colors.teal.shade500;
    }
    
    // 状态修改卡片外观
    if (isOngoing) {
      cardBackground = accentColor.withOpacity(0.08);
      timeColor = accentColor;
      borderColor = accentColor.withOpacity(0.6);
      elevation = 3.0;
    } else if (isCompleted) {
      cardBackground = Colors.grey.shade50;
      accentColor = Colors.grey.shade500;
      timeColor = Colors.grey.shade500;
      elevation = 1.0;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isOngoing ? 0.2 : 0.1),
            blurRadius: isOngoing ? 7 : 5,
            spreadRadius: isOngoing ? 1 : 0,
            offset: const Offset(0, 3)
          )
        ],
      ),
      child: Material(
        type: MaterialType.card,
        elevation: elevation,
        color: cardBackground,
        borderRadius: BorderRadius.circular(16.0),
        clipBehavior: Clip.antiAlias, // 添加裁剪效果
        child: InkWell(
          onTap: mode == TripMode.edit ? onEdit : null,
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            children: [
              // 顶部时间条
              if (activity.startTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    border: Border(
                      left: BorderSide(color: accentColor, width: 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIconData(activity.type ?? ''),
                        size: 18,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activity.startTime!,
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (activity.endTime != null) ...[
                        Text(
                          ' - ',
                          style: TextStyle(color: timeColor, fontSize: 15),
                        ),
                        Text(
                          activity.endTime!,
                          style: TextStyle(
                            color: timeColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '已完成',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (isOngoing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '进行中',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              
              // 内容主体
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 活动标题
                    Text(
                      activity.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.grey.shade600 : Colors.black87,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    
                    // 地点信息
                    if (activity.location != null && activity.location!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: isCompleted ? Colors.grey.shade500 : accentColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              activity.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // 详细描述
                    if (activity.description != null && activity.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.grey.shade100
                              : accentColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                    
                    // 交通信息
                    if (activity.transportation != null && activity.transportation!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _getTransportIcon(activity.transportation!),
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activity.transportation!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                          if (activity.durationMinutes != null) ...[
                            const SizedBox(width: 5),
                            Text(
                              '(${activity.durationMinutes}分钟)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ],
                      ),
                    ],
                    
                    // 底部按钮区域
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 导航按钮
                        OutlinedButton.icon(
                          icon: Icon(Icons.navigation_outlined, size: 16, color: accentColor),
                          label: Text(
                            "导航",
                            style: TextStyle(color: accentColor, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            minimumSize: const Size(0, 32),
                            side: BorderSide(color: accentColor.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("导航功能待实现"))
                            );
                          },
                        ),
                        
                        // 编辑按钮
                        if (mode == TripMode.edit) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: Icon(Icons.edit_outlined, size: 16, color: accentColor),
                            label: Text(
                              "编辑",
                              style: TextStyle(color: accentColor, fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: onEdit,
                          ),
                        ],
                        
                        // 旅行中的状态切换
                        if (mode == TripMode.travel && onStatusChange != null) ...[
                          const SizedBox(width: 8),
                          _buildStatusToggleButton(context, accentColor),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建状态切换按钮
  Widget _buildStatusToggleButton(BuildContext context, Color accentColor) {
    if (uiStatus == ActivityStatus.completed) {
      return TextButton.icon(
        icon: Icon(Icons.refresh, size: 16, color: Colors.amber.shade800),
        label: const Text("取消完成", style: TextStyle(fontSize: 13)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 32),
          foregroundColor: Colors.amber.shade800,
        ),
        onPressed: () => onStatusChange?.call(ActivityStatus.pending),
      );
    } else if (uiStatus == ActivityStatus.ongoing) {
      return TextButton.icon(
        icon: Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
        label: const Text("标记完成", style: TextStyle(fontSize: 13)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 32),
          foregroundColor: Colors.green.shade700,
        ),
        onPressed: () => onStatusChange?.call(ActivityStatus.completed),
      );
    } else {
      return TextButton.icon(
        icon: Icon(Icons.play_arrow, size: 16, color: accentColor),
        label: const Text("开始", style: TextStyle(fontSize: 13)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 32),
        ),
        onPressed: () => onStatusChange?.call(ActivityStatus.pending),
      );
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant': case 'food': case 'meal': return Icons.restaurant_menu_rounded;
      case 'hotel': case 'sleep': case 'accommodation': return Icons.hotel_rounded;
      case 'flight': case 'plane': return Icons.flight_takeoff_rounded;
      case 'train': return Icons.train_rounded;
      case 'bus': return Icons.directions_bus_rounded;
      case 'car': case 'taxi': case 'drive': case 'transport': return Icons.directions_car_rounded;
      case 'walk': return Icons.directions_walk_rounded;
      case 'museum': case 'art': return Icons.museum_rounded;
      case 'landmark': case 'sightseeing': case 'attraction': return Icons.camera_alt_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'activity': return Icons.local_activity_rounded;
      default: return Icons.place_rounded;
    }
  }
  
  IconData _getTransportIcon(String transportType) {
    switch (transportType.toLowerCase()) {
      case '步行': return Icons.directions_walk;
      case '公交': return Icons.directions_bus;
      case '出租车': return Icons.local_taxi;
      case '地铁': return Icons.subway;
      case '共享单车': return Icons.pedal_bike;
      case '景区班车': return Icons.airport_shuttle;
      default: return Icons.commute;
    }
  }
}

/// 用于在活动卡片之间显示交通连接线和信息的 Widget
class TransportConnector extends StatelessWidget {
  final String? transportationMode; // 如："步行", "驾车"
  final int? durationMinutes;    // 如：30 (分钟)

  const TransportConnector({
    super.key,
    this.transportationMode,
    this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // 如果没有交通信息，返回一个简单的连接线
    if (transportationMode == null && durationMinutes == null) {
      return Container(
        height: 40,
        margin: const EdgeInsets.only(left: 32.0),
        child: Column(
          children: [
            Expanded(
              child: VerticalDivider(
                color: Colors.grey.shade300,
                thickness: 1.5,
                width: 20,
              ),
            ),
          ],
        ),
      );
    }
    
    // 计算时间文本
    String durationText = "";
    if (durationMinutes != null) {
      if (durationMinutes! >= 60) {
        durationText = "${(durationMinutes! / 60).floor()}小时";
        if (durationMinutes! % 60 != 0) {
           durationText += " ${(durationMinutes! % 60)}分钟";
        }
      } else {
        durationText = "$durationMinutes分钟";
      }
    }

    // 根据交通方式确定颜色和图标
    Color transportColor;
    IconData transportIcon;
    
    switch (transportationMode?.toLowerCase() ?? '') {
      case '步行':
        transportColor = Colors.green.shade600;
        transportIcon = Icons.directions_walk;
        break;
      case '公交':
        transportColor = Colors.blue.shade600;
        transportIcon = Icons.directions_bus;
        break;
      case '出租车':
        transportColor = Colors.amber.shade700;
        transportIcon = Icons.local_taxi;
        break;
      case '地铁':
        transportColor = Colors.red.shade600;
        transportIcon = Icons.subway;
        break;
      case '共享单车':
        transportColor = Colors.orange.shade600;
        transportIcon = Icons.pedal_bike;
        break;
      case '景区班车':
        transportColor = Colors.purple.shade400;
        transportIcon = Icons.airport_shuttle;
        break;
      default:
        transportColor = Colors.grey.shade600;
        transportIcon = Icons.commute;
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 32.0),
      child: Row(
        children: [
          // 左侧连接线
          Container(
            width: 20,
            child: Column(
              children: [
                Expanded(
                  child: VerticalDivider(
                    color: transportColor.withOpacity(0.5),
                    thickness: 1.5,
                    width: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 圆形交通图标
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: transportColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: transportColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                transportIcon,
                size: 18,
                color: transportColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 交通方式和时间文本
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (transportationMode != null)
                Text(
                  transportationMode!,
                  style: TextStyle(
                    color: transportColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (durationText.isNotEmpty)
                Text(
                  durationText,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
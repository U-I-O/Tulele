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
    
    Color cardBackgroundColor = Colors.white;
    Color titleColor = Colors.black87;
    BoxShadow cardShadow = BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2));

    if (isOngoing) {
        cardBackgroundColor = Theme.of(context).primaryColor.withOpacity(0.05);
        titleColor = Theme.of(context).primaryColorDark ?? Theme.of(context).primaryColor;
        cardShadow = BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.2), spreadRadius: 2, blurRadius: 6, offset: const Offset(0, 3));
    } else if (isCompleted) {
        cardBackgroundColor = Colors.grey.shade50;
        titleColor = Colors.grey.shade600;
        cardShadow = BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 0.5, blurRadius: 3, offset: const Offset(0, 1));
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [cardShadow],
        border: isOngoing ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Material( // 添加 Material Widget 以支持 InkWell 的 splash 效果
        type: MaterialType.transparency,
        child: InkWell(
          onTap: mode == TripMode.edit ? onEdit : null,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧时间显示 (更突出)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 2),
                  child: Text(
                    activity.startTime ?? "待定",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOngoing ? Theme.of(context).primaryColor : Colors.grey.shade700,
                    ),
                  ),
                ),
                // 右侧内容区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activity.icon != null && activity.icon!.isNotEmpty)
                          Icon(_getIconData(activity.icon!), color: titleColor, size: 22),
                      Text(
                        activity.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (activity.location != null && activity.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 15, color: Colors.grey[600]),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                activity.location!,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (activity.description != null && activity.description!.isNotEmpty) ...[
                         const SizedBox(height: 6),
                         Text(activity.description!, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis,),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end, // 将按钮推到右边
                        children: [
                           // 导航按钮 (图4样式)
                          TextButton.icon(
                              icon: Icon(Icons.navigation_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                              label: Text("导航", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
                              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("导航功能待实现"))); },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(50,30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                // backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.05), // 可选背景
                              ),
                          ),
                          if (mode == TripMode.edit) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: onEdit,
                              child: const Text("编辑", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                               style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(50,30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                              ),
                            ),
                          ],
                          // 旅行模式下的状态切换按钮 (若需要，可在此添加)
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant': case 'food': case 'meal': return Icons.restaurant_menu_rounded;
      case 'hotel': case 'sleep': case 'accommodation': return Icons.hotel_rounded;
      case 'flight': case 'plane': return Icons.flight_takeoff_rounded;
      case 'train': return Icons.train_rounded;
      case 'bus': return Icons.directions_bus_rounded;
      case 'car': case 'taxi': case 'drive': return Icons.directions_car_rounded;
      case 'walk': return Icons.directions_walk_rounded;
      case 'museum': case 'art': return Icons.museum_rounded;
      case 'landmark': case 'sightseeing': return Icons.camera_alt_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'activity': return Icons.local_activity_rounded;
      default: return Icons.place_rounded;
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
    if (transportationMode == null && durationMinutes == null) {
      // 如果没有交通信息，可以显示一条简单的虚线或占位符
      return Container(
        height: 40, // 默认高度
        margin: const EdgeInsets.only(left: 32.0), // 与卡片内容左侧大致对齐
        alignment: Alignment.centerLeft,
        child: CustomPaint(
          painter: LineConnectorPainter(lineColor: Colors.grey.shade300),
          size: const Size(20, double.infinity), // 线条的宽度和填充父级高度
        ),
      );
    }
    
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

    return Container(
      height: 50, // 根据需要调整高度
      margin: const EdgeInsets.only(left: 32.0), // 与卡片内容左侧大致对齐，给图标和文字留空间
      alignment: Alignment.centerLeft,
      child: CustomPaint(
        painter: LineConnectorPainter(
          lineColor: Colors.grey.shade300,
          transportText: transportationMode,
          durationText: durationText.isNotEmpty ? durationText : null,
        ),
        child: Container(), // CustomPaint 需要一个 child 来确定其绘制区域
        size: const Size(100, double.infinity), // 为 Painter 提供宽度，高度将撑满父级
      ),
    );
  }
}
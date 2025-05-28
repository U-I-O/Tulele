// lib/trips/presentation/widgets/activity_card_widget.dart
import 'package:flutter/material.dart';
import '../pages/trip_detail_page.dart'; // 为了引入 Activity, TripMode, ActivityStatus (理想情况下这些应在独立文件)

// LineConnectorPainter 修改
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

    // 绘制垂直线
    // 从时间文字下方一点开始，到卡片底部上方一点结束，避免完全连接到边框
    const double linePadding = 4.0;
    canvas.drawLine(Offset(size.width / 2, linePadding), Offset(size.width / 2, size.height - linePadding), paint);

    // 绘制交通方式和时间 (如果提供)
    if (transportText != null || durationText != null) {
      final textStyle = TextStyle(color: Colors.grey[600], fontSize: 10);
      final iconColor = Colors.grey[600];
      double offsetY = size.height / 2 - 15; // 大致居中开始点
      const double textOffsetFromLine = 5.0; // 文本与线的水平偏移
      const double iconTextSpacing = 2.0; // 图标和文本之间的间距

      if (transportText != null) {
        final IconData transportIconData = transportText == '打车' ? Icons.local_taxi_outlined :
        transportText == '公交' ? Icons.directions_bus_outlined :
        transportText == '步行' ? Icons.directions_walk_outlined :
        Icons.drive_eta_outlined;

        // 绘制图标
        final iconPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(transportIconData.codePoint),
            style: TextStyle(
              fontSize: 13, // 图标大小
              fontFamily: transportIconData.fontFamily,
              package: transportIconData.fontPackage, // 处理 CupertinoIcons 等
              color: iconColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        iconPainter.layout();
        iconPainter.paint(canvas, Offset(size.width / 2 + textOffsetFromLine, offsetY));

        // 绘制交通方式文本
        final transportTextPainter = TextPainter(
          text: TextSpan(text: transportText, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        transportTextPainter.layout(maxWidth: size.width - (size.width / 2 + textOffsetFromLine + iconPainter.width + iconTextSpacing)); // 限制文本宽度
        transportTextPainter.paint(canvas, Offset(size.width / 2 + textOffsetFromLine + iconPainter.width + iconTextSpacing, offsetY + (iconPainter.height - transportTextPainter.height) / 2)); // 与图标垂直对齐

        offsetY += (iconPainter.height > transportTextPainter.height ? iconPainter.height : transportTextPainter.height) + 2; // 基于较高的元素增加偏移
      }

      if (durationText != null) {
        final durationTextPainter = TextPainter(
          text: TextSpan(text: durationText, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        durationTextPainter.layout(maxWidth: size.width - (size.width / 2 + textOffsetFromLine)); // 限制文本宽度
        // 如果上面没有transportText，则 offsetY 可能需要调整
        if (transportText == null) offsetY = size.height / 2 - (durationTextPainter.height / 2) ; // 垂直居中

        durationTextPainter.paint(canvas, Offset(size.width / 2 + textOffsetFromLine, offsetY));
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


// ActivityCard 类定义保持不变
class ActivityCard extends StatelessWidget {
  final Activity activity;
  final TripMode mode;
  final bool showConnector;
  final VoidCallback? onTap;
  final ValueChanged<ActivityStatus>? onStatusChange;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.mode,
    this.showConnector = true,
    this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor = Colors.white;
    Color textColor = Colors.black87;
    // IconData statusIcon = Icons.hourglass_empty_outlined; // 移除，不再直接使用
    Color statusIndicatorColor = Colors.grey; // 用于状态Chip的背景

    if (mode == TripMode.travel) {
      switch (activity.status) {
        case ActivityStatus.pending:
          cardColor = Colors.white;
          statusIndicatorColor = Colors.grey.shade400;
          break;
        case ActivityStatus.ongoing:
          cardColor = Theme.of(context).primaryColor.withOpacity(0.05); // 更淡的进行中背景
          textColor = Theme.of(context).primaryColorDark;
          statusIndicatorColor = Theme.of(context).primaryColor;
          break;
        case ActivityStatus.completed:
          cardColor = Colors.grey.shade100; // 完成的卡片用更浅的灰色
          textColor = Colors.grey.shade600;
          statusIndicatorColor = Colors.green.shade600;
          break;
      }
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Card(
            elevation: mode == TripMode.travel && activity.status == ActivityStatus.ongoing ? 3.0 : 1.0,
            margin: const EdgeInsets.only(bottom: 16, left: 24),
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: mode == TripMode.edit ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.description,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor,
                        decoration: activity.status == ActivityStatus.completed ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: Colors.grey[500],
                        decorationThickness: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (activity.location != null && activity.location!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(activity.location!, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
                        ],
                      ),
                    if (mode == TripMode.edit || mode == TripMode.view) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (mode == TripMode.edit)
                            TextButton(onPressed: onTap, child: const Text("编辑活动")),
                        ],
                      )
                    ],
                    if (mode == TripMode.travel) ... [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: ActivityStatus.values.map((s) {
                          bool isCurrent = activity.status == s;
                          String statusText;
                          switch(s) {
                            case ActivityStatus.pending: statusText = "待办"; break;
                            case ActivityStatus.ongoing: statusText = "进行中"; break;
                            case ActivityStatus.completed: statusText = "完成"; break;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: ChoiceChip(
                              label: Text(statusText, style: TextStyle(fontSize: 10, color: isCurrent ? Colors.white : Colors.black54)),
                              selected: isCurrent,
                              onSelected: (selected) {
                                if (selected && onStatusChange != null) {
                                  onStatusChange!(s);
                                }
                              },
                              selectedColor: statusIndicatorColor, // 使用动态的状态颜色
                              backgroundColor: Colors.grey.shade200, // 未选中时的背景色
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: Text(activity.time.split('-')[0].trim(), style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                ),
                if (showConnector)
                  Expanded(
                    child: CustomPaint(
                      painter: LineConnectorPainter(
                          lineColor: Colors.grey.shade300,
                          transportText: activity.transportToNext,
                          durationText: activity.transportDuration
                      ),
                      child: Container(), // 确保 CustomPaint 有子Widget以确定其大小
                    ),
                  )
                else
                  const SizedBox(height: 20), // 为最后一个卡片底部留白
              ],
            ),
          ),
        ),
      ],
    );
  }
}
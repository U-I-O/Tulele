import 'package:flutter/material.dart';
import '../pages/trip_detail_page.dart'; // 为了引入 Activity, TripMode, ActivityStatus, LineConnectorPainter

// 注意：为了让这个文件独立，您可能需要将 Activity, TripMode, ActivityStatus, LineConnectorPainter
// 也提取到它们自己的文件（比如在 domain/entities 或 core/utils 下），或者暂时在这里复制它们的定义。
// 为了简单起见，这里假设您已将那些定义放到了一个可访问的地方，或者暂时接受这里的引用。
// 最好的做法是将模型类（Activity, TripDay, Trip, Ticket）放到 domain/entities/ 下，
// TripMode, BottomView, ActivityStatus 这些枚举可以放到一个 common/enums.dart 或类似文件中。
// LineConnectorPainter 可以是它自己的widget文件。

// 为简化，我将LineConnectorPainter也放在这里，实际应拆分
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

    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);

    if (transportText != null || durationText != null) {
      final textStyle = TextStyle(color: Colors.grey[600], fontSize: 10);
      final iconColor = Colors.grey[600];
      double offsetY = size.height / 2 - 15;

      if (transportText != null) {
        final transportIcon = transportText == '打车' ? Icons.local_taxi_outlined :
        transportText == '公交' ? Icons.directions_bus_outlined :
        transportText == '步行' ? Icons.directions_walk_outlined :
        Icons.drive_eta_outlined;

        final iconSpan = WidgetSpan(child: Icon(transportIcon, size: 12, color: iconColor));
        final textSpan = TextSpan(text: ' $transportText', style: textStyle);
        final textPainter = TextPainter(text: TextSpan(children: [iconSpan, textSpan]), textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(size.width / 2 + 5, offsetY));
        offsetY += 14;
      }

      if (durationText != null) {
        final durationTextSpan = TextSpan(text: durationText, style: textStyle);
        final durationTextPainter = TextPainter(text: durationTextSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        durationTextPainter.layout();
        durationTextPainter.paint(canvas, Offset(size.width / 2 + 5, offsetY));
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


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
    IconData statusIcon = Icons.hourglass_empty_outlined; // 默认图标
    Color statusColor = Colors.grey;

    if (mode == TripMode.travel) {
      switch (activity.status) {
        case ActivityStatus.pending:
          cardColor = Colors.white;
          statusIcon = Icons.radio_button_unchecked_outlined;
          statusColor = Colors.grey.shade400;
          break;
        case ActivityStatus.ongoing:
          cardColor = Theme.of(context).primaryColor.withOpacity(0.1);
          textColor = Theme.of(context).primaryColorDark;
          statusIcon = Icons.radio_button_checked_outlined; // 更改为进行中图标
          statusColor = Theme.of(context).primaryColor;
          break;
        case ActivityStatus.completed:
          cardColor = Colors.grey.shade200;
          textColor = Colors.grey.shade600;
          statusIcon = Icons.check_circle_outline;
          statusColor = Colors.green.shade600;
          break;
      }
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Card(
            elevation: mode == TripMode.travel && activity.status == ActivityStatus.ongoing ? 4.0 : 1.5,
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
                          decorationColor: Colors.grey[500]
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
                              selectedColor: statusColor, // 使用动态的状态颜色
                              backgroundColor: Colors.grey.shade100,
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
                      child: Container(),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
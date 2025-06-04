// lib/trips/presentation/widgets/ticket_view_widget.dart
import 'package:flutter/material.dart';
// 导入新的票务模型
import '../../../core/models/api_user_trip_model.dart'; // ApiTicket 在这里定义

class TicketViewWidget extends StatelessWidget {
  final List<ApiTicket> tickets; // <--- 类型已正确

  const TicketViewWidget({super.key, required this.tickets});

  IconData _getTicketIcon(String? type) { // 改为 String?
    if (type == null) return Icons.confirmation_number_outlined;
    switch (type.toLowerCase()) {
      case '门票': case 'event': return Icons.local_activity_outlined;
      case '火车票': case 'train': return Icons.train_outlined;
      case '机票': case 'flight': return Icons.flight_outlined;
      case '酒店': case 'hotel': return Icons.hotel_outlined;
      default: return Icons.confirmation_number_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('本日暂无票务信息', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index]; // ticket 现在是 ApiTicket 类型
        
        String displayDate = ticket.date ?? "日期未知"; // ApiTicket.date 是 String? "YYYY-MM-DD"
        // 如果需要更友好的日期格式，可以考虑使用 intl 包进行格式化
        // 例如: final formattedDate = ticket.date != null ? DateFormat('yyyy年M月d日').format(DateTime.parse(ticket.date!)) : "日期未知";

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 统一圆角
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), // 使用主题颜色
              child: Icon(_getTicketIcon(ticket.type), color: Theme.of(context).colorScheme.primary, size: 22),
            ),
            title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              '类型: ${ticket.type} ${ticket.fileUrl != null ? "| 码号: ${ticket.fileUrl}" : ""}\n日期: $displayDate\n${ticket.details ?? "无更多详情"}', // 调整显示内容
              style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4), // 调整行高和颜色
            ),
            isThreeLine: true, // 确保有足够空间显示三行
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]), // 调整颜色
            onTap: () {
              // TODO: 实现票务详情查看逻辑，例如弹出一个对话框显示票务的完整信息或图片
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(ticket.title),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text('类型: ${ticket.type}'),
                          if (ticket.fileUrl != null) Text('码号: ${ticket.fileUrl}'),
                          Text('日期: $displayDate'),
                          if (ticket.details != null) Text('详情: ${ticket.details}'),
                          // 可以考虑在这里显示票务图片等
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('关闭'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
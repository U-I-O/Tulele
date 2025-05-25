import 'package:flutter/material.dart';
import '../pages/trip_detail_page.dart'; // 为了引入 Ticket 模型 (同样需要规划模型位置)

class TicketViewWidget extends StatelessWidget {
  final List<Ticket> tickets;

  const TicketViewWidget({super.key, required this.tickets});

  IconData _getTicketIcon(String type) {
    switch (type.toLowerCase()) {
      case '门票': return Icons.local_activity_outlined;
      case '火车票': return Icons.train_outlined;
      case '飞机票': return Icons.flight_outlined;
      case '酒店': return Icons.hotel_outlined;
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
        final ticket = tickets[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).hintColor.withOpacity(0.15),
              child: Icon(_getTicketIcon(ticket.type), color: Theme.of(context).hintColor, size: 22),
            ),
            title: Text(ticket.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              '${ticket.type} - ${ticket.dateTime.month}/${ticket.dateTime.day} ${ticket.dateTime.hour.toString().padLeft(2,'0')}:${ticket.dateTime.minute.toString().padLeft(2,'0')}\n${ticket.details}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('查看 ${ticket.name} 详情 (待实现)')));
            },
          ),
        );
      },
    );
  }
}
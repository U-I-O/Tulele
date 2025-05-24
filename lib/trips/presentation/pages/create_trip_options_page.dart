// lib/create_trip_options_page.dart (新建)
import 'package:flutter/material.dart';
import '../ai/ai_planner_page.dart'; // AI助手对话页面
import 'create_trip_details_page.dart'; // 手动创建详情页面

class CreateTripOptionsPage extends StatelessWidget {
  const CreateTripOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建行程'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '请选择日程安排方式',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 40),
            _buildOptionCard(
              context: context,
              icon: Icons.auto_awesome, // AI智能图标
              title: 'AI智能规划',
              subtitle: '通过与AI助手对话，快速生成个性化行程',
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              iconColor: Theme.of(context).primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiPlannerPage()),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              context: context,
              icon: Icons.edit_calendar_outlined, // 手动创建图标
              title: '手动创建',
              subtitle: '自己手动添加每日活动与景点安排',
              backgroundColor: Theme.of(context).hintColor.withOpacity(0.1),
              iconColor: Theme.of(context).hintColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateTripDetailsPage()),
                );
              },
            ),
            // 未来可以加入“导入图像识别”等选项
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Card(
        elevation: 0, // 使用InkWell的阴影，或自定义
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: iconColor.withOpacity(0.5), width: 1)
        ),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
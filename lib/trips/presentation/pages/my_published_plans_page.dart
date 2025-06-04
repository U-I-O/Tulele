// lib/my_published_plans_page.dart
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart'; // 确保路径正确
import '../../../core/models/api_user_trip_model.dart'; // 引入 ApiUserTrip 模型
// import '../../../core/utils/auth_utils.dart'; // 通常 ApiService 内部处理用户ID

class MyPublishedPlansPage extends StatefulWidget {
  const MyPublishedPlansPage({super.key});

  @override
  State<MyPublishedPlansPage> createState() => _MyPublishedPlansPageState();
}

class _MyPublishedPlansPageState extends State<MyPublishedPlansPage> {
  final ApiService _apiService = ApiService();
  Future<List<ApiUserTrip>>? _publishedPlansFuture;

  @override
  void initState() {
    super.initState();
    _loadPublishedPlans();
  }

  Future<void> _loadPublishedPlans() async {
    if (!mounted) return;
    setState(() {
      // 调用 ApiService 获取当前用户的所有行程，然后在 FutureBuilder 中筛选
      // 或者，如果 ApiService 有专门获取特定状态行程的方法，则调用那个
      _publishedPlansFuture = _apiService.getUserTripsForCurrentUser(
        // 可以考虑在 ApiService 中为 getUserTripsForCurrentUser 添加 publishStatus 筛选参数
        // 如果没有，就在前端筛选
      ).then((allUserTrips) {
        // 在这里筛选出“已提交审核”或“已上架/驳回”的行程
        // publishStatus: 'draft', 'pending_review', 'published', 'rejected', 'archived'
        return allUserTrips.where((trip) =>
            trip.publishStatus == 'pending_review' ||
            trip.publishStatus == 'published' ||
            trip.publishStatus == 'rejected').toList();
      });
    });
     _publishedPlansFuture?.catchError((e) {
        if(mounted) {
          print("Error loading published plans: $e");
          // FutureBuilder 会处理错误状态的显示
        }
    });
  }

  Color _getStatusColor(String status, BuildContext context) {
    switch (status) {
      case 'pending_review': // 后端模型中可能是 'pending_review'
        return Colors.orange.shade600;
      case 'published': // 后端模型中可能是 'published'
        return Colors.green.shade600;
      case 'rejected': // 后端模型中可能是 'rejected'
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.grey.shade600; // 例如 'draft' 或其他未知状态
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending_review':
        return Icons.hourglass_top_outlined;
      case 'published':
        return Icons.check_circle_outline_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知时间';
    // 可以使用 intl 包进行更复杂的格式化
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar( // 添加 AppBar 以便导航和标题
        title: const Text('我发布的方案'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w500
        ),
      ),
      body: FutureBuilder<List<ApiUserTrip>>(
        future: _publishedPlansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '加载已发布方案失败: ${snapshot.error}\n请检查网络连接并稍后重试。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined, size: 70, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('您还没有提交过任何方案进行发布', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('优秀的行程方案可以发布到市场哦！', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          } else {
            final plans = snapshot.data!;
            return RefreshIndicator( // 添加下拉刷新
              onRefresh: _loadPublishedPlans,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index]; // plan 现在是 ApiUserTrip 类型
  
                  // 获取标题，优先使用覆盖名称，然后是 UserTrip 自身的 name (如果存在，根据最新模型已移除)，最后是 planDetails 的 name
                  // 使用我们之前在 ApiUserTrip 中定义的 getter 'displayName' 是最佳实践
                  final String title = plan.displayName; 
                  final String submissionTime = _formatDateTime(plan.updatedAt ?? plan.createdAt);
                  final String status = plan.publishStatus;
                  // 获取平台价格，从 plan.planDetails (ApiTripPlan) 的 platformPrice 获取
                  final String? platformPrice = plan.planDetails?.platformPrice != null 
                      ? '¥${plan.planDetails!.platformPrice!.toStringAsFixed(2)}' 
                      : null; // 如果 planDetails 或 platformPrice 为空，则价格为 null

                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // 统一圆角
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            // 如果有专门的 "提交审核时间" 字段更好，否则用更新时间或创建时间
                            '最后更新: $submissionTime',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center, // 确保垂直居中对齐
                            children: [
                              Row(
                                children: [
                                  Icon(_getStatusIcon(status), color: _getStatusColor(status, context), size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    // 可以创建一个辅助方法将 'pending_review' 转换为 '审核中' 等显示文本
                                    _getDisplayPublishStatus(status),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status, context),
                                    ),
                                  ),
                                ],
                              ),
                              if (status == 'published' && platformPrice != null)
                                Text(
                                  '平台定价: $platformPrice',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.secondary), // 使用主题颜色
                                ),
                            ],
                          ),
                          if (status == 'pending_review')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '平台正在审核您的行程方案，预计需要1-2个工作日。审核通过后我们会为方案定价并上架至方案市场。',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                              ),
                            ),
                          if (status == 'rejected')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '抱歉，您的方案未通过审核，请查看通知中心了解详情并修改。', // TODO: 添加查看原因的入口
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error, fontStyle: FontStyle.italic),
                              ),
                            ),
                          const SizedBox(height: 12.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 根据后端 UserTrip 的实际可编辑状态来决定是否显示“编辑”按钮
                              // 例如，如果 plan.creatorId == 当前用户ID 且状态允许编辑
                              if (status == 'rejected' || status == 'draft') // 通常草稿和驳回的可以编辑
                                TextButton(
                                  onPressed: () {
                                    // TODO: 跳转到行程编辑页面，传递 plan.id (即 UserTrip ID)
                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => EditTripPage(userTripId: plan.id)));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('编辑 "${plan.userTripNameOverride}" (待实现)')),
                                    );
                                  },
                                  child: const Text('编辑'),
                                ),
                              if (status == 'published')
                                TextButton(
                                  onPressed: () { /* TODO: 查看方案表现/数据 */
                                     ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('查看 "${plan.userTripNameOverride}" 数据 (待实现)')),
                                    );
                                  },
                                  child: const Text('查看数据'),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: 跳转到行程详情页，传递 plan.id (即 UserTrip ID)
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => TripDetailPage(userTripId: plan.id)));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('查看 "${plan.userTripNameOverride}" 详情 (待实现)')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 14)
                                ),
                                child: const Text('查看'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }

  // 辅助方法，用于将后端的 publishStatus 转换为用户可读的文本
  String _getDisplayPublishStatus(String status) {
    switch (status) {
      case 'pending_review':
        return '审核中';
      case 'published':
        return '已上架';
      case 'rejected':
        return '已驳回';
      case 'draft':
        return '草稿';
      case 'archived':
        return '已归档';
      default:
        return status; // 返回原始状态，如果未知
    }
  }
}
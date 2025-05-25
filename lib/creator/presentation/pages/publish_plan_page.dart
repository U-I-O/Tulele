// lib/publish_plan_page.dart (新建)
import 'package:flutter/material.dart';

class PublishPlanPage extends StatefulWidget {
  const PublishPlanPage({super.key});

  @override
  State<PublishPlanPage> createState() => _PublishPlanPageState();
}

class _PublishPlanPageState extends State<PublishPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _allTags = ['亲子游', '海岛度假', '美食', '文化', '沙滩', '购物', '摄影', '5日游', '性价比', '深度体验'];
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
              ),
              child: Text(
                '您的行程方案将由平台审核定价，根据下载量和使用情况获得创作激励。发布优质内容，赚取更多奖励！',
                style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColorDark, height: 1.5),
              ),
            ),
            const SizedBox(height: 24.0),

            _buildSectionTitle('方案标题'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '例如：三亚海岛度假 | 亲子游玩5日行程',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入方案标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),

            _buildSectionTitle('方案描述'),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: '详细描述您的行程方案特色、适合人群、主要亮点等...',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入方案描述';
                }
                if (value.length < 50) {
                  return '描述请至少输入50个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),

            _buildSectionTitle('标签选择 (可选)'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _allTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return ChoiceChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),
            Text(
              '提示：选择合适的标签有助于用户更快找到您的方案。',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // 模拟提交审核
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('方案已提交审核 (模拟)')),
                  );
                  _titleController.clear();
                  _descriptionController.clear();
                  setState(() {
                    _selectedTags.clear();
                  });
                  // 实际应用中会调用API提交数据
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48), // 按钮撑满宽度
              ),
              child: const Text('提交审核'),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: 实现从已有方案导入或选择模板功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('从已有方案发布功能待实现')),
                  );
                },
                child: const Text('或从我的行程一键发布'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17.0,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
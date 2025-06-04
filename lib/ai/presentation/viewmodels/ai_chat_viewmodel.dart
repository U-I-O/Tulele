import 'package:flutter/material.dart';
import 'dart:math';
import 'package:tulele/ai/domain/entities/chat_message.dart';
import 'package:tulele/ai/domain/usecases/send_message_usecase.dart';
import 'package:tulele/ai/domain/usecases/generate_trip_plan_usecase.dart';
import 'package:tulele/ai/domain/usecases/modify_trip_plan_usecase.dart';
import 'dart:async';

/// AI聊天的ViewModel
class AiChatViewModel extends ChangeNotifier {
  final SendMessageUseCase _sendMessageUseCase;
  final GenerateTripPlanUseCase _generateTripPlanUseCase;
  final ModifyTripPlanUseCase _modifyTripPlanUseCase;
  
  // 聊天消息列表
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // 更细粒度的加载状态
  String _loadingStatus = '';
  String get loadingStatus => _loadingStatus;
  
  // 错误状态
  String? _error;
  String? get error => _error;

  // 当前生成的行程计划
  Map<String, dynamic>? _currentGeneratedPlan;
  Map<String, dynamic>? get currentGeneratedPlan => _currentGeneratedPlan;
  
  AiChatViewModel({
    required SendMessageUseCase sendMessageUseCase,
    required GenerateTripPlanUseCase generateTripPlanUseCase,
    required ModifyTripPlanUseCase modifyTripPlanUseCase,
  }) : 
    _sendMessageUseCase = sendMessageUseCase,
    _generateTripPlanUseCase = generateTripPlanUseCase,
    _modifyTripPlanUseCase = modifyTripPlanUseCase {
      _addInitialAiMessage();
    }
  
  /// 添加初始AI欢迎消息
  void _addInitialAiMessage() {
    _messages.add(
      ChatMessage(
        content: '您好！我是您的AI旅行助手"途乐乐"，想去哪里？可以告诉我您的目的地、预算、兴趣和时间，我会为您规划行程。',
        isUserMessage: false,
        suggestions: ['我想去三亚，5天，亲子游', '帮我规划一个北京周末文化之旅', '推荐欧洲10日游高性价比路线'],
      )
    );
    notifyListeners();
  }
  
  /// 更新加载状态
  void _updateLoadingStatus(String status) {
    _loadingStatus = status;
    notifyListeners();
  }
  
  /// 发送消息
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // 添加用户消息
    _messages.add(ChatMessage(content: message, isUserMessage: true));
    notifyListeners();
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 检查是否是请求生成或修改行程计划的消息
      bool shouldCreatePlan = _shouldGeneratePlan(message);
      bool shouldModifyPlan = _shouldModifyPlan(message);
      
      if (shouldCreatePlan) {
        // 先返回一个处理中的消息
        final processingMessage = ChatMessage(
          content: '正在为您规划行程，请稍候...',
          isUserMessage: false
        );
        _messages.add(processingMessage);
        notifyListeners();
        
        // 显示进度更新
        _updateLoadingStatus('正在联系AI服务...');
        
        // 定义一个计时器，定期更新处理状态消息，增强用户体验
        int dotCount = 0;
        Timer? progressTimer;
        progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          if (!_isLoading) {
            timer.cancel();
            return;
          }
          
          dotCount = (dotCount + 1) % 4;
          String dots = List.filled(dotCount, '.').join();
          String updatedContent;
          
          if (timer.tick < 3) {
            updatedContent = '正在为您规划行程，请稍候$dots';
          } else if (timer.tick < 6) {
            updatedContent = '正在分析目的地信息$dots\n(AI响应可能需要一点时间，请耐心等待)';
          } else if (timer.tick < 9) {
            updatedContent = '正在设计行程安排$dots\n(AI正在努力为您规划最佳行程)';
          } else if (timer.tick < 12) {
            updatedContent = '正在整合行程信息$dots\n(即将完成，请再等待片刻)';
          } else {
            updatedContent = '正在最终确认行程细节$dots\n(如果等待时间过长，您可以点击取消并尝试简化您的需求)';
          }
          
          // 更新处理中消息的内容
          final msgIndex = _messages.indexOf(processingMessage);
          if (msgIndex != -1) {
            _messages[msgIndex] = ChatMessage(
              content: updatedContent,
              isUserMessage: false
            );
            notifyListeners();
          }
        });
        
        try {
          // 直接调用API生成行程，不使用预设数据
          final plan = await _generateTripPlanUseCase.execute(message, _messages);
          
          // 取消进度计时器
          progressTimer?.cancel();
          
          // 移除处理中的消息
          _messages.remove(processingMessage);
          
          _currentGeneratedPlan = plan;
          
          _updateLoadingStatus('正在整理行程信息...');
          
          // 构建行程概要文字
          String planSummary = _buildPlanSummary(plan);
          
          // 添加计划建议消息
          _messages.add(ChatMessage.planSuggestion(
            content: planSummary,
            tripPlanData: plan,
            suggestions: ['看起来不错，采用这个方案', '我想修改一下行程', '再生成一个不同的方案'],
          ));
          
          // 添加操作按钮
          _messages.add(ChatMessage.buttons());
        } catch (e) {
          // 取消进度计时器
          progressTimer?.cancel();
          
          // 移除处理中的消息
          _messages.remove(processingMessage);
          
          _messages.add(ChatMessage(
            content: '抱歉，生成行程时遇到了问题。错误信息：${e.toString()}\n\n您可以尝试重新发送更简单的行程需求，或者稍后再试。',
            isUserMessage: false,
            suggestions: ['重试', '联系客服', '查看热门目的地'],
          ));
          
          print('AI服务错误: $e');
        } finally {
          _updateLoadingStatus('');
        }
      } else if (shouldModifyPlan && _currentGeneratedPlan != null) {
        // 添加处理消息
        final processingMessage = ChatMessage(
          content: '正在根据您的要求修改行程，请稍候...',
          isUserMessage: false
        );
        _messages.add(processingMessage);
        notifyListeners();
        
        _updateLoadingStatus('正在调整行程...');
        
        // 修改行程的进度提示计时器
        int dotCount = 0;
        Timer? progressTimer;
        progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          if (!_isLoading) {
            timer.cancel();
            return;
          }
          
          dotCount = (dotCount + 1) % 4;
          String dots = List.filled(dotCount, '.').join();
          String updatedContent;
          
          if (timer.tick < 4) {
            updatedContent = '正在根据您的要求修改行程$dots';
          } else if (timer.tick < 8) {
            updatedContent = '正在调整行程细节$dots\n(AI正在根据您的要求进行优化)';
          } else {
            updatedContent = '即将完成行程修改$dots\n(感谢您的耐心等待)';
          }
          
          // 更新处理中消息的内容
          final msgIndex = _messages.indexOf(processingMessage);
          if (msgIndex != -1) {
            _messages[msgIndex] = ChatMessage(
              content: updatedContent,
              isUserMessage: false
            );
            notifyListeners();
          }
        });
        
        try {
          // 调用修改行程用例
          final modifiedPlan = await _modifyTripPlanUseCase.execute(
            message, 
            _currentGeneratedPlan!, 
            _messages
          );
          
          // 取消进度计时器
          progressTimer?.cancel();
          
          // 移除处理中的消息
          _messages.remove(processingMessage);
          
          _currentGeneratedPlan = modifiedPlan;
          
          // 构建修改后的行程概要
          String modifiedPlanSummary = _buildPlanSummary(modifiedPlan);
          
          // 添加修改后的计划建议
          _messages.add(ChatMessage.planSuggestion(
            content: modifiedPlanSummary,
            tripPlanData: modifiedPlan,
            suggestions: ['采用修改后的方案', '还需要继续调整', '看起来不错'],
          ));
          
          // 添加操作按钮
          _messages.add(ChatMessage.buttons());
        } catch (e) {
          // 取消进度计时器
          progressTimer?.cancel();
          
          // 移除处理中的消息
          _messages.remove(processingMessage);
          
          // 如果修改失败，告知用户
          _messages.add(ChatMessage(
            content: '抱歉，修改行程时遇到问题，您可以直接在编辑模式中对行程进行调整。错误信息：${e.toString()}',
            isUserMessage: false,
            suggestions: ['重新生成行程', '联系客服'],
          ));
        } finally {
          _updateLoadingStatus('');
        }
      } else {
        // 常规聊天消息
        _updateLoadingStatus('等待AI助手回复...');
        
        // 添加临时回复指示消息
        final processingMessage = ChatMessage(
          content: '正在思考回复...',
          isUserMessage: false
        );
        _messages.add(processingMessage);
        notifyListeners();
        
        // 聊天消息的进度提示
        Timer? progressTimer;
        progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_isLoading) {
            timer.cancel();
            return;
          }
          
          if (timer.tick % 3 == 0) {
            final msgIndex = _messages.indexOf(processingMessage);
            if (msgIndex != -1) {
              _messages[msgIndex] = ChatMessage(
                content: '正在思考回复' + ('.' * ((timer.tick ~/ 3) % 4)),
                isUserMessage: false
              );
              notifyListeners();
            }
          }
        });
        
        try {
          final response = await _sendMessageUseCase.execute(message, _messages);
          
          // 取消进度计时器
          progressTimer?.cancel();
          
          // 移除处理中的消息
          _messages.remove(processingMessage);
          
          // 添加实际响应
          _messages.add(response);
        } catch (e) {
          // 取消进度计时器
          progressTimer?.cancel();
          
          // 移除处理中的消息
          _messages.remove(processingMessage);
          
          _messages.add(ChatMessage(
            content: '抱歉，无法连接到AI服务，请检查网络连接或稍后再试。错误信息：${e.toString()}',
            isUserMessage: false,
            suggestions: ['重试', '联系客服'],
          ));
          print('AI聊天错误: $e');
        } finally {
          _updateLoadingStatus('');
        }
      }
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessage(
        content: '抱歉，发生了错误：${e.toString()}',
        isUserMessage: false,
        suggestions: ['重试', '联系客服'],
      ));
      _updateLoadingStatus('');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 判断是否应该生成行程计划
  bool _shouldGeneratePlan(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('规划') || 
           lowerMessage.contains('行程') || 
           lowerMessage.contains('帮我') && (lowerMessage.contains('天') || lowerMessage.contains('游')) ||
           lowerMessage.contains('生成方案') ||
           lowerMessage.contains('旅游计划');
  }
  
  /// 判断是否应该修改行程计划
  bool _shouldModifyPlan(String message) {
    final lowerMessage = message.toLowerCase();
    return _currentGeneratedPlan != null && 
           (lowerMessage.contains('修改') || 
            lowerMessage.contains('调整') || 
            lowerMessage.contains('更改') || 
            lowerMessage.contains('换') && (lowerMessage.contains('行程') || lowerMessage.contains('方案')));
  }
  
  /// 构建行程概要描述
  String _buildPlanSummary(Map<String, dynamic> plan) {
    final StringBuffer summary = StringBuffer();
    summary.writeln('✅ 已为您生成"${plan['name'] ?? '行程'}"行程规划：');
    summary.writeln('📍 目的地：${plan['destination'] ?? '未指定目的地'}');
    
    if (plan['tags'] != null && (plan['tags'] as List).isNotEmpty) {
      summary.writeln('🏷️ 标签：${(plan['tags'] as List).join('、')}');
    }
    
    if (plan['days'] != null && (plan['days'] as List).isNotEmpty) {
      summary.writeln('⏱️ 行程天数：${(plan['days'] as List).length}天');
      summary.writeln('\n📋 行程概览：');
      
      // 只显示前3天（如果天数多的话）
      int dayCount = min(3, (plan['days'] as List).length);
      for (int i = 0; i < dayCount; i++) {
        var day = (plan['days'] as List)[i];
        summary.writeln('\n📆 第${day['dayNumber'] ?? (i+1)}天：${day['title'] ?? '行程安排'}');
        
        if (day['activities'] != null && (day['activities'] as List).isNotEmpty) {
          var activities = day['activities'] as List;
          int actCount = min(3, activities.length); // 每天最多显示3个活动
          for (int j = 0; j < actCount; j++) {
            var act = activities[j];
            summary.writeln('• ${act['time'] ?? '时间未定'} ${act['description'] ?? '活动'} @ ${act['location'] ?? '地点未定'}');
          }
          
          if (activities.length > actCount) {
            summary.writeln('• ... 等${activities.length - actCount}项活动');
          }
        } else {
          summary.writeln('• 暂无安排');
        }
      }
      
      if ((plan['days'] as List).length > dayCount) {
        summary.writeln('\n... 等${(plan['days'] as List).length - dayCount}天行程');
      }
    } else {
      summary.writeln('⚠️ 行程详情暂未生成');
    }
    
    summary.writeln('\n您可以采用此方案，或要求我做出调整。');
    
    return summary.toString();
  }
  
  /// 清除所有消息并重置状态
  void reset() {
    _messages.clear();
    _currentGeneratedPlan = null;
    _error = null;
    _isLoading = false;
    _loadingStatus = '';
    _addInitialAiMessage();
  }
  
  /// 采用当前生成的行程
  Map<String, dynamic>? adoptCurrentPlan() {
    return _currentGeneratedPlan;
  }
} 
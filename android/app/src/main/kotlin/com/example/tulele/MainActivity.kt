package com.example.tulele

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // 用于记录通知事件的TAG
    private val TAG = "TuleleNotificationDebug"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 记录日志
        Log.d(TAG, "MainActivity.onCreate 被调用")
        
        // 检查是否由通知启动
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 记录日志
        Log.d(TAG, "MainActivity.onNewIntent 被调用")
        
        // 处理可能来自通知的意图
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "handleIntent: intent 为空")
            return
        }
        
        // 输出所有 extras 以便调试
        val bundle = intent.extras
        if (bundle != null) {
            for (key in bundle.keySet()) {
                Log.d(TAG, "Intent Extra - 键: $key, 值: ${bundle.get(key)}")
            }
        }
        
        // 检查是否有 notification_action_id
        val actionId = intent.getStringExtra("action_id")
        Log.d(TAG, "通知操作ID: $actionId")
        
        // 记录启动 Activity 的 intent 的 action 和 categories
        Log.d(TAG, "Intent Action: ${intent.action}")
        val categories = intent.categories
        if (categories != null) {
            for (category in categories) {
                Log.d(TAG, "Intent Category: $category")
            }
        }
    }
    
    companion object {
        // 检查通知是否来自我们的应用
        fun verifyNotificationIntent(context: Context, intent: Intent?): Boolean {
            if (intent == null) return false
            
            // Android 12+ 需要设置 PendingIntent 的可变性
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Log.d("TuleleNotificationDebug", "运行在Android 12+, 需要检查可变性")
                // 这里只是日志，实际判断依然是基于intent内容
            }
            
            return true // 简化版，实际应用中可以添加更多验证
        }
    }
}

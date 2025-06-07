package com.example.tulele; // 确保这个包名和您的项目一致

// 根据文档，导入 BmfMapApplication
import com.baidu.mapapi.base.BmfMapApplication;

// 您的 Application 类必须继承 BmfMapApplication [cite: 9]
public class MyApplication extends BmfMapApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        // 如果您有其他的初始化代码，可以放在这里
    }
}
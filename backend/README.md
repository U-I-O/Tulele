# Flask 后端服务

这是为Flutter应用提供的Flask后端服务，使用MongoDB作为数据库。

## 环境要求

- Python 3.8+
- MongoDB 4.0+

## 安装步骤

1. 安装依赖包：

```bash
pip install -r requirements.txt
```

2. 创建环境变量文件：

将`.env-example`复制为`.env`并根据需要修改配置。

```bash
cp .env-example .env
```

3. 确保MongoDB服务已启动：

默认情况下，应用会连接到`localhost:27017`上的MongoDB服务。

## 运行服务

```bash
python run.py
```

或者使用Flask命令：

```bash
flask run
```

## API端点说明

### 测试连接
- GET `/api/test`：测试API连接是否正常

### 用户管理
- GET `/api/users`：获取所有用户
- POST `/api/users`：创建新用户，需要提供username、email、password字段

## 与Flutter前端集成

在Flutter应用中，使用HTTP客户端（如dio或http包）访问API端点。例如：

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'));

// 测试API连接
Future<void> testApi() async {
  try {
    final response = await dio.get('/test');
    print(response.data);
  } catch (e) {
    print('API连接失败: $e');
  }
}
```
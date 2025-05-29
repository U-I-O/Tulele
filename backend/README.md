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

### 用户认证
- POST `/api/auth/register`：用户注册，需要提供username、email、password字段
- POST `/api/auth/login`：用户登录，需要提供username/email和password字段
- POST `/api/auth/refresh`：刷新访问令牌，需要refresh_token
- GET `/api/auth/me`：获取当前用户个人资料，需要访问令牌
- PUT `/api/auth/update-profile`：更新用户个人资料，需要访问令牌
- POST `/api/auth/change-password`：修改密码，需要old_password和new_password字段
- POST `/api/auth/logout`：用户登出（前端实现）

### 用户管理
- GET `/api/users`：获取所有用户
- POST `/api/users`：创建新用户，需要提供username、email、password字段

### 旅行规划 (TripPlan)
- GET `/api/trips/plans`：获取旅行规划列表，支持分页和筛选
- GET `/api/trips/plans/<plan_id>`：获取特定旅行规划的详情
- POST `/api/trips/plans`：创建新的旅行规划
- PUT `/api/trips/plans/<plan_id>`：更新旅行规划
- DELETE `/api/trips/plans/<plan_id>`：删除旅行规划

### 用户旅行方案 (UserTrip)
- GET `/api/trips/user-trips?user_id=xxx`：获取用户的旅行方案列表
- GET `/api/trips/user-trips/<trip_id>`：获取特定用户旅行方案的详情
- POST `/api/trips/user-trips`：创建新的用户旅行方案
- PUT `/api/trips/user-trips/<trip_id>`：更新用户旅行方案
- POST `/api/trips/user-trips/<trip_id>/members`：添加旅行团队成员
- POST `/api/trips/user-trips/<trip_id>/messages`：添加旅行消息
- POST `/api/trips/user-trips/<trip_id>/tickets`：添加旅行票务
- POST `/api/trips/user-trips/<trip_id>/notes`：添加旅行笔记

## JWT认证说明

本API使用JWT（JSON Web Token）进行用户认证。客户端需要：

1. 调用登录或注册接口获取`access_token`和`refresh_token`
2. 在后续请求的头部添加`Authorization: Bearer <access_token>`
3. 当`access_token`过期时，使用`refresh_token`调用刷新接口获取新的`access_token`
4. 登出时，前端只需要删除保存的令牌


## 数据模型

### TripPlan (旅行规划)
```json
{
  "id": "5f9d88b9e8a8f31a5c7a9b5a",
  "name": "北京三日游",
  "origin": "上海",
  "destination": "北京",
  "startDate": "2023-06-01",
  "endDate": "2023-06-03",
  "tags": ["历史", "文化", "美食"],
  "description": "北京三日精华游，体验历史与现代交织的首都风采",
  "coverImage": "https://example.com/images/beijing_cover.jpg",
  "days": [
    {
      "date": "2023-06-01",
      "activities": [
        {
          "id": "act1",
          "title": "参观故宫",
          "location": "故宫博物院",
          "startTime": "09:00",
          "endTime": "12:00",
          "note": "记得带身份证",
          "transportation": "地铁"
        },
        {
          "id": "act2",
          "title": "午餐",
          "location": "簋街",
          "startTime": "12:30",
          "endTime": "14:00",
          "note": "尝试北京特色小吃",
          "transportation": "打车"
        }
      ]
    }
  ]
}
```

### UserTrip (用户旅行方案)
```json
{
  "id": "5f9d88b9e8a8f31a5c7a9b5b",
  "plan_id": "5f9d88b9e8a8f31a5c7a9b5a",
  "members": [
    {
      "userId": "user1",
      "name": "张三",
      "avatarUrl": "https://example.com/avatar1.jpg",
      "role": "leader"
    }
  ],
  "messages": [
    {
      "id": "msg1",
      "senderId": "system",
      "content": "行程已创建",
      "timestamp": "2023-05-20T10:00:00",
      "type": "system"
    }
  ],
  "tickets": [
    {
      "id": "ticket1",
      "type": "flight",
      "title": "上海-北京航班",
      "code": "MU5137",
      "date": "2023-06-01",
      "details": "浦东机场T2 10:00起飞"
    }
  ],
  "status": "planning",
  "feeds": [
    {
      "id": "feed1",
      "content": "北京天气预报：晴，18-25°C",
      "timestamp": "2023-05-20T10:05:00",
      "type": "weather"
    }
  ],
  "notes": [
    {
      "id": "note1",
      "content": "记得带充电宝",
      "timestamp": "2023-05-20T10:10:00"
    }
  ]
}
```

### User (用户)
```json
{
  "id": "5f9d88b9e8a8f31a5c7a9b5c",
  "username": "zhangsan",
  "email": "zhangsan@example.com",
  "created_at": "2023-05-20 10:00:00",
  "updated_at": "2023-05-20 10:00:00"
}
```
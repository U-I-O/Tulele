# Flask 后端服务 (途乐乐)

这是为 Flutter 应用"途乐乐"提供的 Flask 后端服务，使用 MongoDB 作为数据库。

## 核心数据模型关系

* **TripPlan (旅行规划)**: 存储可复用的、核心的行程规划内容，如目的地、天数、每日活动等。可以被视为行程的"蓝图"或"模板"。存储在 `tripPlans` 集合中。
* **UserTrip (用户旅行方案)**: 代表用户对一个 `TripPlan` 的具体使用实例或一个从头创建的个人行程记录。它通过 `plan_id` 字段关联到一个 `TripPlan` 文档，并包含用户特定的信息，如团队成员、个人票务、行程笔记、发布状态 (`publish_status`) 和旅行状态 (`travel_status`)。存储在 `userTrips` 集合中。
* **数据获取**: 当客户端请求 `UserTrip` 数据时，API 通常会通过数据库的 `$lookup` 操作将关联的 `TripPlan` 的详细信息嵌入到 `UserTrip` 对象中（例如，作为一个名为 `plan_details` 的字段），以便前端高效获取数据。

## 环境要求

- Python 3.8+
- MongoDB 4.0+

## 安装步骤

1. 安装依赖包：
   ```bash
   pip install -r requirements.txt
   ```

2. 创建环境变量文件：
   将 `.env-example` 复制为 `.env` 并根据需要修改配置。
   ```bash
   cp .env-example .env
   ```

3. 确保 MongoDB 服务已启动（默认连接 `localhost:27017`）。

## 运行服务

```bash
python run.py
```

或者使用 Flask 命令：

```bash
flask run
```

## API 端点说明

### 认证 (Auth)

#### POST /api/auth/register
用户注册。

请求体: `{ "username": "str", "email": "str", "password": "str" }`

#### POST /api/auth/login
用户登录。

请求体: `{ "username_or_email": "str", "password": "str" }`

#### POST /api/auth/refresh
刷新访问令牌。

头部: `Authorization: Bearer <refresh_token>`

#### GET /api/auth/me
获取当前用户信息。

头部: `Authorization: Bearer <access_token>`

#### PUT /api/auth/update-profile
更新用户信息。

头部: `Authorization: Bearer <access_token>`

请求体: 包含要更新的字段 (例如, bio, avatarUrl)。

#### POST /api/auth/change-password
修改密码。

头部: `Authorization: Bearer <access_token>`

请求体: `{ "old_password": "str", "new_password": "str" }`

### 旅行规划模板 (TripPlan)

管理可复用的行程计划模板。

#### GET /api/trips/plans
获取旅行规划模板列表 (例如，用于方案市场的"发现模板"功能)。

查询参数:
- `limit` (int, 默认 20): 每页数量。
- `skip` (int, 默认 0): 跳过数量，用于分页。
- `destination` (str): 按目的地模糊搜索。
- `tags` (str, 逗号分隔): 按标签筛选 (例如, tags=亲子,海岛)。
- `sort_by` (str): 排序依据 (例如, rating, updated_at, popularity)。
- `isPublicTemplate=true` (bool, 可选): 筛选公共模板。

#### GET /api/trips/plans/<plan_id>
获取特定旅行规划模板的详情。

#### POST /api/trips/plans
创建新的旅行规划模板。

头部: `Authorization: Bearer <access_token>`

请求体: TripPlan 对象 (包含 name, origin, destination, startDate, endDate, days 等)。

成功响应: 201 Created，返回创建的 TripPlan 对象 (包含 _id)。

#### PUT /api/trips/plans/<plan_id>
更新现有的旅行规划模板的核心内容。

头部: `Authorization: Bearer <access_token>`

请求体: 包含要更新的 TripPlan 字段。

#### DELETE /api/trips/plans/<plan_id>
删除旅行规划模板。

头部: `Authorization: Bearer <access_token>`

注意: 如果有 UserTrip 正在引用此 plan_id，可能需要特殊处理（如不允许删除或软删除）。

### 用户旅行方案 (UserTrip)

管理用户具体的行程实例。

#### GET /api/trips/user-trips
获取用户旅行方案列表。

头部: `Authorization: Bearer <access_token>` (通常需要)

**场景1**: 获取当前用户的行程 (我的行程夹)

查询参数: `user_id=<current_user_id>` (必需), `populate_plan=true` (可选, 默认true)。

**场景2**: 获取方案市场的已发布行程

查询参数: `publish_status=published` (必需), `populate_plan=true` (默认true), limit, skip, destination (基于plan_details), tags (基于plan_details), sort_by (如 rating, popularity - 这些字段可能需要在UserTrip中也存在或通过聚合计算)。

#### GET /api/trips/user-trips/<user_trip_id>
获取特定用户旅行方案的详情。

头部: `Authorization: Bearer <access_token>`

查询参数: `populate_plan=true` (可选, 默认true)。

#### POST /api/trips/user-trips
创建新的用户旅行方案。

头部: `Authorization: Bearer <access_token>`

请求体:

**A) 基于现有 TripPlan 模板**:

```json
{
  "plan_id": "existing_trip_plan_object_id",
  "creator_id": "current_user_id", // 由后端从JWT获取或前端明确提供
  "user_trip_name_override": "我的三亚之旅", // 可选
  "publish_status": "draft", // 可选, 默认 'draft'
  "travel_status": "planning", // 可选, 默认 'planning'
  "members": [/* 初始成员, 创建者会自动加入 */]
}
```

**B) 从头创建 (同时定义计划内容)**:

```json
{
  "creator_id": "current_user_id",
  // TripPlan 的所有字段:
  "name": "我的全新日本自由行",
  "destination": "日本东京",
  "startDate": "2025-10-01",
  "endDate": "2025-10-07",
  "tags": ["美食", "购物"],
  "days": [ /* ...每日活动详情... */ ],
  // UserTrip 的其他字段:
  "publish_status": "draft",
  "members": []
}
```

在此情况下，后端会先创建一个新的 TripPlan，然后用其 ID 创建 UserTrip。

成功响应: 201 Created，返回创建的 UserTrip 对象 (包含 _id 和 plan_details)。

#### PUT /api/trips/user-trips/<user_trip_id>
更新用户旅行方案的特定属性。

头部: `Authorization: Bearer <access_token>`

请求体: 包含要更新的 UserTrip 字段，如 user_trip_name_override, publish_status, travel_status。不用于修改核心计划内容（天数/活动），核心计划内容请通过 PUT /api/trips/plans/<plan_id> 更新。

#### DELETE /api/trips/user-trips/<user_trip_id>
删除用户旅行方案。

头部: `Authorization: Bearer <access_token>`

### UserTrip 子资源

#### POST /api/trips/user-trips/<user_trip_id>/members
添加团队成员。

请求体: `{ "userId": "str", "name": "str", "role": "str" }`

#### POST /api/trips/user-trips/<user_trip_id>/messages
添加消息。

请求体: `{ "senderId": "str (通常是当前用户)", "content": "str", "type": "str" }`

#### POST /api/trips/user-trips/<user_trip_id>/tickets
添加票务。

请求体: `{ "type": "str", "title": "str", "details": "str", ... }`

#### POST /api/trips/user-trips/<user_trip_id>/notes
添加行程实例的笔记。

请求体: `{ "content": "str" }`

## JWT认证

API 使用 JWT 进行用户认证。客户端需在请求头中添加 `Authorization: Bearer <access_token>`。

## 数据模型 (主要结构)

### User (用户 - users 集合)

```json
{
  "_id": "ObjectId(...)",
  "username": "string",
  "email": "string (unique)",
  "password_hash": "string",
  "avatarUrl": "string (optional)",
  "bio": "string (optional)",
  "created_at": "ISODateTime",
  "updated_at": "ISODateTime"
}
```

### TripPlan (旅行规划核心 - tripPlans 集合)

```json
{
  "_id": "ObjectId(...)",
  "name": "string (行程规划名称/模板名称)",
  "origin": "string (可选, 出发地)",
  "destination": "string (可选, 主要目的地)",
  "startDate": "ISODateTime (可选, YYYY-MM-DD)",
  "endDate": "ISODateTime (可选, YYYY-MM-DD)",
  "tags": ["string"],
  "description": "string (可选, 行程简介)",
  "coverImage": "string (可选, URL)",
  "days": [
    {
      "day_number": "number (可选, 第几天)",
      "date": "ISODateTime (可选, YYYY-MM-DD)",
      "activities": [
        {
          "id": "string (可选, 活动的唯一标识, 便于更新)",
          "title": "string (活动标题/描述)",
          "location": "string (可选)",
          "startTime": "string (可选, HH:MM)",
          "endTime": "string (可选, HH:MM)",
          "note": "string (可选, 活动备注)",
          "transportation": "string (可选, 到下一活动的交通)"
        }
      ],
      "notes": "string (可选, 当日行程备注)"
    }
  ],
  "creator_id": "ObjectId (可选, 模板创建者用户ID)",
  "isPublicTemplate": "boolean (可选, 是否为公开模板)",
  "rating": "number (可选, 模板评分)",
  "reviewCount": "number (可选, 模板评论数)",
  "price_if_published_by_creator": "number (可选, 模板的建议售价)",
  "created_at": "ISODateTime",
  "updated_at": "ISODateTime"
}
```

### UserTrip (用户旅行方案实例 - userTrips 集合)

```json
{
  "_id": "ObjectId(...)",
  "plan_id": "ObjectId (关联到 tripPlans._id)",
  "creator_id": "ObjectId (创建此 UserTrip 实例的用户ID)",
  "creator_name": "string (反规范化, 创建者用户名)",
  "creator_avatar": "string (反规范化, 创建者头像URL)",
  "user_trip_name_override": "string (可选, 用户对此行程实例的自定义名称)",
  "members": [
    {
      "userId": "ObjectId (成员的用户ID)",
      "name": "string (成员名称)",
      "avatarUrl": "string (可选, 成员头像)",
      "role": "string (如 'owner', 'editor', 'viewer')"
    }
  ],
  "messages": [
    {
      "id": "string (消息ID)",
      "senderId": "ObjectId (发送者用户ID)",
      "content": "string",
      "timestamp": "ISODateTime",
      "type": "string (如 'text', 'image', 'system')"
    }
  ],
  "tickets": [
    {
      "id": "string (票务ID)",
      "type": "string (如 'flight', 'hotel', 'train', 'event')",
      "title": "string",
      "code": "string (可选, 票号/预订号)",
      "date": "string (可选, YYYY-MM-DD 或 ISODateTime)",
      "details": "string (可选, 更多详情)"
    }
  ],
  "feeds": [ /* 动态信息流对象数组 */ ],
  "notes": [ /* 行程实例级别的笔记对象数组 */ ],
  "publish_status": "string ('draft', 'pending_review', 'published', 'rejected', 'archived')",
  "travel_status": "string ('planning', 'traveling', 'completed')",
  "price_when_published": "number (可选, 如果此 UserTrip 发布到市场，用户设定的价格)",
  "user_rating_for_plan": "number (可选, 用户对此计划内容的个人评分)",
  "user_review_for_plan": "string (可选, 用户对此计划内容的个人评价)",
  "created_at": "ISODateTime",
  "updated_at": "ISODateTime",

  // 当API返回且 populate_plan=true 时，会包含此字段:
  "plan_details": { 
    // TripPlan 文档的完整内容 (除了 _id)
    "name": "北京三日游计划", 
    // ... TripPlan 的其他所有字段 ...
  }
}
```
        
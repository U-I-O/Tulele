# 旅行数据结构设计说明

本说明文档用于描述 trips 模块中旅行相关数据的结构设计，涵盖旅行规划（TripPlan）、用户旅行方案（UserTrip）及其子结构。

## 1. TripPlan（旅行规划）
用于描述一个可被复用的旅行方案，包含基础信息、标签、每日活动等。

字段说明：
- id: string，唯一标识
- name: string，行程名称
- origin: string，出发地
- destination: string，目的地
- startDate: Date，开始日期
- endDate: Date，结束日期
- tags: List<string>，特征标签
- description: string，行程简介
- days: List<TripDay>，每日行程安排

### TripDay
- date: Date，日期
- activities: List<TripActivity>，当天活动列表

### TripActivity
- id: string，唯一标识
- title: string，活动标题
- location: string，活动地点
- startTime: string（如09:00），开始时间
- endTime: string（如10:00），结束时间
- note: string，备注
- transportation: TransportationMode，交通方式（如步行、地铁、打车等，表示到达该活动的方式，若有前序活动则为两个活动间的交通方式）

## 2. UserTrip（用户旅行方案）
基于 TripPlan，包含用户个性化内容，如团队成员、消息流、票夹、笔记等。

字段说明：
- id: string，唯一标识
- plan: TripPlan，引用的旅行规划
- members: List<UserTripMember>，团队成员
- messages: List<UserTripMessage>，消息流（AI对话、推送等）
- tickets: List<UserTicket>，票务凭证
- status: string，方案状态（如进行中、已完成等）
- feeds: List<UserTripFeed>，信息流（如AI推送、动态等）
- notes: List<UserTripNote>，用户笔记

### UserTripMember
- userId: string，用户ID
- name: string，成员姓名
- avatarUrl: string，头像
- role: string，角色（如队长、成员等）

### UserTripMessage
- id: string，唯一标识
- senderId: string，发送者ID
- content: string，消息内容
- timestamp: Date，时间戳
- type: string，消息类型（ai, system, user）

### UserTicket
- id: string，唯一标识
- type: string，票据类型（flight, train, hotel等）
- title: string，票据标题
- code: string，票据编号
- date: Date，日期
- details: string，详细信息

### UserTripFeed
- id: string，唯一标识
- content: string，内容
- timestamp: Date，时间戳
- type: string，类型

### UserTripNote
- id: string，唯一标识
- content: string，内容
- timestamp: Date，时间戳

## 3. Mock数据格式
mock_trip_plans.json 采用 JSON 数组形式，字段与 TripPlan 结构一致，便于前端直接读取和解析。

如需扩展 UserTrip、消息流、票夹等 mock 数据，可参考上述结构补充。
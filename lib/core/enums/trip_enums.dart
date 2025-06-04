// lib/core/enums/trip_enums.dart

// 用于表示行程详情页的不同操作模式
enum TripMode {
  view,   // 查看模式
  edit,   // 编辑模式
  travel  // 旅行模式（正在进行中）
}

// 用于表示行程详情页底部切换的不同视图
enum BottomView {
  itinerary, // 行程单视图
  map,       // 地图视图
  tickets    // 票夹视图（或其他如成员、笔记等 UserTrip 特有信息视图）
}

// 用于表示单个活动在旅行模式下的前端UI状态
// 注意：这个状态目前主要用于前端UI展示，
// ApiActivityFromUserTrip 模型本身（从后端获取时）不直接包含这个字段。
// 您需要在 _TripDetailPageState 中管理每个活动的这个UI状态。
enum ActivityStatus {
  pending,   // 待办
  ongoing,   // 进行中
  completed  // 已完成
}

// 您可以根据需要在此文件中添加其他项目中共享的枚举类型
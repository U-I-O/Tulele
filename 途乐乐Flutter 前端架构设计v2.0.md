# 途乐乐智能AI旅游助理 Flutter 前端架构设计

## 1. 概述

本文档旨在描述途乐乐智能AI旅游助理 Flutter 应用的前端架构设计，旨在构建一个模块化、可维护、可扩展且易于测试的应用。架构设计遵循 Flutter 社区推荐的分层架构和状态管理实践，并结合产品设计书中的核心功能需求进行细化。

## 2. 架构分层

应用采用清晰的分层架构，将代码划分为以下主要层次：

*   **Presentation Layer (UI 层):** 负责构建用户界面，包括页面和组件。处理用户交互和 UI 状态，通过观察 Domain 层暴露的状态来更新 UI，并通过调用 Domain 层的方法触发业务逻辑。
*   **Domain Layer (业务逻辑层):** 包含应用的核心业务逻辑、状态管理和用例。协调 Presentation 层和 Data 层，处理业务规则、管理应用状态，并定义与 Data 层交互的接口 (Repositories)。
*   **Data Layer (数据层):** 负责处理所有数据源的交互，包括远程 API、本地存储等。实现 Domain 层定义的 Repository 接口，将原始数据转换为 Domain 层所需的数据模型。

这种分层有助于实现关注点分离，提高代码的可测试性和可维护性。

## 3. 文件结构

`lib` 目录按功能模块进行组织，每个模块内部再按架构分层进行细化：

```
lib/
├── ai/
│   ├── data/
│   │   ├── datasources/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── pages/
│       │   └── ai_planner_page.dart
│       └── widgets/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── widgets/
├── creator/
│   ├── data/
│   │   ├── datasources/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── pages/
│       │   ├── creator_center_page.dart
│       │   ├── creator_earnings_page.dart
│       │   └── publish_plan_page.dart
│       └── widgets/
├── main.dart
├── market/
│   ├── data/
│   │   ├── datasources/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── pages/
│       │   ├── plan_details_page.dart
│       │   └── solution_market_page.dart
│       └── widgets/
├── profile/
│   ├── data/
│   │   ├── datasources/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── pages/
│       │   ├── notification_center_page.dart
│       │   └── profile_page.dart
│       └── widgets/
└── trips/
    ├── data/
    │   ├── datasources/
    │   │   ├── trip_remote_data_source.dart
    │   │   └── trip_local_data_source.dart
    │   ├── models/
    │   │   └── trip_model.dart
    │   └── repositories/
    │       └── trip_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── trip.dart
    │   ├── repositories/
    │   │   └── trip_repository.dart
    │   └── usecases/
    │       ├── create_trip.dart
    │       ├── get_trips.dart
    │       └── update_trip.dart
    └── presentation/
        ├── pages/
        │   ├── my_trips_page.dart
        │   ├── create_trip_options_page.dart
        │   ├── create_trip_details_page.dart
        │   ├── itinerary_editor_page.dart
        │   └── my_published_plans_page.dart
        ├── widgets/
        │   └── trip_card_widget.dart
        └── blocs/ (或 cubits/ 或 providers/)
            └── trips_bloc.dart
```

## 4. 页面功能与跳转关系

根据设计书，主要页面及其功能和跳转关系如下：

*   **功能模块划分：**
    *   **行程模块 (Trips)**: 包含用户行程的创建、管理、编辑、查看等功能。
    *   **AI 模块 (AI)**: 包含 AI 智能行程规划功能。
    *   **市场模块 (Market)**: 包含方案市场、方案详情等功能。
    *   **个人中心模块 (Profile)**: 包含个人信息、消息中心等功能。
    *   **创作者模块 (Creator)**: 包含创作者中心、发布方案、创作收益等功能。

*   **模块内部结构规划：**
    每个模块 (`ai`, `creator`, `market`, `profile`, `trips`) 都将遵循分层架构，包含以下子目录：
    *   **presentation/**: 负责构建用户界面，包括页面和组件。处理用户交互和 UI 状态，通过观察 Domain 层暴露的状态来更新 UI，并通过调用 Domain 层的方法触发业务逻辑。
        *   **pages/**: 存放页面级别的 Widget。
        *   **widgets/**: 存放可复用的 UI 组件。
        *   **blocs/** 或 **cubits/** 或 **providers/**: 存放状态管理相关的逻辑文件 (根据选择的状态管理方案，例如 BLoC, Cubit, Riverpod)。
    *   **domain/**: 包含应用的核心业务逻辑、状态管理和用例。协调 Presentation 层和 Data 层，处理业务规则、管理应用状态，并定义与 Data 层交互的接口 (Repositories)。
        *   **entities/**: 存放业务实体类。
        *   **repositories/**: 存放 Repository 接口定义，定义业务逻辑层与数据层交互的契约。
        *   **usecases/**: 存放业务用例，封装具体的业务逻辑操作。
    *   **data/**: 负责处理所有数据源的交互，包括远程 API、本地存储等。实现 Domain 层定义的 Repository 接口，将原始数据转换为 Domain 层所需的数据模型。
        *   **datasources/**: 存放数据源实现，例如 `remote_data_source.dart` (API 调用), `local_data_source.dart` (本地存储)。
        *   **repositories/**: 存放 Repository 接口的具体实现，负责协调不同数据源获取数据并转换为 Domain 层实体。
        *   **models/**: 存放数据模型类，用于数据源与 Repository 之间的数据转换。

*   **Core 模块 (Core):**
    *   **constants/**: 存放应用级别的常量，例如 API 地址、颜色、字体等。
    *   **errors/**: 存放自定义错误类和异常处理逻辑。
    *   **utils/**: 存放应用级别的工具类，例如日期格式化、网络工具等。
    *   **widgets/**: 存放应用级别的通用 Widget，例如加载指示器、自定义按钮等。

*   **文件结构示例 (以 Trips 模块为例):**

```
lib/
├── trips/
    ├── data/
    │   ├── datasources/
    │   │   ├── trip_remote_data_source.dart
    │   │   └── trip_local_data_source.dart
    │   ├── models/
    │   │   └── trip_model.dart
    │   └── repositories/
    │       └── trip_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── trip.dart
    │   ├── repositories/
    │   │   └── trip_repository.dart
    │   └── usecases/
    │       ├── create_trip.dart
    │       ├── get_trips.dart
    │       └── update_trip.dart
    └── presentation/
        ├── pages/
        │   ├── my_trips_page.dart
        │   ├── create_trip_options_page.dart
        │   ├── create_trip_details_page.dart
        │   ├── itinerary_editor_page.dart
        │   └── my_published_plans_page.dart
        ├── widgets/
        │   └── trip_card_widget.dart
        └── blocs/ (或 cubits/ 或 providers/)
            └── trips_bloc.dart
```

这份文档提供了一个基础的前端架构框架，具体实现细节和技术选型可以根据项目进展和团队情况进行调整和完善。

## 4. 页面功能与跳转关系

根据设计书，主要页面及其功能和跳转关系如下：

*   **`main.dart`:** 应用的入口，负责初始化应用、配置路由和全局状态管理。
*   **首页 (行程夹) (`my_trips_page.dart`):**
    *   **功能:** 展示用户的行程列表（便签式卡片），提供创建/导入行程的入口。
    *   **跳转:**
        *   点击行程卡片 -> 行程详情页 (浏览模式)
        *   点击创建/导入行程入口 -> 创建行程选项页 (`create_trip_options_page.dart`)
        *   底部导航栏 -> 方案市场、消息中心、个人中心
*   **创建行程选项页 (`create_trip_options_page.dart`):**
    *   **功能:** 提供 AI 对话、手动编辑、图片识别三种创建行程的方式。
    *   **跳转:**
        *   选择 AI 对话 -> AI 规划页 (`ai_planner_page.dart`)
        *   选择手动编辑 -> 创建行程详情页 (`create_trip_details_page.dart`)
        *   选择图片识别 -> 图片识别处理页 (待定)
*   **创建行程详情页 (`create_trip_details_page.dart`):**
    *   **功能:** 手动填写行程基本信息（名称、日期、目的地等）。
    *   **跳转:**
        *   填写完成后 -> 行程编辑器页 (`itinerary_editor_page.dart`)
*   **AI 规划页 (`ai_planner_page.dart`):**
    *   **功能:** 通过 AI 对话生成行程方案，展示 AI 推荐的服务卡片。
    *   **跳转:**
        *   接受 AI 方案 -> 行程编辑器页 (`itinerary_editor_page.dart`)
*   **行程编辑器页 (`itinerary_editor_page.dart`):**
    *   **功能:** 多视图行程编辑（文字笔记/地图可视化），支持添加、修改、删除行程活动，管理票夹。
    *   **跳转:**
        *   保存行程 -> 我的行程列表页 (`my_trips_page.dart`)
        *   点击票夹入口 -> 票夹详情页 (待定)
*   **方案市场页 (`solution_market_page.dart`):**
    *   **功能:** 展示可购买的行程方案列表，支持多维度筛选和搜索。
    *   **跳转:**
        *   点击方案卡片 -> 方案详情页 (`plan_details_page.dart`)
*   **方案详情页 (`plan_details_page.dart`):**
    *   **功能:** 展示行程方案的详细信息、用户评价，提供购买入口。
    *   **跳转:**
        *   购买成功后 -> 导入到我的行程列表 (`my_trips_page.dart`) 或直接进入浏览模式 (待定)
*   **个人中心页 (`profile_page.dart`):**
    *   **功能:** 展示用户信息，提供设置、消息中心、创作者中心等入口。
    *   **跳转:**
        *   点击消息中心 -> 消息中心页 (`notification_center_page.dart`)
        *   点击创作者中心 -> 创作者中心页 (`creator_center_page.dart`)
        *   点击设置等入口 -> 相应设置页面 (待定)
*   **消息中心页 (`notification_center_page.dart`):**
    *   **功能:** 展示系统通知、私信等消息列表。
    *   **跳转:**
        *   点击消息 -> 消息详情页 (待定)
*   **创作者中心页 (`creator_center_page.dart`):**
    *   **功能:** 包含“发布方案”、“我的方案”、“创作收益”等 Tab 页面，展示创作者数据。
    *   **子页面/Tab:**
        *   发布方案页 (`publish_plan_page.dart`): 填写方案信息并提交审核。
        *   我的方案页 (`my_published_plans_page.dart`): 查看已发布和审核中的方案。
        *   创作收益页 (`creator_earnings_page.dart`): 查看收益数据和提现。
    *   **跳转:**
        *   在发布方案页提交 -> 我的方案页
*   **旅行模式:**
    *   **功能:** 基于时空语境提供实时服务推送、票务自动提取、团队位置共享等。
    *   **进入:** 从行程详情页 (浏览模式) 点击“出发”按钮进入。
    *   **退出:** 结束旅行或手动退出。
*   **团队旅行:**
    *   **功能:** 多人共享行程，位置共享，团队聊天，服务推荐优化。
    *   **进入:** 从行程详情页 (浏览模式) 点击“邀请”按钮，邀请好友加入。

## 5. 状态管理

推荐使用 **Riverpod** 或 **BLoC** 进行状态管理。它们能够很好地支持分层架构和模块化，使状态逻辑独立于 UI，易于测试和维护。

## 6. 路由管理

推荐使用 **go_router** 进行页面导航管理，它支持声明式路由和深层链接，与模块化结构兼容良好。

## 7. 依赖注入

可以考虑使用 **get_it** 或 **flutter_riverpod** (如果选择 Riverpod) 进行依赖注入，方便管理 Repository、API Service 等依赖项。

## 8. 编码规范与测试

*   遵循 Dart 和 Flutter 官方编码规范，使用 `flutter_lints` 进行代码静态分析。
*   为 Domain 层的业务逻辑编写单元测试。
*   为 Presentation 层的关键 Widgets 编写 Widget 测试。

这份文档提供了一个基础的前端架构框架，具体实现细节和技术选型可以根据项目进展和团队情况进行调整和完善。
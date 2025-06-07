# 途乐乐智能AI旅游助理 Flutter 项目

## 项目概况

本项目是“途乐乐智能AI旅游助理”应用的 Flutter 前端部分，旨在构建一个模块化、可维护、可扩展且易于测试的应用。项目遵循清晰的分层架构（Presentation, Domain, Data），并按功能模块（行程、AI、市场、个人中心、创作者）进行组织。

当前处于原型开发阶段，主要关注前端界面的实现和交互逻辑。后端接口将预留，数据使用模拟数据并封装在单独的文件夹中。

## 架构设计

详细的架构设计文档请参考：<mcfile name="# 途乐乐智能AI旅游助理 Flutter 前端架构设计.md" path="e:\code\FlutterProj\flutter_tule_new\# 途乐乐智能AI旅游助理 Flutter 前端架构设计.md"></mcfile>

主要特点包括：

- **分层架构:** Presentation, Domain, Data 三层分离，实现关注点分离。
- **模块化:** 代码按功能模块（Trips, AI, Market, Profile, Creator）组织。
- **Core 模块:** 包含跨模块共享的基础组件、工具类、常量和错误处理。
- **状态管理:** 推荐使用 Riverpod 或 BLoC。
- **路由管理:** 推荐使用 go_router。
- **依赖注入:** 推荐使用 get_it 或 flutter_riverpod。

## 文件结构

项目主要文件结构如下：

```
lib/
├── ai/             # AI 智能行程规划模块
│   ├── data/
│   ├── domain/
│   └── presentation/
├── core/           # 核心模块 (常量、错误、工具、通用组件)
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── widgets/
├── creator/        # 创作者模块
│   ├── data/
│   ├── domain/
│   └── presentation/
├── market/         # 方案市场模块
│   ├── data/
│   ├── domain/
│   └── presentation/
├── profile/        # 个人中心模块
│   ├── data/
│   ├── domain/
│   └── presentation/
├── trips/          # 行程模块
│   ├── data/
│   ├── domain/
│   └── presentation/
└── main.dart       # 应用入口

# 其他重要文件
├── .gitignore      # Git 忽略文件配置
├── analysis_options.yaml # Dart/Flutter 代码分析配置
├── pubspec.yaml    # 项目依赖管理文件
├── pubspec.lock    # 项目依赖锁定文件
├── README.md       # 项目说明文件
└── # 途乐乐智能AI旅游助理 Flutter 前端架构设计.md # 架构设计文档
```

## 使用方式

1.  **克隆仓库:**
    ```bash
    git clone <仓库地址>
    cd flutter_tule_new
    ```

2.  **安装依赖:**
    ```bash
    flutter pub get
    ```

3.  **运行项目:**
    ```bash
    flutter run
    ```

## 模拟数据

模拟数据将统一封装在 `lib/data/mock/` 目录下（待创建），方便后续与真实后端接口对接时进行替换。

## 协同开发

请确保遵循 `.gitignore` 文件中的规则，避免提交不必要的文件。在提交代码前，请运行 `flutter analyze` 和 `flutter format .` 进行代码检查和格式化。

## 更多资源

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart 官方文档](https://dart.dev/)

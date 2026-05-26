# SA Todo

SA Todo 是一款采用 **iOS 毛玻璃风格 (Glassmorphism)** 打造的个人待办事项管理应用。项目以 Flutter 为核心构建，遵循 **Feature-First Clean Architecture** 规范，采用 **Local-First (本地优先)** 策略进行数据存储和云端同步。

## ✨ 核心特性

- **极致毛玻璃美学**：全局支持 iOS 级别的精美毛玻璃效果、磨砂质感卡片与自适应黑白主题。
- **本地优先体验 (Local-First)**：采用 Drift (SQLite) 作为核心数据存储中枢进行秒级应用响应，允许在完全断网的环境下流畅进行增删改查。
- **平滑双向同步**：在网络连通时支持与您的独立后端悄无声息地进行无缝同步。
- **响应式状态管理**：基于 Riverpod 架构，状态共享更具安全性与可测试性。
- **严格规范标准**：0 错误、0 Warning，严苛遵守最新的 Dart 代码规范。

## 🛠 技术栈

- 框架：[Flutter](https://flutter.dev/) / Dart 3
- 状态管理：[Riverpod](https://riverpod.dev/) (`flutter_riverpod`, `riverpod_annotation`)
- 路由系统：[go_router](https://pub.dev/packages/go_router)
- 本地数据库：[Drift (sqlite3)](https://drift.simonbinder.eu/)
- 网络请求：[Dio](https://pub.dev/packages/dio)
- 动画交互：[flutter_animate](https://pub.dev/packages/flutter_animate)

---

## 🚀 快速开始

### 运行环境前置要求

确保你的开发环境中已经正确安装：
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (推荐版本 `3.10.x` 及以上)
- 对应的平台开发工具（Xcode 用于 iOS / MacOS 测试，Android Studio 用于 Android 测试）
- 已配置就绪的 [SA Todo 后端服务](../sa_todo_backend/)（如果只需要使用纯本地模式测试界面，则后端为可选项）

### 1. **安装依赖**

将项目克隆到本地后，在根目录下终端执行：

```bash
flutter pub get
```

### 2. 执行代码生成

本项目深度依赖 `build_runner` 动态生成依赖注入文件 (`.g.dart`) 和数据库抽象定义。如果你刚拉取代码，或者修改过 `drift` 表结构及 `riverpod` 代码，必须先运行以下指令：

```bash
# 生成本地数据库和状态相关代码文件
dart run build_runner build -d

# 或者当你在开发状态下，可以开启自动监听变化生成：
dart run build_runner watch -d
```

### 3. 本地调试与运行

你可以启动模拟器，或接入真机后执行下面的命令在调试模式下运行应用：

```bash
# 查看有哪些可用的设备
flutter devices

# 在默认设备上运行
flutter run

# 指定设备运行 (如 windows 或 iPhone)
flutter run -d <device_id>
```

### 4. 在 Web 浏览器中运行

Flutter 原生支持 Web 平台，无需额外配置即可在浏览器中运行应用。

#### 前置条件

确保已启用 Web 支持：

```bash
flutter config --enable-web
```

#### 启动开发服务器

```bash
# 列出可用设备（应能看到 Chrome 和 Web Server）
flutter devices

# 在 Chrome 中运行（推荐）
flutter run -d chrome

# 或者使用 Edge 浏览器
flutter run -d edge

# 指定端口运行
flutter run -d chrome --web-port=8080
```

#### 构建生产版本

```bash
# 构建 Web 生产版本（输出到 build/web 目录）
flutter build web --release
```

构建完成后，`build/web` 目录包含纯静态文件（HTML、CSS、JS），可部署到任意静态托管服务：

- **Nginx / Apache**：将 `build/web` 内容复制到服务器根目录
- **Vercel / Netlify**：直接关联 Git 仓库，构建命令设为 `flutter build web`，输出目录设为 `build/web`
- **GitHub Pages**：将 `build/web` 内容推送到 `gh-pages` 分支
- **本地预览**：使用 `dhttpd` 包快速预览

```bash
# 使用 dhttpd 在本地预览生产版本
dart pub global activate dhttpd
dhttpd --path build/web
```

---

## 📦 打包与发布部署 (Release)

发布到正式环境前，需要构建对应平台的 Release 安装包，以达到最优响应速度与性能：

### Android 打包

构建适用于 Android 的安装包（默认生成位置：`build/app/outputs/flutter-apk/app-release.apk`）

```bash
# 普通 Apk 包构建
flutter build apk --release

# 面向 Google Play 商店的 AAB 格式
flutter build appbundle --release
```

### iOS 打包

确保系统为 MacOS 并且已安装并配置好 Xcode 签名。

```bash
# 这一步将会通过 Xcode 构建 iOS 的 Release App 包 (.app / .ipa)
flutter build ios --release
```

> **注意**：如果是在真机测试或者发布，请打开 `ios/Runner.xcworkspace` 在 Xcode 内登录您的 Apple Id 配置对应的开发证书 Signing & Capabilities。

### Web 及桌面端打包 (如需启用)

如果您的项目中开启了 Web 或 桌面端支持：

```bash
# Web 部署打包，静态资源会输出到 build/web 目录
flutter build web --release

# Windows 桌面版打包
flutter build windows --release

# MacOS 桌面版打包
flutter build macos --release
```

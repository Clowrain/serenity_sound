<p align="center">
  <h1 align="center">🌙 Serenity Sound</h1>
  <p align="center">极简主义白噪音应用 · 专为放松、冥想与专注而设计</p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.32-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/iOS%20|%20Android%20|%20macOS-lightgrey" alt="Platform">
</p>

---

## 📸 应用截图

<p align="center">
  <!-- 首页截图 -->
  <img src="screenshots/home.png" width="280" alt="首页">
  <img src="screenshots/mixer.png" width="280" alt="混音器">
  <img src="screenshots/settings.png" width="280" alt="设置">
</p>

---

## 🎯 项目简介

Serenity Sound 是一款跨平台白噪音混音应用，采用 iOS 原生设计语言（Cupertino），提供沉浸式的环境音效体验。支持多音效同时播放、场景保存与恢复、睡眠定时器等功能。

---

## ✨ 功能详解

### 🎵 音效系统

**内置音效库**
- 12 个本地高品质音效，涵盖自然、雨声、动物、场所、器物等分类
- 每个音效配有精心设计的 SVG 矢量图标和专属主题色
- 支持无限混音：同时播放任意数量的音效

**远程音效扩展**
- 通过 URL 添加远程音效包（JSON 配置 + MP3/SVG 资源）
- 自动下载并缓存到本地，离线可用
- 支持单独删除或批量清空远程音效
- 下载进度实时显示，失败时提供友好错误提示

---

### 🎚️ 混音器

- **音量独立控制**: 每个音效单独调节音量 (0-100%)
- **拖拽排序**: 长按拖拽手柄重新排列音效顺序，带触感反馈
- **播放状态**: 点击播放/暂停单个音效
- **视觉反馈**: 激活的音效高亮显示主题色

---

### 💾 场景系统

**场景保存**
- 保存当前所有激活的音效及其音量配置
- 保存音效的排列顺序
- 支持 8 种预设颜色标识

**场景管理**
- 点击场景：立即恢复完整配置（音效 + 音量 + 顺序）
- 重命名/删除：通过操作菜单管理
- 修改检测：场景变化时显示「保存」按钮

---

### ⏰ 睡眠定时器

- **触发方式**: 点击主页时钟区域
- **时间选择**: iOS 原生滚轮选择器，支持小时/分钟设置
- **倒计时显示**: 主页时钟自动切换为剩余时间
- **结束动画**: 定时结束时时钟闪烁提示
- **一键取消**: 取消后自动关闭面板

---

### 🎨 界面设计

**Cupertino 设计语言**
- 采用 CupertinoApp 作为应用根组件
- 所有对话框使用 CupertinoAlertDialog
- 导航使用 CupertinoPageRoute 转场动画
- 滑块、按钮、卡片均为 iOS 风格

**视觉效果**
- 时钟冒号渐隐渐显动画 (500ms easeInOut)
- 音效图标呼吸光效
- 深色主题，护眼舒适

---

### 🔄 后台播放

- 锁屏状态持续播放
- 系统通知栏控制（Android）
- 控制中心集成（iOS）
- 双击时钟区域快速暂停/播放

---

## 📂 项目结构

```
lib/
├── main.dart                      # 应用入口，初始化服务
├── models/
│   └── sound_effect.dart          # SoundEffect / SoundScene 数据模型
├── providers/
│   └── sound_provider.dart        # Riverpod 状态管理（12+ providers）
├── screens/
│   ├── home_screen.dart           # 主页（时钟、音效网格、场景栏）
│   ├── mixer_panel.dart           # 混音面板（可拖拽排序）
│   ├── timer_panel.dart           # 定时器设置
│   ├── settings_page.dart         # 设置主页
│   ├── scene_management_page.dart # 场景管理
│   └── sound_management_page.dart # 音效管理
├── services/
│   ├── audio_handler.dart         # 后台音频服务 (audio_service)
│   ├── storage_service.dart       # Hive 持久化存储
│   ├── asset_cache_service.dart   # 远程资源缓存管理
│   └── remote_source_service.dart # 远程音效包加载
├── theme/
│   └── serenity_theme.dart        # 统一颜色/字体/圆角配置
└── widgets/
    ├── breathing_logo.dart        # 呼吸动画图标
    ├── control_buttons.dart       # ControlKnob / MasterButton
    ├── cupertino_card.dart        # iOS 风格卡片
    ├── cupertino_slider.dart      # iOS 风格音量滑块
    ├── scene_widgets.dart         # AddSceneButton / SceneChip
    ├── svg_icon.dart              # SVG 图标加载器
    └── toast.dart                 # 消息提示组件
```

---

## 🛠️ 技术栈

| 类别 | 技术 | 用途 |
|------|------|------|
| UI 框架 | Flutter 3.32 | 跨平台界面 |
| 设计语言 | Cupertino | iOS 原生风格 |
| 状态管理 | Riverpod | 响应式状态 |
| 音频播放 | just_audio | 高品质音频 |
| 后台服务 | audio_service | 锁屏播放/通知栏 |
| 持久化 | Hive | 本地数据存储 |
| 网络请求 | Dio | 远程资源下载 |
| 矢量图标 | flutter_svg | SVG 渲染 |

---

## 🚀 快速开始

```bash
# 克隆仓库
git clone https://github.com/Clowrain/serenity_sound.git
cd serenity_sound

# 安装依赖
flutter pub get

# 运行（选择平台）
flutter run -d macos
flutter run -d ios
flutter run -d android
```

---

## 📦 添加远程音效包

1. 准备 JSON 配置文件（音效数组格式）：

```json
[
  {
    "id": "my_rain",
    "name": "我的雨声",
    "svgPath": "https://example.com/sounds/rain.svg",
    "audioPath": "https://example.com/sounds/rain.mp3",
    "themeColor": "#4FC3F7"
  },
  {
    "id": "my_thunder",
    "name": "雷声",
    "svgPath": "https://example.com/sounds/thunder.svg",
    "audioPath": "https://example.com/sounds/thunder.mp3",
    "themeColor": "#4FC3F7"
  }
]
```

2. 设置 → 音效管理 → 点击右上角 "+" → 输入 JSON 文件 URL
3. 等待下载完成，新音效自动出现在列表

> **注意**: `svgPath` 和 `audioPath` 必须是完整的 URL 地址

---

## 📱 平台支持

| 平台 | 状态 | 后台播放 |
|------|------|----------|
| Android | ✅ | 通知栏控制 |
| iOS | ✅ | 控制中心 |
| macOS | ✅ | 菜单栏 |

---

## 🙏 鸣谢

- **音效资源**: 本项目的音效文件来源于 [Moodist](https://github.com/remvze/moodist)，一个优秀的开源白噪音应用。

---

## 📄 开源协议

[MIT License](LICENSE) © 2024 Serenity Sound
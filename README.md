# Serenity Sound (宁静之声)

Serenity Sound 是一款专为放松、冥想、睡眠和提高专注度设计的极简主义环境音效混音应用。它通过高品质的自然与生活音效，结合复古的视觉设计，为用户营造沉浸式的听觉环境。

## ✨ 项目核心特性

- **庞大的音效库**：内置 80+ 种精选音效，涵盖：
  - **自然 (Nature)**：篝火、溪流、海浪、森林风声等。
  - **雨声 (Rain)**：暴雨、小雨、窗边雨、车顶雨、惊雷等。
  - **动物 (Animals)**：鸟鸣、猫咪呼噜、鲸语、虫鸣等。
  - **场所 (Places)**：咖啡厅、图书馆、夜间村庄、水下世界等。
  - **交通 (Transport)**：列车车厢、潜艇、划船、飞机等。
  - **器物 (Things)**：机械键盘、老式挂钟、风铃、颂钵等。
  - **城市 (Urban)**：繁华街道、交通流、烟花、人群等。
- **独特的展示逻辑 (Top-12 Logic)**：
  - **首页精选**：首页仅展示排名前 12 位的音效，确保界面简洁且易于快速开启。
  - **混音预览模式**：在混音面板中，用户可以预览播放库中所有的 80+ 种音效。
  - **动态裁剪**：关闭混音面板时，非前 12 名的预览音效会自动停止，节省系统资源并维持首页的一致性。
  - **自定义排序**：支持通过拖拽手柄重新排列音效顺序，从而自定义首页展示的 12 个音效。
- **自定义场景 (Scenes)**：允许用户将当前的混音配置（包含哪些声音及各自的音量）保存为“场景”，以便一键切换。
- **复古数字视觉**：
  - 复古 VFD 风格的数字时钟与定时器显示。
  - 动态“呼吸灯”音效图标，实时反馈播放状态与音效主题色。
  - 沉浸式暗黑渐变背景。
- **全方位功能支持**：
  - **睡眠定时器**：设置倒计时自动停止播放。
  - **后台播放**：支持系统级后台音频服务，锁屏或切换应用时持续播放，并可通过通知栏控制。
  - **多语种支持**：界面及 80+ 种音效名称已完全汉化。

## 🛠️ 技术架构

- **UI 框架**: Flutter (支持 Material 3 设计规范)
- **状态管理**: [Riverpod](https://riverpod.dev/) (用于复杂的混音状态管理与逻辑解耦)
- **音频引擎**: 
  - [just_audio](https://pub.dev/packages/just_audio): 负责多音轨并发播放、音量平滑调节。
  - [audio_service](https://pub.dev/packages/audio_service): 负责 iOS/Android 系统的后台播放与媒体控制集成。
- **数据持久化**: [Hive](https://pub.dev/packages/hive) (高性能键值对数据库，用于存储用户排序、场景及音量设置)
- **图形与资源**:
  - [flutter_svg](https://pub.dev/packages/flutter_svg): 渲染来自 Iconify 的 MDI 与 Phosphor 矢量图标。
  - 自动同步逻辑：启动时自动比对 `sounds.json` 配置与本地数据库，确保资源动态更新。

## 📂 项目结构

```text
lib/
├── main.dart             # 应用入口、首页 UI 及混音面板/定时器弹窗
├── models/
│   └── sound_effect.dart # 数据模型 (SoundEffect, SoundScene)
├── providers/
│   └── sound_provider.dart # 核心逻辑：混音状态、前12名过滤、定时器
├── services/
│   ├── audio_handler.dart  # 系统音频服务封装 (后台控制)
│   └── storage_service.dart # 数据同步与 Hive 持久化逻辑
├── widgets/
│   └── breathing_logo.dart # 动画组件：支持呼吸效果的 SVG 图标
assets/
├── audio/                # 80+ 个分类存放的 mp3 音频文件
├── svg/                  # 统一样式的 Iconify 矢量图标资源
└── config/
    └── sounds.json       # 核心配置文件：定义 ID、中文名、图标路径与主题色
```

## 🚀 快速开始

1. **安装依赖**
   ```bash
   flutter pub get
   ```

2. **生成持久化代码**
   ```bash
   flutter pub run build_runner build
   ```

3. **运行**
   ```bash
   flutter run
   ```

## 📝 配置指南

如需添加新音效：
1. 将 `.mp3` 文件放入 `assets/audio/` 对应分类。
2. 在 `assets/config/sounds.json` 中添加相应条目。
3. 应用启动时会自动扫描并合并新资源，同时保留用户已有的音量和场景设置。

## 📄 开源协议

本项目采用 MIT 协议。
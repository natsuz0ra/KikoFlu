# KikoFlu

[English](README_EN.md)

本仓库 fork 自 [pa-jesusf/KikoFlu](https://github.com/pa-jesusf/KikoFlu)，使用
[CPF-Flutter/flutter_flutter](https://gitcode.com/CPF-Flutter/flutter_flutter)
为 KikoFlu 增加 HarmonyOS NEXT 原生 HAP 支持，并持续同步上游功能。

> [!IMPORTANT]
>
> 本仓库主要维护 HarmonyOS NEXT 移植与发布。其他平台请优先使用
> [上游仓库](https://github.com/pa-jesusf/KikoFlu)提供的版本。

## 支持情况

- 目标 API 版本：26.0.0
- 最低兼容版本：HarmonyOS 6.0.2（API 22）
- Flutter 版本：ohos-3.41.9-dev（revision `c83ab0015f`）

## 功能适配情况

**鸿蒙端主要功能已与上游同步。**

- [x] 作品浏览、搜索、筛选与详情
- [x] 音频播放、后台播放与系统媒体控制
- [x] 音频缓存、下载与离线浏览
- [x] 字幕加载、编辑、翻译与字幕库
- [x] 图片、文本与 PDF 浏览
- [x] 主题、多语言与隐私模式

## 下载与安装

前往 [Releases](https://github.com/natsuz0ra/KikoFlu/releases) 下载 HarmonyOS
NEXT HAP。

### 🔍 搜索
- 高级搜索，支持多标签 / 排除标签
- 多维度筛选（标签、评分、发售日期等）
- 完整作品信息展示

### 🌐 国际化
- 简体中文 / 繁體中文 / English / 日本語 / Русский
- 多形式、多语言翻译支持

### ⚙️ 设置
- 多账户支持
- 自定义服务器地址（[使用指南](https://github.com/pa-jesusf/KikoFlu/wiki/%E4%BD%BF%E7%94%A8%E8%87%AA%E5%BB%BA%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1%E5%99%A8)），可测试连接延迟
- 自定义缓存大小限制与清理策略
- 主题模式、配色方案自由选择
- 翻译目标语言可单独设置，LLM 模式支持自定义目标语言
- 丰富的界面自定义选项
- 应用内日志系统（支持导出）
- 更新检查

### 📱 Android 特性
- 悬浮歌词（锁定 / 解锁 / 触控穿透）

---

## 下载

前往 [Releases](https://github.com/pa-jesusf/KikoFlu/releases/latest) 下载最新版本。

支持平台：Android（universal / arm64 / armeabi-v7a / x86_64）、iOS（未签名 IPA）、Windows（安装包 / 便携版）、macOS（DMG）、Linux（x64 / arm64）

### AltStore / SideStore

iOS 用户可通过 AltStore 或 SideStore 添加软件源来安装和更新 KikoFlu：

**源地址：** `https://raw.githubusercontent.com/pa-jesusf/KikoFlu/main/altstore-source.json`

---

## 源码构建

### 环境要求
- Flutter SDK 3.44.1+
- Dart SDK 3.12.1+

```bash
git clone https://github.com/pa-jesusf/KikoFlu.git
cd KikoFlu
flutter pub get
```

### 构建命令

| 平台 | 命令 |
|------|------|
| Android | `flutter build apk --release --split-per-abi` |
| Windows | `flutter build windows --release` |
| macOS | `flutter build macos --release` |
| Linux | `flutter build linux --release` |
| iOS | `./build_ios_xcode.sh` |

---

## 相关项目

- [Kikoeru](https://github.com/Number178/kikoeru-express) — 自建后端服务器
- [asmr.one](https://www.asmr.one) — 在线服务
可以使用[小白调试助手](https://github.com/likuai2010/auto-installer)等工具进行安装

## 开源协议

GNU 通用公共许可证第 3 版（[GPL-3.0](LICENSE)）

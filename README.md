# 手持弹幕播报器 (HandheldBarrage)

> 一款专为 HarmonyOS NEXT 设计的全功能手持弹幕展示应用，支持渐变文字、粒子特效、LED 点阵、多行模式等丰富的视觉效果。

---

## 📱 项目简介

**手持弹幕播报器**是一款让手机屏幕变身为个性化弹幕展示板的 HarmonyOS 应用。  
无论是演唱会应援、体育赛场加油、生日派对、婚礼现场，还是网红直播道具，都能通过这款 APP 在人群中脱颖而出。

---

## ✨ 核心功能

### 文字显示
| 功能 | 描述 |
|------|------|
| 单行 / 多行模式 | 支持 1-5 行弹幕同时滚动 |
| 横向 / 竖向滚动 | 自由切换滚动方向，适配不同场景 |
| 反向滚动 | 反转滚动方向，左→右或下→上 |
| 镜像模式 | 水平翻转文字，方便隔玻璃展示 |
| 富文本高级模式 | 每个文字片段可独立设置字体、颜色、大小 |

### 字体与排版
| 功能 | 描述 |
|------|------|
| 字体大小 | 任意调节，从小字幕到超大横幅 |
| 字体粗细 | Lighter / Normal / Medium / Bold / Bolder |
| 字体斜体 | 普通 / 斜体 |
| 字体族 | 内置 HarmonyOS Sans、serif、monospace + 自定义字体加载 |
| 字间距 | 0-50px 精细调节 |
| 行间距 | 多行模式下行间距调节 |
| 文字装饰 | 下划线 / 删除线 |
| 文字描边 | 启用描边轮廓，颜色与粗细可调 |

### 颜色与渐变
| 功能 | 描述 |
|------|------|
| 单色文字 | HSV 色轮精准取色 |
| 线性渐变 | 多色停止点、渐变角度全自定义 |
| 渐变方向 | 0-360° 任意角度 |

### 动态效果
| 效果 | 描述 |
|------|------|
| 缩放动画 | 文字呼吸式放大缩小 |
| 旋转动画 | 文字持续旋转 |
| 跳跃动画 | 文字上下弹跳 |
| 抖动动画 | 文字左右震动（适合加油场景） |
| 波浪动画 | 文字左右波浪起伏 |
| 闪烁效果 | 文字定期闪烁，速度可调 |

### 特效与覆盖层
| 特效 | 描述 |
|------|------|
| LED 点阵 | 模拟电子屏像素风格，支持圆点/方块/网格 |
| 粒子特效 | 五种粒子：闪光✨、泡泡🫧、火焰🔥、雪晶❄️、星星⭐ |

### 背景
| 功能 | 描述 |
|------|------|
| 纯色背景 | 自定义背景颜色 |
| 图片背景 | 从相册选择背景图，透明度可调 |
| 视频背景 | 播放本地视频作为动态背景 |
| 背景模糊 | 毛玻璃效果 |

### 多行弹幕特殊显示
| 模式 | 描述 |
|------|------|
| 中间行放大 | 突出中心行，视觉层次更丰富 |
| 首行高亮色 | 第一行使用强调色 |
| 渐进式大小 | 行从小到大排列 |
| 交替颜色 | 奇偶行不同颜色 |
| 彩虹颜色 | 每行一种彩虹色 |

### 全屏模式
- 一键进入全屏播放，隐藏所有系统 UI
- 自动横竖屏锁定（根据滚动方向自动适配）
- 全屏亮度控制（10%-100%）
- 屏幕常亮，演出全程不熄屏
- 双击返回编辑页面

### 模板系统
- 自定义模板保存 / 加载 / 删除
- 8 种内置场景预设快速套用：
  - 🎤 演唱会（Concert）
  - 💪 体育赛事（Sports）
  - 🎂 生日快乐（Birthday）
  - ⚡ 霓虹风格（Neon）
  - 🎄 圣诞快乐（Christmas）
  - 🎃 万圣节（Halloween）
  - ❤️ 浪漫告白（Romantic）
  - 🎮 游戏竞技（Gaming）

---

## 🛠 技术栈

| 技术 | 说明 |
|------|------|
| **ArkTS** | 华为 HarmonyOS NEXT 原生开发语言 |
| **ArkUI** | 声明式 UI 框架，组件化开发 |
| **Canvas 2D API** | 渐变文字、LED 点阵、粒子系统的底层绘制 |
| **@ohos.window** | 全屏控制、屏幕方向、亮度、常亮 |
| **@ohos.router** | 页面间导航（Index ↔ PlayPage） |
| **@ohos.data.preferences** | 轻量键值对存储，用于模板持久化 |
| **@ohos.file.fs / picker** | 本地字体文件加载、图片/视频选取 |
| **@ohos.font** | 动态注册自定义字体 |

---

## 📁 项目结构

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets          # 主页（预览区 + 设置区）
│   └── PlayPage.ets       # 全屏播放页
├── components/
│   ├── BarragePreview.ets # 核心渲染组件（GradientText / NormalText / LED / Particle）
│   ├── SettingsPanel.ets  # 完整设置面板
│   ├── ColorPicker.ets    # HSV 色盘颜色选择器
│   └── GradientTextCanvas.ets  # 独立渐变文字组件（备用实现）
├── model/
│   ├── BarrageConfig.ets  # 核心数据模型（@Observed，含预设，序列化）
│   └── ColorUtils.ets     # HSV ↔ RGB 颜色转换工具
└── utils/
    └── TemplateManager.ets # 模板持久化（@ohos.data.preferences）
```

---

## 🚀 构建与运行

### 环境要求
- DevEco Studio 5.0+
- HarmonyOS SDK API 12+
- 真机或 HarmonyOS 5.0+ 模拟器

### 构建步骤

```bash
# 1. 克隆项目
git clone <项目地址>

# 2. 用 DevEco Studio 打开项目根目录

# 3. 等待依赖下载完成（oh_modules）

# 4. 连接 HarmonyOS 真机或启动模拟器

# 5. 点击 Run 或使用 hvigor 命令构建
```

### 使用 hvigor 命令行构建

```bash
# 构建 Debug HAP
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# 构建 Release HAP（需配置签名）
hvigorw assembleHap --mode module -p product=default -p buildMode=release
```

---

## 📖 使用指南

### 基本使用

1. **输入文字**：在设置面板顶部文本框输入想要展示的内容（支持 emoji）
2. **调整样式**：设置字体大小、颜色、渐变、动画等
3. **选择预设**：快速套用内置场景模板
4. **全屏播放**：点击右下角「全屏播放」按钮进入播放模式
5. **退出播放**：双击屏幕任意位置退出全屏

### 镜像模式使用场景
> 开启「镜像」开关后，文字会水平翻转  
> 适用于：将手机贴近透明玻璃/亚克力板，从另一侧看到正常文字（如演唱会现场应援队）

### 自定义字体
> 将 `.ttf` 或 `.otf` 字体文件放入 `entry/src/main/resources/rawfile/fonts/` 目录  
> 应用启动时会自动扫描并注册，在设置面板的字体选择器中选用

---

## ⚙️ 配置项参考

`BarrageConfig` 是应用的核心数据模型，包含以下主要配置组：

| 配置组 | 主要属性 |
|--------|----------|
| 内容 | `text`, `useAdvancedMode`, `segments` |
| 字体 | `fontSize`, `fontColor`, `fontWeight`, `fontStyle`, `fontFamily`, `letterSpacing`, `lineSpacing` |
| 渐变 | `gradientEnabled`, `gradientColors`, `gradientDirection` |
| 背景 | `backgroundType`, `backgroundColor`, `backgroundOpacity`, `backgroundBlur` |
| 滚动 | `direction`, `scrollSpeed`, `scrollReverse` |
| 动画 | `animationType`, `isBlinking`, `blinkSpeed` |
| LED | `ledEnabled`, `ledDensity`, `ledShape`, `ledSpacing` |
| 粒子 | `particleEnabled`, `particleType` |
| 多行 | `multiLineEnabled`, `lineCount`, `sameContent`, `specialLineType` |
| 描边 | `strokeEnabled`, `strokeColor`, `strokeWidth` |
| 特殊 | `mirrorMode`, `scrollReverse`, `brightness`, `keepScreenOn` |

---

## 📄 License

MIT License

---

*使用 ArkTS + ArkUI 构建，专为 HarmonyOS NEXT 优化*

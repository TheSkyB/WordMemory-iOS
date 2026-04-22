# WordMemory iOS

基于 `english__app`（不爱背单词）Android 应用的原生 SwiftUI 重写版本。

## 功能特性

### 第一阶段 ✅
- SM2 调度算法（V3/V4 双版本切换）
- 认词模式（卡片翻转 + 手势滑动）
- 词库导入（JSON 格式）
- 学习进度跟踪
- 艾宾浩斯遗忘曲线

### 第二阶段 ✅
- **拼写模式** - 看释义拼写，编辑距离判定
- **生词本** - 右滑加入，搜索，详情查看
- **数据统计** - 今日/周图表/掌握进度/连续打卡
- **SQLite 持久化** - 进度、记录、统计本地存储

### 第三阶段 ✅
- **AI 助手** - 例句生成、助记技巧、词源分析（DeepSeek API）
- **发音功能** - 系统语音 / Free Dictionary / 有道
- **复习压力分散** - 每日上限，超出顺延
- **打卡系统** - 连续打卡统计

## 项目结构

```
WordMemory/
├── WordMemoryApp.swift              # App 入口 + Tab 导航
├── Core/
│   ├── SM2/
│   │   └── SM2Scheduler.swift       # SM2 算法核心
│   ├── AI/
│   │   └── AIService.swift          # DeepSeek AI 服务
│   ├── SpellingEvaluator.swift      # 拼写评估
│   └── ReviewPressureManager.swift  # 复习压力分散
├── Data/
│   ├── Model/
│   │   ├── Word.swift               # 数据模型
│   │   └── Progress.swift           # 进度模型
│   ├── Repository/
│   │   ├── WordbookLoader.swift     # 词库加载器
│   │   └── NotebookManager.swift    # 生词本管理
│   ├── SQLiteManager.swift          # SQLite 持久化
│   └── DatabaseManager.swift        # 旧 UserDefaults 占位
└── UI/
    ├── Screens/
    │   ├── LearningScreen.swift     # 学习页面
    │   ├── SpellingView.swift       # 拼写模式
    │   ├── NotebookScreen.swift     # 生词本
    │   └── StatsScreen.swift        # 统计页面
    ├── Components/
    │   └── AIAssistantPanel.swift   # AI 助手面板
    └── ViewModels/
        └── LearningViewModel.swift
```

## 构建步骤

### 1. 准备环境
- macOS + Xcode 15+
- 或 GitHub Actions 云端构建

### 2. 生成 Xcode 项目
```bash
cd WordMemory-iOS
xcodegen generate
```

### 3. 配置签名
- 打开 `WordMemory.xcodeproj`
- 选择 Target → Signing & Capabilities
- 选择你的 Apple ID Team

### 4. 构建 IPA
```bash
xcodebuild -project WordMemory.xcodeproj \
  -scheme WordMemory \
  -configuration Release \
  -sdk iphoneos \
  -archivePath build/WordMemory.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath build/WordMemory.xcarchive \
  -exportPath build/WordMemory.ipa \
  -exportOptionsPlist exportOptions.plist
```

### 5. 安装到 iPhone
使用 AltStore、Sideloadly 或 TrollStore 安装 IPA。

## 词库导入

将 `wordbook_full.json` 放入项目 `Resources` 目录，或放入 App Documents 目录。

JSON 格式：
```json
[
  {
    "word": "abandon",
    "phonetic": "/əˈbændən/",
    "meaning": "v. 放弃，遗弃",
    "example": "He abandoned his car.",
    "phrases": "abandon oneself to 沉溺于",
    "synonyms": "desert, forsake",
    "rel_words": "abandoned adj. 被遗弃的"
  }
]
```

## 手势操作

| 手势 | 动作 |
|------|------|
| 轻触卡片 | 翻转查看释义 |
| 左滑 | 太简单（30天后复习）|
| 右滑 | 加入生词本 |

## 学习模式

| 模式 | 说明 |
|------|------|
| 认词模式 | 看单词选认识/模糊/不认识 |
| 拼写模式 | 看释义拼写，支持字母提示 |

## 拼写评分

| 结果 | 条件 | 间隔调整 |
|------|------|----------|
| 🟢 完美 | 完全正确 | 标准间隔 × 1.1 |
| 🔵 接近正确 | 1-2字符差，>80%相似 | 保守间隔 |
| 🟡 需要练习 | 3-4字符差，>60%相似 | 标准间隔 |
| 🔴 再试一次 | 差距大 | 重置为1天 |

## AI 助手

支持三种 AI 功能：
- **例句生成** - 为单词生成地道例句
- **助记技巧** - 谐音联想、词根拆解
- **词源分析** - 词源、搭配、真题频率

在设置中配置 DeepSeek API Key 即可使用。

## 发音来源

| 来源 | 说明 |
|------|------|
| 系统语音 | iOS 自带 TTS，无需网络 |
| Free Dictionary | 真人发音，需网络 |
| 有道 | 真人发音，需网络 |

## 复习压力分散

当待复习单词超过每日上限（默认50个）时：
- 优先复习最早到期的单词
- 剩余单词自动顺延至明天
- 避免一天内复习量过大

## 后续优化

- [ ] 数据备份/恢复
- [ ] iCloud 同步
- [ ] 深色模式优化
- [ ] 学习提醒通知
- [ ] App Store 上架

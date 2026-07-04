# Story DSL

## 概述

Story DSL 是 ChatMemoir 的叙事层。它不依赖 AI，而是通过模板将 Timeline 事件编织成有结构的故事。

**核心哲学**：不讲统计，讲故事。

```
Timeline    →  StoryEngine  →  Story DSL  →  JSON / UI / AI
("发生了什么")  ("怎么讲这个故事")  (故事结构)   (消费端)
```

## 数据结构

### Story

顶层容器。

```swift
struct Story {
    let title: String           // 自动生成，如"《Alice与我：3年聊天回忆录》"
    let subtitle: String         // 一行副标题
    let chapters: [Chapter]      // 按重要性排序的章节
    let metadata: StoryMetadata  // 元信息
}
```

### Chapter

故事的一个章节。

```swift
struct Chapter {
    let title: String            // "初识"、"热络"、"沉默"、"一周年"
    let summary: String          // 一句话摘要
    let emotion: ChapterEmotion  // 情绪基调
    let importance: Int          // 重要性 1-10
    let chapterType: ChapterType // 章节类型
    let eventIDs: [String]       // 关联的 TimelineEvent
    let narrative: NarrativeTemplate? // 叙事模板
}
```

### ChapterType

| 类型 | 说明 | 示例标题 |
|------|------|---------|
| `opening` | 故事开篇 | "初识" |
| `growth` | 关系升温 | "升温" |
| `peak` | 最热络的时期 | "热络" |
| `silence` | 沉默期 | "沉默" |
| `milestone` | 里程碑 | — |
| `anniversary` | 周年 | "一周年" |
| `closing` | 收尾 | "未完待续" |
| `turningPoint` | 转折 | — |

### ChapterEmotion

| 情绪 | 触发条件 |
|------|---------|
| `.nostalgic` | opening（回忆起点） |
| `.warm` | growth、streak（日常陪伴） |
| `.excited` | peak（高峰） |
| `.bittersweet` | silence（沉默） |
| `.joyful` | anniversary（周年） |
| `.reflective` | closing（总结） |
| `.proud` | milestone（成就） |

## NarrativeTemplate

每个 Chapter 包含一个 `NarrativeTemplate`，它定义了故事文本的结构。

```swift
struct NarrativeTemplate {
    let template: String          // "从{date}开始，{owner}和{contact}..."
    let variables: [String: String] // {"date": "2023年1月15日", ...}
    
    func fill() -> String         // 填充变量后的文本
}
```

### 设计理念

- **当前**：`fill()` 用变量替换产生可读文本
- **未来**：AI 读取 `template` + `variables`，用自然语言重写
- **结构不变**：无论文本怎么写，Chapter 的结构（类型、情绪、重要性）不变

## StoryEngine 算法

### 输入

一个 Timeline（来自 TimelineEngine）。

### 流程

```
Timeline.events
    ↓
按 event.kind 分组
    ↓
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Opening  │ │ Growth   │ │ Peak     │ │ Silence  │
│ 第一条消息│ │ 里程碑   │ │ 最忙一天 │ │ 最长沉默 │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Streak   │ │ Anniv.   │ │ Closing  │
│ 连续聊天 │ │ 周年     │ │ 总结     │
└──────────┘ └──────────┘ └──────────┘
    ↓
按重要性排序 (importance desc, then type order)
    ↓
生成 title + subtitle
    ↓
Story
```

### 重要性规则

| Chapter | Importance |
|---------|-----------|
| opening | 10 |
| closing | 10 |
| anniversary | 9 |
| growth | 8 |
| peak | 7 |
| streak | 7 |
| silence | 6 |
| contact | 5 |

### 标题生成

```
if 有最高频联系人 && > 365天:
    → "《Alice与我：3年聊天回忆录》"
else if 有最高频联系人:
    → "《Alice与我：500天的对话》"
else:
    → "《8423条消息的故事》"
```

## 与 AI 的关系

Story DSL **不依赖 AI**，但它**为 AI 而生**。

```
现在（v0.1）:
  NarrativeTemplate.fill() → 模板文本

未来:
  AI 接收:
    {
      "chapterType": "opening",
      "emotion": "nostalgic",
      "events": [...],
      "narrativeTemplate": {...}
    }
  → 生成自然语言 →
    "2023年1月15日，第一条'你好'出现在屏幕上。
     那时候谁也不知道，这两个字会开启一段500天的旅程。"
```

**关键**：AI 改变的是叙事风格，不改变叙事结构。

## 示例输出

```json
{
  "title": "《Alice与我：2年聊天回忆录》",
  "subtitle": "2年，8423条消息，一个关于陪伴的故事。",
  "chapters": [
    {
      "id": "opening",
      "title": "初识",
      "summary": "一切开始的地方。",
      "emotion": "nostalgic",
      "importance": 10,
      "chapterType": "opening",
      "narrative": {
        "template": "从{date}的第一条消息开始...",
        "variables": {"date": "2023年1月15日"}
      }
    },
    {
      "id": "closing",
      "title": "未完待续",
      "summary": "2年，8423条消息。这就是你们的聊天回忆录。",
      "emotion": "reflective",
      "importance": 10,
      "chapterType": "closing"
    }
  ]
}
```

## 扩展方式

### 添加新的章节类型

1. 在 `ChapterType` 枚举中添加新 case
2. 在 `StoryEngine.generate()` 中添加匹配和构造逻辑
3. 在 `chapterTypeOrder()` 中添加排序权重

### 添加新的情绪

1. 在 `ChapterEmotion` 枚举中添加新 case
2. 在对应的 Chapter Builder 中设置

## 与 Timeline Engine 的分工

| Layer | 问题 | 输出 |
|-------|------|------|
| ChatImportKit | 发生了什么？ | ChatDatabase |
| TimelineEngine | 哪些事值得记住？ | Timeline + Events |
| StoryEngine | 怎么讲故事？ | Story + Chapters |
| AI Adapter（未来） | 怎么讲得更动人？ | Natural language text |
| SwiftUI（未来） | 怎么展示？ | UI |

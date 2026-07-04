# Presentation Engine

## 概述

Presentation Engine 是 ChatMemoir 的渲染层。它将 Story DSL 转换为可以展示、导出、分享的 RenderDocument。

**不分析数据，不生成故事，只管怎么讲。**

```
Story → PresentationEngine → RenderDocument → 
                                    ├── Markdown
                                    ├── HTML
                                    ├── JSON
                                    └── (未来) SwiftUI / PDF / Video
```

## 架构

### 数据流

```
Story.chapters
    ↓
┌────────────────────┐
│  PresentationEngine │
│  ├── Cover Page     │  ← 自动生成封面
│  ├── Chapter Pages  │  ← 按内容智能分页
│  ├── StoryCards     │  ← 提取分享卡片
│  └── Closing Page   │  ← 自动生成结尾
└────────────────────┘
    ↓
RenderDocument
    ↓
ExportEngine → JSON / Markdown / HTML
```

### 分层职责

| 层 | 职责 | 不负责 |
|----|------|--------|
| Story DSL | 讲什么故事 | 怎么讲 |
| PresentationEngine | 怎么呈现 | 数据从哪来 |
| ExportEngine | 输出格式 | 视觉样式 |
| SwiftUI (未来) | 屏幕渲染 | 内容结构 |

## 智能分页

分页不是简单的 "一个 Chapter = 一页"。PresentationEngine 根据内容密度自动分页：

- `blocksPerPage`（默认 8）：每页最多容纳的 block 数
- Chapter 边界处理：Chapter Header 在新页开始
- 封面和结尾独立成页
- 装饰分割线独立成页

## Block 系统

所有内容都是 Block。这是 UI 和数据的统一接口：

| Block 类型 | 说明 | 示例 |
|-----------|------|------|
| `title` | 标题 (h1/h2) | "《Alice与我》" |
| `subtitle` | 副标题 | "2年，8423条消息" |
| `paragraph` | 正文段落 | "从第一句'你好'开始..." |
| `quote` | 引用 | "> 一切开始的地方" |
| `statistic` | 统计数据 | "**8423**条 — 总消息数" |
| `milestone` | 里程碑 | "🏆 第10000条消息" |
| `divider` | 分割线 | plain / decorated / chapter |
| `spacer` | 间距 | small / medium / large |
| `imagePlaceholder` | 图片占位 | AI 插图预留位置 |
| `storyCard` | 分享卡片 | 卡片嵌入 |
| `chapterHeader` | 章节标题 | "初识" + 情绪 emoji |
| `emotionTag` | 情绪标签 | `怀旧` |

### rawText vs rewrittenText

每个文本 Block 有两个字段：
- `rawText`：模板生成的文本（永远存在）
- `rewrittenText`：AI 改写后的文本（当前为 nil）

**现在**：UI 使用 `rawText`
**未来**：AI 填充 `rewrittenText`，UI 优先使用改写文本

## StoryCard 系统

StoryCard 是分享功能的基础。每个 Card 捕获一个值得分享的瞬间：

```json
{
  "title": "凌晨两点",
  "subtitle": "这是你们最常聊天的时候",
  "statisticValue": "342",
  "statisticLabel": "次深夜聊天",
  "emotion": "nostalgic",
  "theme": "warm"
}
```

Card 从 Chapter 中自动提取，按 ChapterType 匹配不同的模板。

## 主题系统

4 个预设主题，每个包含字体、间距、圆角、动画提示：

| Theme | 风格 | 字体 | 适用场景 |
|-------|------|------|---------|
| `memoir` | 经典回忆录 | Georgia | 沉浸式阅读 |
| `warm` | 温暖 | Avenir | 分享到朋友圈 |
| `minimal` | 极简 | Helvetica | 数据报告 |
| `midnight` | 深夜 | Menlo | 深夜回顾 |

## 封面和结尾

自动生成，模板化：

**封面示例**：
```
《Alice与我：2年聊天回忆录》
2年，8423条消息，一个关于陪伴的故事。

8423 条消息
500 天的对话

一本属于我们的聊天回忆录。
怀旧
```

**结尾示例**（>10000条消息）：
```
这不是终点。只是下一卷故事开始之前，短暂的停顿。
— ChatMemoir
```

## 导出

| 格式 | 方法 | 输出 |
|------|------|------|
| JSON | `ExportEngine.exportJSON()` | 完整 RenderDocument |
| Markdown | `ExportEngine.exportMarkdown()` | # 标题 + 引用 + 统计 |
| HTML | `ExportEngine.exportHTML()` | 自包含 HTML 页面 |

## 阅读模式（预留）

`RenderMetadata.readingMode` 支持：
- `memoir`：像一本书
- `wrapped`：年度总结
- `timeline`：时间轴
- `cards`：卡片流

当前实现 memoir 模式，其他模式预留接口。

## 使用示例

```swift
let story = StoryEngine.generate(from: timeline)
let doc = PresentationEngine.render(story: story, theme: .warm)

// Markdown
let md = ExportEngine.exportMarkdown(doc)

// HTML
let html = ExportEngine.exportHTML(doc)

// 分享卡片
for card in doc.cards {
    print("[\(card.emotion)] \(card.title): \(card.subtitle)")
}
```

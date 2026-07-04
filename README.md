# ChatMemoir — Core Pipeline

**ChatMemoir 的核心计算管线。**

不负责 UI。只负责：聊天数据 → 时间线 → 故事 → 可渲染文档。

---

## 架构

```
ChatImportKit
    ↓
ChatDatabase
    ↓
TimelineEngine    ← 从聊天数据提取统计、事件、趋势
    ↓
Timeline
    ↓
StoryEngine       ← 将事件编排为章节化故事
    ↓
Story
    ↓
PresentationEngine ← 渲染为可导出的文档
    ↓
RenderDocument
    ↓
（SwiftUI / HTML / PDF）
```

## 模块

| 模块 | 职责 | 输出 |
|------|------|------|
| **TimelineEngine** | "哪些事值得记住？" | Timeline（事件、统计、活跃热力图） |
| **StoryEngine** | "怎么讲故事？" | Story（章节、情绪、叙事模板） |
| **PresentationEngine** | "怎么呈现？" | RenderDocument（页面、Block、导出） |

## 测试

```bash
swift test  # 33 tests, all passing
```

## 依赖

- [ChatImportKit](https://github.com/Cjh-y/ChatImportKit) — 统一聊天数据模型

## 使用者

- [ChatMemoirApp](https://github.com/Cjh-y/ChatMemoirApp) — iOS 回忆录 App

## License

MIT

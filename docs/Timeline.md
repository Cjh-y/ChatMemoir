# Timeline Engine

## 概述

Timeline Engine 是 ChatMemoir 的核心计算引擎。它将统一的 `ChatDatabase` 转换为富含事件、统计和模式的 `Timeline` 数据结构。

**全部算法化，不依赖 AI。**

## 数据流

```
ChatDatabase → TimelineEngine.generate() → Timeline → JSON
     ↑                                              ↑
  ChatImportKit                              Story Engine (后续消费)
```

## 数据结构

### Timeline

顶层容器，包含所有计算产出。

| 字段 | 类型 | 说明 |
|------|------|------|
| `schemaVersion` | Int | JSON 兼容性版本号 |
| `platform` | ChatPlatform | 来源平台 |
| `statistics` | ChatStatistics | 总体统计 |
| `hourlyDistribution` | [HourBucket] | 24小时消息分布 |
| `weekdayDistribution` | [WeekdayBucket] | 星期分布 |
| `monthlyDistribution` | [MonthBucket] | 月度趋势 |
| `yearlyDistribution` | [YearBucket] | 年度趋势 |
| `messageTypeBreakdown` | MessageTypeBreakdown | 消息类型分布 |
| `streaks` | StreakInfo | 连续聊天与沉默期 |
| `responseTime` | ResponseTimeInfo | 回复速度分析 |
| `topContacts` | [ContactRank] | 高频联系人排行 |
| `groupStats` | GroupStats | 群聊统计 |
| `events` | [TimelineEvent] | 所有生成的事件 |
| `sections` | [TimelineSection] | 事件分组 |
| `activityHeatmap` | ActivityHeatmap | 7×24 活跃度矩阵 |

### TimelineEvent

算法自动生成的关键事件。每个事件包含：
- `kind`：事件类型（`.firstContact`、`.milestone`、`.anniversary` 等 13 种）
- `title`：人类可读的标题（"第10000条消息"）
- `date`：事件发生时间
- `description`：适合叙事生成的描述文本

事件类型：
| Kind | 触发条件 | 示例 |
|------|---------|------|
| `firstContact` | 第一条消息存在 | "一切开始的地方" |
| `lastContact` | 有最近消息 | "故事还在继续" |
| `milestone` | 达到消息数阈值 | "第10000条消息" |
| `busiestDay` | 单日消息最多 | "消息最多的一天" |
| `peakHour` | 某小时消息最多 | "最活跃的时段" |
| `chatStreak` | 连续聊天≥7天 | "最长连续聊天：120天" |
| `longestSilence` | 沉默≥30天 | "最长的沉默：60天" |
| `currentStreak` | 当前连续≥7天 | "连续聊天90天" |
| `anniversary` | 认识N周年 | "认识5周年" |
| `topContact` | 高频联系前5 | "#1 高频联系人：Alice" |

## 算法

### 统计计算
- 消息总数、文本/媒体分类
- 聊天天数 = 首尾消息日期差
- 人均消息数、活跃度

### 连续聊天（Streak）
- 按日聚合活跃日期
- 扫描间隔：gap=1天 = 连续，gap>1 = 沉默
- 最长连续 = max(连续区间长度)
- 当前连续 = 从今天往前推到第一个断点

### 里程碑检测
- 预设阈值：[1, 10, 50, 100, 500, 1000, 5000, 10000, 50000, 100000]
- 遍历消息序列，找到每个阈值被突破的精确时间点

### 周年检测
- 从首条消息日期计算经过的年数
- 为每个周年（1/2/3/5/10年）生成事件

## 扩展方式

### 添加新的事件类型
1. 在 `TimelineEvent.Kind` 枚举中添加新 case
2. 在 `generateEvents()` 中添加检测逻辑
3. 在 `buildSections()` 中添加分组规则

### 添加新的统计指标
1. 在 `ChatStatistics` 或相关结构体中添加字段
2. 在对应的 `compute*` 方法中计算
3. 更新 `Timeline` 初始化

## JSON 输出示例

```json
{
  "schemaVersion": 1,
  "platform": "wechat",
  "statistics": {
    "totalMessages": 8423,
    "totalChats": 3,
    "totalDays": 500,
    "averageMessagesPerDay": 16.8
  },
  "events": [
    {
      "kind": "firstContact",
      "title": "第一次聊天",
      "date": "2023-01-15T00:00:00Z",
      "description": "一切开始的地方。你们的第一条消息。"
    },
    {
      "kind": "milestone",
      "title": "第5000条消息",
      "date": "2024-03-10T14:23:00Z",
      "description": "这一天，你们的聊天正式突破了5000条。"
    }
  ]
}
```

## 与 Story Engine 的关系

Timeline Engine 只负责**提取**，Story Engine 负责**讲述**。

Timeline 中的每个事件都包含了叙事所需的所有素材：
- 发生了什么（type + title）
- 什么时候（date）
- 为什么重要（description）
- 量化数据（value）

Story Engine 不需要重新分析原始聊天记录，只需要把这些事件串联成故事。

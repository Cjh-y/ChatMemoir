import Foundation
import TimelineEngine

/// The Story Engine: converts a Timeline into a Story.
///
/// All logic is template-driven — no AI dependencies.
/// The engine:
/// 1. Groups TimelineEvents into narrative chapters
/// 2. Assigns emotions based on event types
/// 3. Generates titles and summaries using templates
/// 4. Produces a complete Story ready for export or AI enhancement
public struct StoryEngine {

    // MARK: - Public API

    /// Generate a Story from a Timeline.
    public static func generate(from timeline: Timeline) -> Story {
        // Group events by kind
        let grouped = Dictionary(grouping: timeline.events) { $0.kind }

        var chapters: [Chapter] = []

        // 1. Opening — first contact
        if let firstEvents = grouped[.firstContact], let first = firstEvents.first {
            chapters.append(makeOpeningChapter(first))
        }

        // 2. Growth — milestones
        let milestones = (grouped[.milestone] ?? []).sorted { ($0.value ?? 0) < ($1.value ?? 0) }
        if !milestones.isEmpty {
            chapters.append(makeGrowthChapter(milestones, stats: timeline.statistics))
        }

        // 3. Peak — busiest day + peak hour
        var peakEvents: [TimelineEvent] = []
        if let bd = grouped[.busiestDay]?.first { peakEvents.append(bd) }
        if let ph = grouped[.peakHour]?.first { peakEvents.append(ph) }
        if !peakEvents.isEmpty {
            chapters.append(makePeakChapter(peakEvents))
        }

        // 4. Silence — longest silence
        if let silenceEvents = grouped[.longestSilence], let silence = silenceEvents.first {
            chapters.append(makeSilenceChapter(silence))
        }

        // 5. Streaks
        var streakEvents: [TimelineEvent] = []
        if let cs = grouped[.chatStreak]?.first { streakEvents.append(cs) }
        if let cu = grouped[.currentStreak]?.first { streakEvents.append(cu) }
        if !streakEvents.isEmpty {
            chapters.append(makeStreakChapter(streakEvents))
        }

        // 6. Anniversaries
        let anniversaries = (grouped[.anniversary] ?? []).sorted { ($0.value ?? 0) < ($1.value ?? 0) }
        for anniversary in anniversaries {
            chapters.append(makeAnniversaryChapter(anniversary))
        }

        // 7. Top contacts
        if let topEvents = grouped[.topContact] {
            for contact in topEvents.sorted(by: { ($0.value ?? 0) > ($1.value ?? 0) }).prefix(3) {
                chapters.append(makeContactChapter(contact))
            }
        }

        // 8. Closing — last contact
        if let lastEvents = grouped[.lastContact], let last = lastEvents.first {
            chapters.append(makeClosingChapter(last, stats: timeline.statistics))
        }

        // Sort chapters by importance (descending), then by type ordering
        chapters.sort { a, b in
            if a.importance != b.importance { return a.importance > b.importance }
            return chapterTypeOrder(a.chapterType) < chapterTypeOrder(b.chapterType)
        }

        // Generate story title
        let title = generateTitle(from: timeline)
        let subtitle = generateSubtitle(from: timeline)

        return Story(
            schemaVersion: 1,
            title: title,
            subtitle: subtitle,
            chapters: chapters,
            generatedAt: Date(),
            engineVersion: "1.0.0",
            metadata: StoryMetadata(
                platform: timeline.platform.rawValue,
                ownerName: timeline.owner.displayName,
                dateRangeStart: timeline.statistics.firstMessageDate,
                dateRangeEnd: timeline.statistics.lastMessageDate,
                totalMessages: timeline.statistics.totalMessages,
                totalDays: timeline.statistics.totalDays,
                totalChats: timeline.statistics.totalChats,
                topContactName: timeline.topContacts.first?.contact.displayName
            )
        )
    }

    // MARK: - Chapter Builders

    private static func makeOpeningChapter(_ event: TimelineEvent) -> Chapter {
        return Chapter(
            id: "opening",
            title: "初识",
            summary: "一切开始的地方。",
            emotion: .nostalgic,
            importance: 10,
            chapterType: .opening,
            eventIDs: [event.id],
            narrative: NarrativeTemplate(
                template: "从{date}的第一条消息开始，{owner}和{contact}的故事正式启幕。",
                variables: [
                    "date": formatDate(event.date),
                    "owner": "我",
                    "contact": event.chatName ?? "对方",
                ]
            )
        )
    }

    private static func makeGrowthChapter(
        _ milestones: [TimelineEvent],
        stats: ChatStatistics
    ) -> Chapter {
        let lastMilestone = milestones.last
        let summary: String
        if let lm = lastMilestone, let v = lm.value {
            let word = v >= 10000 ? "万条大关" : "\(v)条"
            summary = "消息量突破了\(word)，关系在日复一日的对话中悄然升温。"
        } else {
            summary = "消息量在日复一日的对话中悄然增长。"
        }

        return Chapter(
            id: "growth",
            title: "升温",
            summary: summary,
            emotion: .warm,
            importance: 8,
            chapterType: .growth,
            eventIDs: milestones.map { $0.id },
            narrative: NarrativeTemplate(
                template: "从最初的寒暄到{total_messages}条消息的累积，每一条都是这段关系的见证。",
                variables: [
                    "total_messages": "\(stats.totalMessages)",
                ]
            )
        )
    }

    private static func makePeakChapter(_ events: [TimelineEvent]) -> Chapter {
        let busiestDay = events.first { $0.kind == .busiestDay }
        let summary: String
        if let bd = busiestDay, let count = bd.value {
            summary = "\(formatDate(bd.date))，单日\(count)条消息，是聊得最尽兴的一天。"
        } else {
            summary = "这是你们聊得最热烈的时候。"
        }

        return Chapter(
            id: "peak",
            title: "热络",
            summary: summary,
            emotion: .excited,
            importance: 7,
            chapterType: .peak,
            eventIDs: events.map { $0.id },
            narrative: NarrativeTemplate(
                template: "在{date}这一天，消息像潮水般涌来——{count}条，是这段关系最炽热的瞬间。",
                variables: [
                    "date": busiestDay.map { formatDate($0.date) } ?? "",
                    "count": busiestDay.flatMap { $0.value.map { "\($0)" } } ?? "",
                ]
            )
        )
    }

    private static func makeSilenceChapter(_ event: TimelineEvent) -> Chapter {
        let days = event.value ?? 0
        let summary: String
        switch days {
        case 0..<7: summary = "短暂的安静。"
        case 7..<30: summary = "\(days)天的沉默，像一段未完的省略号。"
        case 30..<100: summary = "\(days)天没有说话。不是忘了，只是生活把彼此推向了不同的方向。"
        default: summary = "\(days)天的漫长沉默。但真正的羁绊，经得起时间的考验。"
        }

        return Chapter(
            id: "silence",
            title: "沉默",
            summary: summary,
            emotion: .bittersweet,
            importance: 6,
            chapterType: .silence,
            eventIDs: [event.id],
            narrative: NarrativeTemplate(
                template: "从{start_date}到{end_date}，整整{days}天。这段空白不是遗忘，而是另一种形式的惦记。",
                variables: [
                    "days": "\(days)",
                    "start_date": event.metadata["startDate"] ?? "",
                    "end_date": event.metadata["endDate"] ?? "",
                ]
            )
        )
    }

    private static func makeStreakChapter(_ events: [TimelineEvent]) -> Chapter {
        let longest = events.first { $0.kind == .chatStreak }
        let days = longest?.value ?? 0

        return Chapter(
            id: "streak",
            title: "习惯",
            summary: "连续\(days)天聊天，已经成了戒不掉的习惯。",
            emotion: .warm,
            importance: 7,
            chapterType: .growth,
            eventIDs: events.map { $0.id },
            narrative: NarrativeTemplate(
                template: "连续{days}天，每天都有对方的消息。这不是刻意，是自然而然的惦记。",
                variables: ["days": "\(days)"]
            )
        )
    }

    private static func makeAnniversaryChapter(_ event: TimelineEvent) -> Chapter {
        let years = event.value ?? 0
        let titles = [1: "一周年", 2: "两周年", 3: "三周年", 5: "五周年", 10: "十年"]
        let title = titles[years] ?? "\(years)周年"

        return Chapter(
            id: "anniversary_\(years)",
            title: title,
            summary: "认识\(years)年了。时间过得真快。",
            emotion: .joyful,
            importance: 9,
            chapterType: .anniversary,
            eventIDs: [event.id],
            narrative: NarrativeTemplate(
                template: years == 1
                ? "一年了。从陌生到熟悉，从你好到晚安，三百六十五天，每一天都算数。"
                : "\(years)年。\(years * 365)天。\(years * 365 * 24)小时。这不是数字，是陪伴。",
                variables: ["years": "\(years)"]
            )
        )
    }

    private static func makeContactChapter(_ event: TimelineEvent) -> Chapter {
        return Chapter(
            id: "contact_\(event.chatID ?? "")",
            title: "重要的人：\(event.chatName ?? "")",
            summary: event.description,
            emotion: .warm,
            importance: 5,
            chapterType: .other,
            eventIDs: [event.id],
            narrative: NarrativeTemplate(
                template: event.description,
                variables: [:]
            )
        )
    }

    private static func makeClosingChapter(
        _ event: TimelineEvent,
        stats: ChatStatistics
    ) -> Chapter {
        let messages = stats.totalMessages
        let days = stats.totalDays

        let summary: String
        if days > 365 {
            let years = days / 365
            summary = "\(years)年，\(messages)条消息。这就是你们的聊天回忆录。"
        } else {
            summary = "\(days)天，\(messages)条消息。故事还在继续。"
        }

        return Chapter(
            id: "closing",
            title: "未完待续",
            summary: summary,
            emotion: .reflective,
            importance: 10,
            chapterType: .closing,
            eventIDs: [event.id],
            narrative: NarrativeTemplate(
                template: "从{first_date}到{last_date}，{total_messages}条消息，{total_days}天。这不是结束，这是你们故事的第一章。",
                variables: [
                    "first_date": stats.firstMessageDate.map { formatDate($0) } ?? "",
                    "last_date": stats.lastMessageDate.map { formatDate($0) } ?? "",
                    "total_messages": "\(messages)",
                    "total_days": "\(days)",
                ]
            )
        )
    }

    // MARK: - Title Generation

    private static func generateTitle(from timeline: Timeline) -> String {
        let stats = timeline.statistics
        let topName = timeline.topContacts.first?.contact.displayName

        if let name = topName, stats.totalDays > 365 {
            let years = stats.totalDays / 365
            return "《\(name)与我：\(years)年聊天回忆录》"
        } else if let name = topName {
            return "《\(name)与我：\(stats.totalDays)天的对话》"
        } else if stats.totalMessages > 0 {
            return "《\(stats.totalMessages)条消息的故事》"
        } else {
            return "《聊天回忆录》"
        }
    }

    private static func generateSubtitle(from timeline: Timeline) -> String {
        let stats = timeline.statistics
        if stats.totalMessages == 0 {
            return "一段等待被填写的空白。"
        }
        if stats.totalDays > 365 {
            let years = stats.totalDays / 365
            return "\(years)年，\(stats.totalMessages)条消息，一个关于陪伴的故事。"
        }
        return "\(stats.totalDays)天，\(stats.totalMessages)条消息，一个关于陪伴的故事。"
    }

    // MARK: - Helpers

    private static func chapterTypeOrder(_ type: ChapterType) -> Int {
        switch type {
        case .opening: return 0
        case .growth: return 1
        case .peak: return 2
        case .silence: return 3
        case .turningPoint: return 4
        case .milestone: return 5
        case .anniversary: return 6
        case .closing: return 7
        case .other: return 8
        }
    }

    private static func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年M月d日"
        return fmt.string(from: date)
    }

    private static func formatNumber(_ n: Int) -> String {
        if n >= 10000 {
            return String(format: "%.1f万", Double(n) / 10000.0)
        }
        return "\(n)"
    }
}

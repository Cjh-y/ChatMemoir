import Foundation
import ChatImportKit

/// The Timeline Engine: converts a ChatDatabase into a Timeline.
///
/// All logic is algorithmic — no AI dependencies.
/// The engine extracts statistics, events, patterns, and rankings
/// that a Story Engine can later weave into a narrative.
public struct TimelineEngine {

    // MARK: - Config

    /// Milestone thresholds for message counts.
    public static let messageMilestones: [Int] = [
        1, 10, 50, 100, 500,
        1_000, 5_000, 10_000, 50_000, 100_000
    ]

    /// Day-count milestones for streaks.
    public static let streakMilestones: [Int] = [7, 30, 100, 365, 500, 1000]

    /// Anniversary years.
    public static let anniversaryYears: [Int] = [1, 2, 3, 5, 10]

    /// Top contacts to include.
    public static let topContactCount = 20

    // MARK: - Public API

    /// Generate a Timeline from a ChatDatabase.
    public static func generate(from db: ChatDatabase) -> Timeline {
        let allMessages = db.chats.flatMap { $0.messages }
        let sortedMessages = allMessages.sorted { $0.timestamp < $1.timestamp }

        // Statistics
        let stats = computeStatistics(db: db, sorted: sortedMessages)

        // Time distribution
        let hourly = computeHourlyDistribution(sortedMessages)
        let weekday = computeWeekdayDistribution(sortedMessages)
        let monthly = computeMonthlyDistribution(sortedMessages)
        let yearly = computeYearlyDistribution(sortedMessages)

        // Message types
        let typeBreakdown = computeMessageTypes(sortedMessages)

        // Streaks
        let streaks = computeStreaks(sortedMessages, stats: stats)

        // Response time
        let response = computeResponseTime(db: db)

        // Contacts
        let contacts = computeTopContacts(db: db, owner: db.owner)

        // Groups
        let groups = computeGroupStats(db: db)

        // Events
        let events = generateEvents(
            db: db, stats: stats, streaks: streaks,
            contacts: contacts, sorted: sortedMessages
        )

        // Sections
        let sections = buildSections(events: events)

        // Heatmap
        let heatmap = computeActivityHeatmap(sortedMessages)

        return Timeline(
            platform: db.platform,
            owner: db.owner,
            statistics: stats,
            hourlyDistribution: hourly,
            weekdayDistribution: weekday,
            monthlyDistribution: monthly,
            yearlyDistribution: yearly,
            messageTypeBreakdown: typeBreakdown,
            streaks: streaks,
            responseTime: response,
            topContacts: Array(contacts.prefix(Self.topContactCount)),
            groupStats: groups,
            events: events,
            sections: sections,
            activityHeatmap: heatmap
        )
    }

    // MARK: - Statistics

    private static func computeStatistics(
        db: ChatDatabase,
        sorted: [Message]
    ) -> ChatStatistics {
        let textMsgs = sorted.filter { $0.type == .text }
        let mediaMsgs = sorted.filter { $0.type != .text && $0.type != .system }
        let firstDate = sorted.first?.timestamp
        let lastDate = sorted.last?.timestamp

        let totalDays: Int
        if let f = firstDate, let l = lastDate {
            totalDays = max(1, Calendar.current.dateComponents([.day], from: f, to: l).day ?? 1)
        } else {
            totalDays = 0
        }

        let allParticipants = Set(db.chats.flatMap { $0.participants.map { $0.id } })
        let groupCount = db.chats.filter { $0.isGroupChat }.count
        let privateCount = db.chats.filter { !$0.isGroupChat }.count
        let activeChats = db.chats.filter { !$0.messages.isEmpty }.count

        return ChatStatistics(
            totalChats: db.chats.count,
            totalMessages: sorted.count,
            totalTextMessages: textMsgs.count,
            totalMediaMessages: mediaMsgs.count,
            totalDays: totalDays,
            firstMessageDate: firstDate,
            lastMessageDate: lastDate,
            averageMessagesPerDay: totalDays > 0 ? Double(sorted.count) / Double(totalDays) : 0,
            averageMessagesPerChat: db.chats.isEmpty ? 0 : Double(sorted.count) / Double(db.chats.count),
            activeChats: activeChats,
            totalParticipants: allParticipants.count,
            groupChats: groupCount,
            privateChats: privateCount
        )
    }

    // MARK: - Time Distribution

    private static func computeHourlyDistribution(_ messages: [Message]) -> [HourBucket] {
        let cal = Calendar.current
        var counts = [Int](repeating: 0, count: 24)
        for msg in messages {
            let hour = cal.component(.hour, from: msg.timestamp)
            counts[hour] += 1
        }
        return (0..<24).map { HourBucket(hour: $0, count: counts[$0], label: "\($0):00") }
    }

    private static func computeWeekdayDistribution(_ messages: [Message]) -> [WeekdayBucket] {
        let cal = Calendar.current
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var counts = [Int](repeating: 0, count: 7)
        for msg in messages {
            let wd = cal.component(.weekday, from: msg.timestamp) - 1
            counts[wd] += 1
        }
        return (0..<7).map {
            WeekdayBucket(weekday: $0, name: names[$0], count: counts[$0],
                          isWorkday: $0 >= 1 && $0 <= 5)
        }
    }

    private static func computeMonthlyDistribution(_ messages: [Message]) -> [MonthBucket] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM"
        var grouped: [String: (month: Int, year: Int, count: Int)] = [:]
        for msg in messages {
            let m = cal.component(.month, from: msg.timestamp)
            let y = cal.component(.year, from: msg.timestamp)
            let key = "\(y)-\(m)"
            if var entry = grouped[key] {
                entry.count += 1
                grouped[key] = entry
            } else {
                grouped[key] = (month: m, year: y, count: 1)
            }
        }
        return grouped.map {
            let d = Calendar.current.date(from: DateComponents(year: $0.value.year, month: $0.value.month)) ?? Date()
            return MonthBucket(month: $0.value.month, name: fmt.string(from: d), count: $0.value.count, year: $0.value.year)
        }.sorted { ($0.year, $0.month) < ($1.year, $1.month) }
    }

    private static func computeYearlyDistribution(_ messages: [Message]) -> [YearBucket] {
        let cal = Calendar.current
        var counts: [Int: Int] = [:]
        for msg in messages {
            let y = cal.component(.year, from: msg.timestamp)
            counts[y, default: 0] += 1
        }
        return counts.map { YearBucket(year: $0.key, count: $0.value) }
            .sorted { $0.year < $1.year }
    }

    // MARK: - Message Types

    private static func computeMessageTypes(_ messages: [Message]) -> MessageTypeBreakdown {
        var breakdown = MessageTypeBreakdown(
            text: 0, image: 0, voice: 0, video: 0, file: 0,
            sticker: 0, link: 0, location: 0, contact: 0,
            call: 0, system: 0, other: 0
        )
        for msg in messages {
            switch msg.type {
            case .text: breakdown = MessageTypeBreakdown(text: breakdown.text + 1, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .image: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image + 1, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .voice: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice + 1, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .video: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video + 1, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .file: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file + 1, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .sticker: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker + 1, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .link: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link + 1, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .location: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location + 1, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .contact: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact + 1, call: breakdown.call, system: breakdown.system, other: breakdown.other)
            case .call: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call + 1, system: breakdown.system, other: breakdown.other)
            case .system: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system + 1, other: breakdown.other)
            default: breakdown = MessageTypeBreakdown(text: breakdown.text, image: breakdown.image, voice: breakdown.voice, video: breakdown.video, file: breakdown.file, sticker: breakdown.sticker, link: breakdown.link, location: breakdown.location, contact: breakdown.contact, call: breakdown.call, system: breakdown.system, other: breakdown.other + 1)
            }
        }
        return breakdown
    }

    // MARK: - Streaks

    private static func computeStreaks(_ messages: [Message], stats: ChatStatistics) -> StreakInfo {
        guard !messages.isEmpty else {
            return StreakInfo(longestStreak: 0, longestStreakStart: nil, longestStreakEnd: nil,
                              currentStreak: 0, longestSilence: 0,
                              longestSilenceStart: nil, longestSilenceEnd: nil)
        }

        let cal = Calendar.current
        // Build set of dates with messages
        var activeDates = Set<Date>()
        for msg in messages {
            let day = cal.startOfDay(for: msg.timestamp)
            activeDates.insert(day)
        }
        let sortedDates = activeDates.sorted()

        // Compute longest streak
        var longestStreak = 1
        var currentRun = 1
        var longestStart = sortedDates[0]
        var longestEnd = sortedDates[0]
        var runStart = sortedDates[0]

        for i in 1..<sortedDates.count {
            let prev = sortedDates[i-1]
            let curr = sortedDates[i]
            if let diff = cal.dateComponents([.day], from: prev, to: curr).day, diff == 1 {
                currentRun += 1
                if currentRun > longestStreak {
                    longestStreak = currentRun
                    longestStart = runStart
                    longestEnd = curr
                }
            } else {
                // Check silence
                currentRun = 1
                runStart = curr
            }
        }

        // Current streak
        let today = cal.startOfDay(for: Date())
        var currentStreak = 0
        var checkDate = today
        while activeDates.contains(checkDate) {
            currentStreak += 1
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        // Longest silence
        var longestSilence = 0
        var silenceStart: Date? = nil
        var silenceEnd: Date? = nil
        for i in 1..<sortedDates.count {
            if let diff = cal.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day, diff > 1 {
                let gap = diff - 1
                if gap > longestSilence {
                    longestSilence = gap
                    silenceStart = cal.date(byAdding: .day, value: 1, to: sortedDates[i-1])
                    silenceEnd = cal.date(byAdding: .day, value: -1, to: sortedDates[i])
                }
            }
        }

        return StreakInfo(
            longestStreak: longestStreak,
            longestStreakStart: longestStart,
            longestStreakEnd: longestEnd,
            currentStreak: currentStreak,
            longestSilence: longestSilence,
            longestSilenceStart: silenceStart,
            longestSilenceEnd: silenceEnd
        )
    }

    // MARK: - Response Time

    private static func computeResponseTime(db: ChatDatabase) -> ResponseTimeInfo {
        var allIntervals: [TimeInterval] = []
        var weekdayCount = 0
        var weekendCount = 0
        let cal = Calendar.current

        for chat in db.chats {
            let msgs = chat.messages.sorted { $0.timestamp < $1.timestamp }
            for i in 1..<msgs.count {
                let prev = msgs[i-1]
                let curr = msgs[i]
                // Only count when different people send
                if prev.sender.id != curr.sender.id {
                    let interval = curr.timestamp.timeIntervalSince(prev.timestamp)
                    if interval > 0 && interval < 86400 { // Less than 24 hours
                        allIntervals.append(interval)
                    }
                }
                let wd = cal.component(.weekday, from: curr.timestamp)
                if wd >= 2 && wd <= 6 { weekdayCount += 1 }
                else { weekendCount += 1 }
            }
        }

        let sortedIntervals = allIntervals.sorted()
        let avg = allIntervals.isEmpty ? nil : allIntervals.reduce(0, +) / Double(allIntervals.count)
        let median = sortedIntervals.isEmpty ? nil : sortedIntervals[sortedIntervals.count / 2]
        let fastest = sortedIntervals.first

        let total = weekdayCount + weekendCount
        let ratio = weekendCount > 0 ? Double(weekdayCount) / Double(weekendCount) : nil
        let pct = total > 0 ? Double(weekdayCount) / Double(total) * 100 : nil

        return ResponseTimeInfo(
            averageResponseSeconds: avg,
            medianResponseSeconds: median,
            fastestResponseSeconds: fastest,
            weekdayWeekendRatio: ratio,
            workdayPercentage: pct
        )
    }

    // MARK: - Top Contacts

    private static func computeTopContacts(db: ChatDatabase, owner: Participant) -> [ContactRank] {
        var counts: [String: (participant: Participant, count: Int)] = [:]
        for chat in db.chats {
            for msg in chat.messages {
                let key = msg.sender.id
                if key == owner.id { continue }
                if var entry = counts[key] {
                    entry.count += 1
                    counts[key] = entry
                } else {
                    counts[key] = (msg.sender, 1)
                }
            }
        }
        let total = counts.values.reduce(0) { $0 + $1.count }
        return counts.values
            .sorted { $0.count > $1.count }
            .enumerated()
            .map {
                ContactRank(
                    rank: $0.offset + 1,
                    contact: $0.element.participant,
                    messageCount: $0.element.count,
                    percentageOfTotal: total > 0 ? Double($0.element.count) / Double(total) * 100 : 0
                )
            }
    }

    // MARK: - Group Stats

    private static func computeGroupStats(db: ChatDatabase) -> GroupStats {
        let groups = db.chats.filter { $0.isGroupChat }
        let largest = groups.max(by: { $0.participants.count < $1.participants.count })
        let avgSize = groups.isEmpty ? 0 : Double(groups.reduce(0) { $0 + $1.participants.count }) / Double(groups.count)
        return GroupStats(
            totalGroups: groups.count,
            largestGroupName: largest?.displayName,
            largestGroupSize: largest?.participants.count ?? 0,
            averageGroupSize: avgSize
        )
    }

    // MARK: - Activity Heatmap

    private static func computeActivityHeatmap(_ messages: [Message]) -> ActivityHeatmap {
        let cal = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: 24), count: 7)

        for msg in messages {
            let wd = cal.component(.weekday, from: msg.timestamp) - 1
            let hr = cal.component(.hour, from: msg.timestamp)
            if wd >= 0 && wd < 7 && hr >= 0 && hr < 24 {
                matrix[wd][hr] += 1
            }
        }

        let rows = (0..<7).map { ActivityHeatmap.HeatmapRow(dayName: dayNames[$0], hours: matrix[$0]) }
        return ActivityHeatmap(rows: rows)
    }

    // MARK: - Event Generation

    private static func generateEvents(
        db: ChatDatabase,
        stats: ChatStatistics,
        streaks: StreakInfo,
        contacts: [ContactRank],
        sorted: [Message]
    ) -> [TimelineEvent] {
        var events: [TimelineEvent] = []
        let cal = Calendar.current

        // Helper
        func addEvent(_ e: TimelineEvent) { events.append(e) }

        // 1. First contact
        if let first = sorted.first {
            addEvent(TimelineEvent(
                kind: .firstContact,
                title: "第一次聊天",
                date: first.timestamp,
                description: "一切开始的地方。你们的第一条消息。",
                value: stats.totalMessages
            ))
        }

        // 2. Last contact
        if let last = sorted.last, stats.totalMessages > 1 {
            addEvent(TimelineEvent(
                kind: .lastContact,
                title: "最近一次聊天",
                date: last.timestamp,
                description: "最近的消息，故事还在继续。",
                value: stats.totalMessages
            ))
        }

        // 3. Message milestones
        for milestone in Self.messageMilestones {
            if stats.totalMessages >= milestone && milestone > 1 {
                // Find the date when this milestone was hit
                var running = 0
                var milestoneDate: Date?
                for msg in sorted {
                    running += 1
                    if running == milestone {
                        milestoneDate = msg.timestamp
                        break
                    }
                }
                if let md = milestoneDate {
                    addEvent(TimelineEvent(
                        kind: .milestone,
                        title: "第\(formatNumber(milestone))条消息",
                        date: md,
                        description: "这一天，你们的聊天正式突破了\(formatNumber(milestone))条。",
                        value: milestone
                    ))
                }
            }
        }

        // 4. Peak activity - busiest day
        var dayCounts: [Date: Int] = [:]
        for msg in sorted {
            let day = cal.startOfDay(for: msg.timestamp)
            dayCounts[day, default: 0] += 1
        }
        if let busiest = dayCounts.max(by: { $0.value < $1.value }) {
            addEvent(TimelineEvent(
                kind: .busiestDay,
                title: "消息最多的一天",
                date: busiest.key,
                description: "这一天你们发了\(busiest.value)条消息，是聊天最密集的一天。",
                value: busiest.value
            ))
        }

        // 5. Peak hour
        let hourly = computeHourlyDistribution(sorted)
        if let peak = hourly.max(by: { $0.count < $1.count }), peak.count > 0 {
            // Find a representative timestamp in that hour
            let repDate = sorted.first(where: { cal.component(.hour, from: $0.timestamp) == peak.hour })?.timestamp ?? Date()
            addEvent(TimelineEvent(
                kind: .peakHour,
                title: "最活跃的时段",
                date: repDate,
                description: "你们在\(peak.label)左右最活跃，这段时间一共发了\(peak.count)条消息。",
                value: peak.count,
                metadata: ["hour": "\(peak.hour)"]
            ))
        }

        // 6. Longest streak
        if streaks.longestStreak >= 7, let start = streaks.longestStreakStart {
            addEvent(TimelineEvent(
                kind: .chatStreak,
                title: "最长连续聊天：\(streaks.longestStreak)天",
                date: start,
                description: "从\(formatDate(start))开始，你们连续聊了\(streaks.longestStreak)天没有间断。",
                value: streaks.longestStreak,
                metadata: ["endDate": streaks.longestStreakEnd.map { ISO8601DateFormatter().string(from: $0) } ?? ""]
            ))
        }

        // 7. Longest silence
        if streaks.longestSilence >= 30, let start = streaks.longestSilenceStart {
            addEvent(TimelineEvent(
                kind: .longestSilence,
                title: "最长的沉默：\(streaks.longestSilence)天",
                date: start,
                description: "从\(formatDate(start))开始，你们有\(streaks.longestSilence)天没有说话。",
                value: streaks.longestSilence
            ))
        }

        // 8. Current streak
        if streaks.currentStreak >= 7 {
            addEvent(TimelineEvent(
                kind: .currentStreak,
                title: "连续聊天\(streaks.currentStreak)天",
                date: Date(),
                description: "你们已经连续聊了\(streaks.currentStreak)天，还在继续！",
                value: streaks.currentStreak
            ))
        }

        // 9. Anniversaries
        if let firstDate = stats.firstMessageDate {
            let years = cal.dateComponents([.year], from: firstDate, to: Date()).year ?? 0
            for y in Self.anniversaryYears where y <= years {
                if let anniversaryDate = cal.date(byAdding: .year, value: y, to: firstDate) {
                    addEvent(TimelineEvent(
                        kind: .anniversary,
                        title: "认识\(y)周年",
                        date: anniversaryDate,
                        description: y == 1 ? "认识一周年了！" : "认识\(y)周年了！一路走来不容易。",
                        value: y
                    ))
                }
            }
        }

        // 10. Top contacts
        for contact in contacts.prefix(5) where contact.rank <= 5 {
            addEvent(TimelineEvent(
                kind: .topContact,
                title: "#\(contact.rank) 高频联系人：\(contact.contact.displayName)",
                date: stats.firstMessageDate ?? Date(),
                description: "和\(contact.contact.displayName)一共发了\(formatNumber(contact.messageCount))条消息，占全部对话的\(String(format: "%.1f", contact.percentageOfTotal))%。",
                chatID: contact.contact.id,
                chatName: contact.contact.displayName,
                value: contact.messageCount
            ))
        }

        // 11. Streak milestones
        for ms in Self.streakMilestones where streaks.longestStreak >= ms {
            if let _ = streaks.longestStreakStart {
                addEvent(TimelineEvent(
                    kind: .milestone,
                    title: "连续\(ms)天聊天达成",
                    date: streaks.longestStreakStart!,
                    description: "你们曾经连续\(ms)天保持聊天，从未间断。",
                    value: ms
                ))
                break // Only add one streak milestone
            }
        }

        // Sort by date
        events.sort { $0.date < $1.date }
        return events
    }

    // MARK: - Sections

    private static func buildSections(events: [TimelineEvent]) -> [TimelineSection] {
        let grouped = Dictionary(grouping: events) { $0.kind }
        var sections: [TimelineSection] = []

        let sectionDefs: [(title: String, icon: String, kinds: [TimelineEvent.Kind], order: Int)] = [
            ("重要时刻", "star", [.firstContact, .lastContact, .anniversary], 1),
            ("里程碑", "flag", [.milestone], 2),
            ("活跃度", "flame", [.busiestDay, .peakHour, .peakActivity], 3),
            ("关系深度", "heart", [.chatStreak, .currentStreak, .longestSilence], 4),
            ("重要的人", "person", [.topContact], 5),
        ]

        for def in sectionDefs {
            let sectionEvents = def.kinds.flatMap { grouped[$0] ?? [] }
            if !sectionEvents.isEmpty {
                sections.append(TimelineSection(
                    id: def.title,
                    title: def.title,
                    subtitle: "\(sectionEvents.count)个事件",
                    icon: def.icon,
                    eventIDs: sectionEvents.map { $0.id },
                    sortOrder: def.order
                ))
            }
        }

        return sections.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Helpers

    private static func formatNumber(_ n: Int) -> String {
        if n >= 10000 {
            return String(format: "%.1f万", Double(n) / 10000.0)
        }
        return "\(n)"
    }

    private static func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年M月d日"
        return fmt.string(from: date)
    }
}

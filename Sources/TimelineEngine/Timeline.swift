import Foundation
import ChatImportKit

/// A computed timeline from chat data.
///
/// The Timeline is the output of the TimelineEngine. It contains:
/// - Overall statistics
/// - Events (milestones, peaks, firsts)
/// - Time distribution (by hour, day, week, month, year)
/// - Activity heatmap data
/// - Relationship trends
/// - Sections for grouping
///
/// The Timeline is consumed by the Story Engine (future) and
/// can be exported as JSON.
public struct Timeline: Codable, Sendable {

    // MARK: - Metadata

    /// Schema version for JSON compatibility.
    public let schemaVersion: Int

    /// Which platform this timeline was generated from.
    public let platform: ChatPlatform

    /// When the timeline was generated.
    public let generatedAt: Date

    /// The owner ("me").
    public let owner: Participant

    /// Version of the engine used.
    public let engineVersion: String

    // MARK: - Statistics

    /// Overall chat statistics.
    public let statistics: ChatStatistics

    // MARK: - Time Distribution

    /// Message counts per hour (0-23).
    public let hourlyDistribution: [HourBucket]

    /// Message counts per day of week (0=Sun, 6=Sat).
    public let weekdayDistribution: [WeekdayBucket]

    /// Message counts per month (1-12).
    public let monthlyDistribution: [MonthBucket]

    /// Message counts per year.
    public let yearlyDistribution: [YearBucket]

    // MARK: - Message Types

    /// Breakdown of messages by type.
    public let messageTypeBreakdown: MessageTypeBreakdown

    // MARK: - Streaks & Patterns

    /// Chat streak information.
    public let streaks: StreakInfo

    /// Response time analysis.
    public let responseTime: ResponseTimeInfo

    // MARK: - Contacts

    /// Top contacts ranked by message count.
    public let topContacts: [ContactRank]

    // MARK: - Group Chats

    /// Group chat statistics.
    public let groupStats: GroupStats

    // MARK: - Events

    /// All generated events, sorted by date.
    public let events: [TimelineEvent]

    // MARK: - Sections

    /// Logical groupings of events.
    public let sections: [TimelineSection]

    /// Activity heatmap data (day × hour matrix).
    public let activityHeatmap: ActivityHeatmap

    // MARK: - Init

    public init(
        platform: ChatPlatform,
        owner: Participant,
        statistics: ChatStatistics,
        hourlyDistribution: [HourBucket],
        weekdayDistribution: [WeekdayBucket],
        monthlyDistribution: [MonthBucket],
        yearlyDistribution: [YearBucket],
        messageTypeBreakdown: MessageTypeBreakdown,
        streaks: StreakInfo,
        responseTime: ResponseTimeInfo,
        topContacts: [ContactRank],
        groupStats: GroupStats,
        events: [TimelineEvent],
        sections: [TimelineSection],
        activityHeatmap: ActivityHeatmap
    ) {
        self.schemaVersion = 1
        self.platform = platform
        self.generatedAt = Date()
        self.owner = owner
        self.engineVersion = "1.0.0"
        self.statistics = statistics
        self.hourlyDistribution = hourlyDistribution
        self.weekdayDistribution = weekdayDistribution
        self.monthlyDistribution = monthlyDistribution
        self.yearlyDistribution = yearlyDistribution
        self.messageTypeBreakdown = messageTypeBreakdown
        self.streaks = streaks
        self.responseTime = responseTime
        self.topContacts = topContacts
        self.groupStats = groupStats
        self.events = events
        self.sections = sections
        self.activityHeatmap = activityHeatmap
    }

    // MARK: - JSON Export

    public func toJSON(pretty: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = pretty
            ? [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            : [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

// MARK: - Statistics

/// Overall chat statistics.
public struct ChatStatistics: Codable, Sendable {
    public let totalChats: Int
    public let totalMessages: Int
    public let totalTextMessages: Int
    public let totalMediaMessages: Int
    public let totalDays: Int
    public let firstMessageDate: Date?
    public let lastMessageDate: Date?
    public let averageMessagesPerDay: Double
    public let averageMessagesPerChat: Double
    public let activeChats: Int
    public let totalParticipants: Int
    public let groupChats: Int
    public let privateChats: Int
}

// MARK: - Time Distribution

public struct HourBucket: Codable, Sendable {
    public let hour: Int
    public let count: Int
    public let label: String
}

public struct WeekdayBucket: Codable, Sendable {
    public let weekday: Int
    public let name: String
    public let count: Int
    public let isWorkday: Bool
}

public struct MonthBucket: Codable, Sendable {
    public let month: Int
    public let name: String
    public let count: Int
    public let year: Int
}

public struct YearBucket: Codable, Sendable {
    public let year: Int
    public let count: Int
}

// MARK: - Message Type Breakdown

public struct MessageTypeBreakdown: Codable, Sendable {
    public let text: Int
    public let image: Int
    public let voice: Int
    public let video: Int
    public let file: Int
    public let sticker: Int
    public let link: Int
    public let location: Int
    public let contact: Int
    public let call: Int
    public let system: Int
    public let other: Int

    public var total: Int {
        text + image + voice + video + file + sticker + link + location + contact + call + system + other
    }
}

// MARK: - Streaks

public struct StreakInfo: Codable, Sendable {
    /// Longest consecutive days with messages.
    public let longestStreak: Int
    /// Start date of the longest streak.
    public let longestStreakStart: Date?
    /// End date of the longest streak.
    public let longestStreakEnd: Date?
    /// Current consecutive days with messages.
    public let currentStreak: Int
    /// Longest silence (days without messages).
    public let longestSilence: Int
    /// Start date of the longest silence.
    public let longestSilenceStart: Date?
    /// End date of the longest silence.
    public let longestSilenceEnd: Date?
}

// MARK: - Response Time

public struct ResponseTimeInfo: Codable, Sendable {
    /// Average time between messages in the same chat (seconds).
    public let averageResponseSeconds: TimeInterval?
    /// Median response time.
    public let medianResponseSeconds: TimeInterval?
    /// Fastest response time.
    public let fastestResponseSeconds: TimeInterval?
    /// Weekday vs weekend ratio (messages on weekdays / messages on weekends).
    public let weekdayWeekendRatio: Double?
    /// Percentage of messages on workdays.
    public let workdayPercentage: Double?
}

// MARK: - Contact Rank

public struct ContactRank: Codable, Sendable {
    public let rank: Int
    public let contact: Participant
    public let messageCount: Int
    public let percentageOfTotal: Double
}

// MARK: - Group Stats

public struct GroupStats: Codable, Sendable {
    public let totalGroups: Int
    public let largestGroupName: String?
    public let largestGroupSize: Int
    public let averageGroupSize: Double
}

// MARK: - Activity Heatmap

/// A day-of-week × hour-of-day matrix of message counts.
/// rows[0] = Sunday, rows[6] = Saturday.
/// Each row has 24 columns (hours 0-23).
public struct ActivityHeatmap: Codable, Sendable {
    public let rows: [HeatmapRow]

    public struct HeatmapRow: Codable, Sendable {
        public let dayName: String
        public let hours: [Int]
    }
}

// MARK: - Timeline Section

public struct TimelineSection: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let eventIDs: [String]
    public let sortOrder: Int
}

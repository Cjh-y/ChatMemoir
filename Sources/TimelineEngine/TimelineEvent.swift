import Foundation

/// A significant event in a chat timeline.
///
/// Generated algorithmically (no AI). Each event represents something
/// worth remembering — a milestone, a peak, a first, a silence.
///
/// Events are designed to be consumable by a Story Engine that
/// weaves them into a coherent narrative.
public struct TimelineEvent: Codable, Sendable, Identifiable {
    public let id: String

    /// The type of event.
    public let kind: Kind

    /// Human-readable title (e.g. "第10000条消息")
    public let title: String

    /// When this event occurred.
    public let date: Date

    /// A longer description suitable for narrative generation.
    public let description: String

    /// Which chat this event belongs to (nil = global event).
    public let chatID: String?

    /// The chat display name, for context.
    public let chatName: String?

    /// Numeric value associated with the event (message count, days, etc.).
    public let value: Int?

    /// Additional metadata.
    public let metadata: [String: String]

    public enum Kind: String, Codable, Sendable {
        /// First message ever exchanged
        case firstContact

        /// Last message (or most recent)
        case lastContact

        /// Numeric milestone (10k messages, 100 days, etc.)
        case milestone

        /// Peak activity day/week
        case peakActivity

        /// Longest period of silence
        case longestSilence

        /// Current unbroken chat streak
        case currentStreak

        /// Anniversary (1 year, 2 years, etc.)
        case anniversary

        /// A period of consecutive daily chat
        case chatStreak

        /// High-frequency contact ranking
        case topContact

        /// Most messages in a single day
        case busiestDay

        /// Most active hour of the day
        case peakHour

        /// Friendship turning point (message volume doubled, etc.)
        case turningPoint

        /// Custom / other
        case other
    }

    public init(
        id: String = UUID().uuidString,
        kind: Kind,
        title: String,
        date: Date,
        description: String,
        chatID: String? = nil,
        chatName: String? = nil,
        value: Int? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.date = date
        self.description = description
        self.chatID = chatID
        self.chatName = chatName
        self.value = value
        self.metadata = metadata
    }
}

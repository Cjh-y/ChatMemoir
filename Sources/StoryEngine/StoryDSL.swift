import Foundation
import TimelineEngine

// MARK: - Story

/// A complete story built from a Timeline.
///
/// The Story is the output of the StoryEngine.
/// It contains chapters that weave TimelineEvents into a coherent narrative.
/// Designed to be consumed by:
/// - A SwiftUI renderer
/// - An AI adapter (future)
/// - JSON export for external tools
public struct Story: Codable, Sendable {
    /// Schema version for compatibility.
    public let schemaVersion: Int

    /// The story title, auto-generated from data.
    public let title: String

    /// A one-line subtitle.
    public let subtitle: String

    /// Chapters in narrative order.
    public let chapters: [Chapter]

    /// When this story was generated.
    public let generatedAt: Date

    /// Engine version.
    public let engineVersion: String

    /// Story-level metadata.
    public let metadata: StoryMetadata

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

// MARK: - Story Metadata

public struct StoryMetadata: Codable, Sendable {
    public let platform: String
    public let ownerName: String
    public let dateRangeStart: Date?
    public let dateRangeEnd: Date?
    public let totalMessages: Int
    public let totalDays: Int
    public let totalChats: Int
    public let topContactName: String?
}

// MARK: - Chapter

/// A chapter in the story.
///
/// Each chapter has a narrative purpose: opening, growth, milestone, etc.
/// Chapters are composed of related TimelineEvents.
public struct Chapter: Codable, Sendable, Identifiable {
    public let id: String
    /// The chapter title (e.g., "初识", "热络期", "一周年")
    public let title: String
    /// A one-line summary.
    public let summary: String
    /// The emotional tone of this chapter.
    public let emotion: ChapterEmotion
    /// Importance from 1 (minor) to 10 (pivotal).
    public let importance: Int
    /// The chapter's role in the story arc.
    public let chapterType: ChapterType
    /// TimelineEvents that belong to this chapter.
    public let eventIDs: [String]
    /// Optional narrative template for AI fill-in.
    public let narrative: NarrativeTemplate?
}

// MARK: - Chapter Emotion

/// The emotional tone of a chapter.
public enum ChapterEmotion: String, Codable, Sendable {
    /// Pure happiness — first contact, anniversary
    case joyful
    /// Looking back fondly
    case nostalgic
    /// Happy and sad mixed
    case bittersweet
    /// Comfortable, familiar
    case warm
    /// High energy, lots of messages
    case excited
    /// Quiet, peaceful
    case calm
    /// Thoughtful, introspective
    case reflective
    /// Achievement, milestone
    case proud
    /// Neutral / informational
    case neutral
}

// MARK: - Chapter Type

/// The narrative role of a chapter.
public enum ChapterType: String, Codable, Sendable {
    /// The beginning of the story
    case opening
    /// Period of growing closeness
    case growth
    /// Peak activity — the golden age
    case peak
    /// A period of silence or distance
    case silence
    /// A numeric milestone
    case milestone
    /// A yearly anniversary
    case anniversary
    /// Where things stand now
    case closing
    /// A turning point or change
    case turningPoint
    /// Custom / other
    case other
}

// MARK: - Narrative Template

/// A fill-in-the-blank narrative template.
///
/// Designed for future AI adaptation:
/// - `template` contains placeholders like `{first_date}`, `{contact_name}`
/// - `variables` maps placeholder keys to their values
/// - AI can replace the template with natural language while keeping the structure
public struct NarrativeTemplate: Codable, Sendable {
    /// The template text with {variable} placeholders.
    public let template: String

    /// Variable values for filling in the template.
    public let variables: [String: String]

    public init(template: String, variables: [String: String]) {
        self.template = template
        self.variables = variables
    }

    /// Fill in the template with actual values (no AI).
    public func fill() -> String {
        var result = template
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}

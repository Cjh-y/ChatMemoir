import Foundation

// MARK: - RenderDocument

/// The rendered output of a Story, ready for display or export.
///
/// RenderDocument is UI-agnostic. It contains pages of blocks
/// that any renderer (SwiftUI, HTML, PDF) can consume.
public struct RenderDocument: Codable, Sendable {
    public let schemaVersion: Int
    public let title: String
    public let subtitle: String
    public let pages: [RenderPage]
    public let cards: [StoryCard]
    public let theme: RenderTheme
    public let metadata: RenderMetadata
    public let generatedAt: Date
    public let engineVersion: String

    public init(
        title: String, subtitle: String,
        pages: [RenderPage], cards: [StoryCard],
        theme: RenderTheme, metadata: RenderMetadata
    ) {
        self.schemaVersion = 1
        self.title = title
        self.subtitle = subtitle
        self.pages = pages
        self.cards = cards
        self.theme = theme
        self.metadata = metadata
        self.generatedAt = Date()
        self.engineVersion = "1.0.0"
    }
}

// MARK: - RenderMetadata

public struct RenderMetadata: Codable, Sendable {
    public let platform: String
    public let ownerName: String
    public let totalMessages: Int
    public let totalDays: Int
    public let topContact: String?
    public let dateRange: String
    public let readingMode: ReadingMode

    public enum ReadingMode: String, Codable, Sendable {
        case memoir
        case wrapped
        case timeline
        case cards
    }
}

// MARK: - RenderPage

/// A single page in the rendered document.
public struct RenderPage: Codable, Sendable, Identifiable {
    public let id: String
    public let pageNumber: Int
    public let pageType: PageType
    public let blocks: [RenderBlock]
    public let estimatedReadingTime: TimeInterval

    public enum PageType: String, Codable, Sendable {
        case cover
        case chapter
        case content
        case closing
        case divider
    }
}

// MARK: - RenderBlock

/// The atomic unit of rendering.
///
/// Each block type carries `rawText` (template-generated)
/// and `rewrittenText` (future AI fill-in, currently nil).
public indirect enum RenderBlock: Codable, Sendable {
    case title(TitleBlock)
    case subtitle(SubtitleBlock)
    case paragraph(ParagraphBlock)
    case quote(QuoteBlock)
    case statistic(StatisticBlock)
    case milestone(MilestoneBlock)
    case divider(DividerBlock)
    case spacer(SpacerBlock)
    case imagePlaceholder(ImagePlaceholderBlock)
    case storyCard(StoryCardBlock)
    case chapterHeader(ChapterHeaderBlock)
    case emotionTag(EmotionTagBlock)

    // MARK: - Block Types

    public struct TitleBlock: Codable, Sendable {
        public let rawText: String
        public var rewrittenText: String?
        public let level: Int  // 1 = h1, 2 = h2
    }

    public struct SubtitleBlock: Codable, Sendable {
        public let rawText: String
        public var rewrittenText: String?
    }

    public struct ParagraphBlock: Codable, Sendable {
        public let rawText: String
        public var rewrittenText: String?
    }

    public struct QuoteBlock: Codable, Sendable {
        public let rawText: String
        public var rewrittenText: String?
        public let attribution: String?
    }

    public struct StatisticBlock: Codable, Sendable {
        public let label: String
        public let value: String
        public let unit: String?
        public let rawText: String
        public var rewrittenText: String?
    }

    public struct MilestoneBlock: Codable, Sendable {
        public let title: String
        public let date: Date?
        public let rawText: String
        public var rewrittenText: String?
    }

    public struct DividerBlock: Codable, Sendable {
        public let style: DividerStyle
        public enum DividerStyle: String, Codable, Sendable {
            case plain, decorated, chapter
        }
    }

    public struct SpacerBlock: Codable, Sendable {
        public let size: SpacerSize
        public enum SpacerSize: String, Codable, Sendable {
            case small, medium, large
        }
    }

    public struct ImagePlaceholderBlock: Codable, Sendable {
        public let caption: String?
        public let suggestedContent: String?
    }

    public struct StoryCardBlock: Codable, Sendable {
        public let card: StoryCard
    }

    public struct ChapterHeaderBlock: Codable, Sendable {
        public let number: Int?
        public let title: String
        public let emotion: String
    }

    public struct EmotionTagBlock: Codable, Sendable {
        public let emotion: String
        public let label: String
    }
}

// MARK: - RenderTheme

/// The visual theme for the document.
public struct RenderTheme: Codable, Sendable {
    public let name: String
    public let typography: Typography
    public let spacing: Spacing
    public let cornerRadius: Double
    public let animationHint: AnimationHint

    public struct Typography: Codable, Sendable {
        public let titleFont: String
        public let bodyFont: String
        public let captionFont: String
        public let titleSize: Double
        public let bodySize: Double
        public let captionSize: Double
    }

    public struct Spacing: Codable, Sendable {
        public let pageMargin: Double
        public let paragraphSpacing: Double
        public let blockSpacing: Double
    }

    public struct AnimationHint: Codable, Sendable {
        public let pageTransition: String
        public let blockReveal: String
    }

    // MARK: - Preset Themes

    public static let memoir = RenderTheme(
        name: "memoir",
        typography: Typography(titleFont: "Georgia", bodyFont: "Georgia", captionFont: "Helvetica",
                               titleSize: 28, bodySize: 16, captionSize: 12),
        spacing: Spacing(pageMargin: 40, paragraphSpacing: 24, blockSpacing: 32),
        cornerRadius: 4,
        animationHint: AnimationHint(pageTransition: "fade", blockReveal: "fadeIn")
    )

    public static let warm = RenderTheme(
        name: "warm",
        typography: Typography(titleFont: "Avenir", bodyFont: "Avenir", captionFont: "Avenir",
                               titleSize: 32, bodySize: 17, captionSize: 13),
        spacing: Spacing(pageMargin: 32, paragraphSpacing: 20, blockSpacing: 28),
        cornerRadius: 12,
        animationHint: AnimationHint(pageTransition: "slideUp", blockReveal: "scaleIn")
    )

    public static let minimal = RenderTheme(
        name: "minimal",
        typography: Typography(titleFont: "Helvetica Neue", bodyFont: "Helvetica Neue", captionFont: "Helvetica Neue",
                               titleSize: 24, bodySize: 15, captionSize: 11),
        spacing: Spacing(pageMargin: 48, paragraphSpacing: 16, blockSpacing: 24),
        cornerRadius: 0,
        animationHint: AnimationHint(pageTransition: "none", blockReveal: "none")
    )

    public static let midnight = RenderTheme(
        name: "midnight",
        typography: Typography(titleFont: "Menlo", bodyFont: "Menlo", captionFont: "Menlo",
                               titleSize: 26, bodySize: 15, captionSize: 12),
        spacing: Spacing(pageMargin: 36, paragraphSpacing: 22, blockSpacing: 30),
        cornerRadius: 8,
        animationHint: AnimationHint(pageTransition: "dissolve", blockReveal: "typewriter")
    )
}

// MARK: - StoryCard

/// A shareable card extracted from the Story.
///
/// StoryCards are the foundation of the sharing feature.
/// Each card captures a single memorable moment with
/// a title, subtitle, statistic, and emotional tone.
public struct StoryCard: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let highlight: String?
    public let statisticValue: String?
    public let statisticLabel: String?
    public let emotion: String
    public let theme: String
    public let associatedEventID: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        highlight: String? = nil,
        statisticValue: String? = nil,
        statisticLabel: String? = nil,
        emotion: String,
        theme: String = "warm",
        associatedEventID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.highlight = highlight
        self.statisticValue = statisticValue
        self.statisticLabel = statisticLabel
        self.emotion = emotion
        self.theme = theme
        self.associatedEventID = associatedEventID
    }
}

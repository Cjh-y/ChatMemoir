import Foundation
import StoryEngine

/// The Presentation Engine: converts a Story into a RenderDocument.
///
/// Handles:
/// - Smart pagination (content-based, not chapter-based)
/// - Block generation (titles, quotes, stats, milestones)
/// - StoryCard extraction
/// - Cover and closing page generation
/// - Theme application
public struct PresentationEngine {

    // MARK: - Pagination Config

    /// Approximate blocks per page before splitting.
    public static var blocksPerPage: Int = 8

    /// Whether to force new page on each chapter.
    public static var forceNewPagePerChapter: Bool = false

    // MARK: - Public API

    /// Convert a Story into a RenderDocument.
    public static func render(
        story: Story,
        theme: RenderTheme = .memoir,
        mode: RenderMetadata.ReadingMode = .memoir
    ) -> RenderDocument {
        var pages: [RenderPage] = []
        var allCards: [StoryCard] = []
        var pageNum = 0

        // 1. Cover page
        pages.append(makeCoverPage(story: story, number: &pageNum))

        // 2. Chapter pages
        for chapter in story.chapters {
            let blocks = renderChapter(chapter, story: story)
            let chapterCards = extractCards(from: chapter, story: story)
            allCards.append(contentsOf: chapterCards)

            // Split into pages
            let chunked = chunkBlocks(blocks)
            for (i, chunk) in chunked.enumerated() {
                pageNum += 1
                let pageType: RenderPage.PageType
                if i == 0 {
                    pageType = .chapter
                } else {
                    pageType = .content
                }
                pages.append(RenderPage(
                    id: "p\(pageNum)",
                    pageNumber: pageNum,
                    pageType: pageType,
                    blocks: chunk,
                    estimatedReadingTime: Double(chunk.count) * 5.0  // ~5s per block
                ))
            }

            // Optional divider
            pages.append(makeDividerPage(number: &pageNum))
        }

        // 3. Closing page
        pages.append(makeClosingPage(story: story, number: &pageNum))

        // Metadata
        let metadata = RenderMetadata(
            platform: story.metadata.platform,
            ownerName: story.metadata.ownerName,
            totalMessages: story.metadata.totalMessages,
            totalDays: story.metadata.totalDays,
            topContact: story.metadata.topContactName,
            dateRange: dateRange(from: story.metadata),
            readingMode: mode
        )

        return RenderDocument(
            title: story.title,
            subtitle: story.subtitle,
            pages: pages.filter { !$0.blocks.isEmpty || $0.pageType == .divider },
            cards: allCards,
            theme: theme,
            metadata: metadata
        )
    }

    // MARK: - Cover Page

    private static func makeCoverPage(story: Story, number: inout Int) -> RenderPage {
        number += 1
        return RenderPage(
            id: "cover",
            pageNumber: number,
            pageType: .cover,
            blocks: [
                .spacer(.init(size: .large)),
                .title(.init(rawText: story.title, level: 1)),
                .subtitle(.init(rawText: story.subtitle)),
                .spacer(.init(size: .medium)),
                .statistic(.init(
                    label: "总消息数", value: "\(story.metadata.totalMessages)",
                    unit: "条", rawText: "\(story.metadata.totalMessages)条消息"
                )),
                .statistic(.init(
                    label: "跨越天数", value: "\(story.metadata.totalDays)",
                    unit: "天", rawText: "\(story.metadata.totalDays)天的对话"
                )),
                .spacer(.init(size: .large)),
                .paragraph(.init(rawText: "一本属于我们的聊天回忆录。")),
                .emotionTag(.init(emotion: "nostalgic", label: "回忆")),
            ],
            estimatedReadingTime: 15
        )
    }

    // MARK: - Chapter Rendering

    private static func renderChapter(_ chapter: Chapter, story: Story) -> [RenderBlock] {
        var blocks: [RenderBlock] = []

        // Chapter header
        blocks.append(.chapterHeader(.init(
            number: nil, title: chapter.title,
            emotion: chapter.emotion.rawValue
        )))

        // Emotion tag
        let emotionLabels: [String: String] = [
            "nostalgic": "怀旧", "joyful": "喜悦", "warm": "温暖",
            "excited": "兴奋", "bittersweet": "酸甜", "calm": "平静",
            "reflective": "沉思", "proud": "自豪", "neutral": "",
        ]
        if let label = emotionLabels[chapter.emotion.rawValue], !label.isEmpty {
            blocks.append(.emotionTag(.init(emotion: chapter.emotion.rawValue, label: label)))
        }

        // Summary paragraph
        blocks.append(.paragraph(.init(rawText: chapter.summary)))

        // Narrative template
        if let narrative = chapter.narrative {
            blocks.append(.quote(.init(
                rawText: narrative.fill(),
                attribution: nil
            )))
        }

        // Statistics (if any)
        if chapter.chapterType == .milestone || chapter.chapterType == .growth {
            blocks.append(.statistic(.init(
                label: "本章",
                value: "\(story.metadata.totalMessages)",
                unit: "条消息",
                rawText: ""
            )))
        }

        if chapter.chapterType == .silence, let daysStr = chapter.narrative?.variables["days"] {
            blocks.append(.statistic(.init(
                label: "沉默天数", value: daysStr,
                unit: "天", rawText: ""
            )))
        }

        if chapter.chapterType == .anniversary, let yearsStr = chapter.narrative?.variables["years"] {
            blocks.append(.statistic(.init(
                label: "相识", value: yearsStr,
                unit: "年", rawText: ""
            )))
        }

        // Milestone blocks
        if chapter.chapterType == .milestone {
            blocks.append(.milestone(.init(
                title: chapter.title, date: nil,
                rawText: chapter.summary
            )))
        }

        blocks.append(.spacer(.init(size: .small)))

        return blocks
    }

    // MARK: - Closing Page

    private static func makeClosingPage(story: Story, number: inout Int) -> RenderPage {
        number += 1
        let total = story.metadata.totalMessages

        let closingText: String
        if total > 10000 {
            closingText = "这不是终点。只是下一卷故事开始之前，短暂的停顿。"
        } else if total > 0 {
            closingText = "故事没有结束。下一条消息，会开启新的章节。"
        } else {
            closingText = "每一段关系，都值得被记住。"
        }

        return RenderPage(
            id: "closing",
            pageNumber: number,
            pageType: .closing,
            blocks: [
                .spacer(.init(size: .large)),
                .divider(.init(style: .chapter)),
                .spacer(.init(size: .medium)),
                .paragraph(.init(rawText: closingText)),
                .spacer(.init(size: .medium)),
                .paragraph(.init(rawText: "— ChatMemoir")),
                .spacer(.init(size: .large)),
            ],
            estimatedReadingTime: 10
        )
    }

    // MARK: - Divider

    private static func makeDividerPage(number: inout Int) -> RenderPage {
        number += 1
        return RenderPage(
            id: "divider_\(number)",
            pageNumber: number,
            pageType: .divider,
            blocks: [.divider(.init(style: .decorated))],
            estimatedReadingTime: 0
        )
    }

    // MARK: - Card Extraction

    public static func extractCards(from chapter: Chapter, story: Story) -> [StoryCard] {
        var cards: [StoryCard] = []

        switch chapter.chapterType {
        case .opening:
            cards.append(StoryCard(
                title: "故事从这里开始",
                subtitle: chapter.summary,
                emotion: "nostalgic",
                theme: "warm",
                associatedEventID: chapter.eventIDs.first
            ))

        case .anniversary:
            let years = chapter.narrative?.variables["years"] ?? "?"
            cards.append(StoryCard(
                title: "\(years)年",
                subtitle: chapter.summary,
                highlight: "时间过得真快",
                statisticValue: years,
                statisticLabel: "年",
                emotion: "joyful",
                theme: "warm"
            ))

        case .peak:
            cards.append(StoryCard(
                title: "最热烈的时光",
                subtitle: chapter.summary,
                emotion: "excited",
                theme: "warm"
            ))

        case .growth, .other where chapter.chapterType == .growth && chapter.title.contains("习惯"):
            let days = chapter.narrative?.variables["days"] ?? "?"
            cards.append(StoryCard(
                title: "连续\(days)天",
                subtitle: "后来，再也没有断过。",
                statisticValue: days,
                statisticLabel: "天",
                emotion: "warm",
                theme: "warm"
            ))

        case .silence:
            let days = chapter.narrative?.variables["days"] ?? "?"
            cards.append(StoryCard(
                title: "\(days)天的空白",
                subtitle: "不是遗忘，是另一种惦记。",
                emotion: "bittersweet",
                theme: "midnight"
            ))

        case .closing:
            cards.append(StoryCard(
                title: "未完待续",
                subtitle: chapter.summary,
                highlight: "故事还在继续",
                statisticValue: "\(story.metadata.totalMessages)",
                statisticLabel: "条消息",
                emotion: "reflective",
                theme: "memoir"
            ))

        default:
            break
        }

        return cards
    }

    // MARK: - Pagination

    private static func chunkBlocks(_ blocks: [RenderBlock]) -> [[RenderBlock]] {
        if blocks.isEmpty { return [] }
        var chunks: [[RenderBlock]] = []
        var current: [RenderBlock] = []
        let limit = forceNewPagePerChapter ? 1 : blocksPerPage

        for block in blocks {
            if case .chapterHeader = block, !current.isEmpty {
                chunks.append(current)
                current = []
            }
            current.append(block)
            if current.count >= limit {
                chunks.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }

    // MARK: - Helpers

    private static func dateRange(from meta: StoryMetadata) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy"
        if let start = meta.dateRangeStart, let end = meta.dateRangeEnd {
            let s = fmt.string(from: start)
            let e = fmt.string(from: end)
            return s == e ? s : "\(s) - \(e)"
        }
        return ""
    }
}

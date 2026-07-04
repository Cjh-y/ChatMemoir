import Foundation
import XCTest
@testable import PresentationEngine
@testable import StoryEngine
@testable import TimelineEngine
import ChatImportKit

final class PresentationEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeStory(messages: Int = 2000, days: Int = 400, name: String = "Alice") -> Story {
        let owner = Participant(id: "me", displayName: "我")
        let friend = Participant(id: "f", displayName: name)
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2023, month: 1, day: 15))!

        var msgs: [Message] = []
        for i in 0..<messages {
            let dayOffset = (i * days) / max(messages, 1)
            let sender = i % 3 == 0 ? owner : friend
            let ts = cal.date(byAdding: .day, value: dayOffset, to: base) ?? base
            msgs.append(Message(id: "m\(i)", sender: sender, timestamp: ts, type: .text, content: "msg"))
        }
        let chat = Chat(id: "c1", displayName: name, isGroupChat: false,
                         participants: [owner, friend], messages: msgs,
                         lastMessageAt: msgs.last?.timestamp)
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
        let timeline = TimelineEngine.generate(from: db)
        return StoryEngine.generate(from: timeline)
    }

    // MARK: - RenderDocument

    func testStoryToRenderDocument() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)

        XCTAssertFalse(doc.title.isEmpty)
        XCTAssertGreaterThan(doc.pages.count, 2)
        XCTAssertTrue(doc.pages.contains { $0.pageType == .cover })
        XCTAssertTrue(doc.pages.contains { $0.pageType == .closing })
        XCTAssertFalse(doc.cards.isEmpty)
    }

    func testCoverPageHasTitle() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)

        let cover = doc.pages.first { $0.pageType == .cover }
        XCTAssertNotNil(cover)
        let hasTitle = cover?.blocks.contains { block in
            if case .title = block { return true }
            return false
        }
        XCTAssertTrue(hasTitle ?? false)
    }

    func testEmptyStoryRenders() {
        let owner = Participant(id: "me", displayName: "我")
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [])
        let timeline = TimelineEngine.generate(from: db)
        let story = StoryEngine.generate(from: timeline)
        let doc = PresentationEngine.render(story: story)

        XCTAssertGreaterThan(doc.pages.count, 0)
        XCTAssertTrue(doc.pages.contains { $0.pageType == .cover })
    }

    // MARK: - Pagination

    func testPaginationSplitsLargeContent() {
        PresentationEngine.blocksPerPage = 3
        PresentationEngine.forceNewPagePerChapter = false

        let story = makeStory(messages: 3000, days: 600)
        let doc = PresentationEngine.render(story: story)

        // Should have more pages due to low blocksPerPage
        XCTAssertGreaterThan(doc.pages.count, 3)

        // Reset
        PresentationEngine.blocksPerPage = 8
    }

    func testAllPagesHaveValidNumbers() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)

        for page in doc.pages {
            XCTAssertGreaterThan(page.pageNumber, 0)
        }
    }

    // MARK: - StoryCard

    func testCardExtraction() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)

        XCTAssertGreaterThan(doc.cards.count, 0)
        for card in doc.cards {
            XCTAssertFalse(card.title.isEmpty)
            XCTAssertFalse(card.subtitle.isEmpty)
            XCTAssertFalse(card.emotion.isEmpty)
        }
    }

    // MARK: - JSON Export

    func testJSONExport() throws {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)
        let json = try ExportEngine.exportJSON(doc)

        XCTAssertTrue(json.contains("\"title\""))
        XCTAssertTrue(json.contains("\"pages\""))
        XCTAssertTrue(json.contains("\"cards\""))

        // Round-trip
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RenderDocument.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.pages.count, doc.pages.count)
    }

    // MARK: - Markdown Export

    func testMarkdownExport() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)
        let md = ExportEngine.exportMarkdown(doc)

        XCTAssertTrue(md.contains("# "))
        XCTAssertTrue(md.contains("*"))
        XCTAssertTrue(md.contains("ChatMemoir"))
    }

    // MARK: - HTML Export

    func testHTMLExport() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)
        let html = ExportEngine.exportHTML(doc)

        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<title>"))
        XCTAssertTrue(html.contains("</html>"))
        XCTAssertTrue(html.contains("font-family"))
    }

    // MARK: - Theme

    func testThemeApplication() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story, theme: .warm)

        XCTAssertEqual(doc.theme.name, "warm")
        XCTAssertEqual(doc.theme.typography.titleFont, "Avenir")
    }

    func testAllThemesRender() {
        let story = makeStory()
        for theme in [RenderTheme.memoir, RenderTheme.warm, RenderTheme.minimal, RenderTheme.midnight] {
            let doc = PresentationEngine.render(story: story, theme: theme)
            XCTAssertEqual(doc.theme.name, theme.name)
        }
    }

    // MARK: - Metadata

    func testRenderMetadata() {
        let story = makeStory(messages: 500, days: 100, name: "Charlie")
        let doc = PresentationEngine.render(story: story)

        XCTAssertEqual(doc.metadata.totalMessages, 500)
        XCTAssertEqual(doc.metadata.topContact, "Charlie")
        XCTAssertEqual(doc.metadata.ownerName, "我")
    }

    // MARK: - Closing Page

    func testClosingPageExists() {
        let story = makeStory()
        let doc = PresentationEngine.render(story: story)

        let closing = doc.pages.filter { $0.pageType == .closing }
        XCTAssertEqual(closing.count, 1)
    }
}

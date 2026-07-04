import Foundation
import XCTest
@testable import StoryEngine
@testable import TimelineEngine
import ChatImportKit

final class StoryEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeTimeline(messages: Int, days: Int, contactName: String = "Alice") -> Timeline {
        let owner = Participant(id: "me", displayName: "我")
        let friend = Participant(id: "f", displayName: contactName)
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2023, month: 1, day: 15))!

        var msgs: [Message] = []
        for i in 0..<messages {
            let dayOffset = (i * days) / max(messages, 1)
            let sender = i % 3 == 0 ? owner : friend
            let ts = cal.date(byAdding: .day, value: dayOffset, to: base) ?? base
            let type: MessageType = i % 10 == 0 ? .image : .text
            msgs.append(Message(id: "m\(i)", sender: sender, timestamp: ts, type: type, content: "msg \(i)"))
        }

        let chat = Chat(id: "c1", displayName: contactName, isGroupChat: false,
                         participants: [owner, friend], messages: msgs,
                         lastMessageAt: msgs.last?.timestamp,
                         lastMessagePreview: msgs.last?.content)
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
        return TimelineEngine.generate(from: db)
    }

    // MARK: - Basic Tests

    func testEmptyTimeline() {
        let owner = Participant(id: "me", displayName: "我")
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [])
        let timeline = TimelineEngine.generate(from: db)
        let story = StoryEngine.generate(from: timeline)

        XCTAssertFalse(story.title.isEmpty)
        XCTAssertTrue(story.chapters.isEmpty)
        XCTAssertEqual(story.metadata.totalMessages, 0)
    }

    func testStoryHasAllChapterTypes() {
        let timeline = makeTimeline(messages: 500, days: 400, contactName: "Alice")
        let story = StoryEngine.generate(from: timeline)

        // Should have at minimum: opening, closing
        XCTAssertGreaterThanOrEqual(story.chapters.count, 2)
        XCTAssertTrue(story.chapters.contains { $0.chapterType == .opening })
        XCTAssertTrue(story.chapters.contains { $0.chapterType == .closing })
    }

    func testChaptersSortedByImportance() {
        let timeline = makeTimeline(messages: 5000, days: 800)
        let story = StoryEngine.generate(from: timeline)

        // Opening and closing should be top importance
        let opening = story.chapters.first { $0.chapterType == .opening }
        let closing = story.chapters.first { $0.chapterType == .closing }
        XCTAssertEqual(opening?.importance, 10)
        XCTAssertEqual(closing?.importance, 10)
    }

    // MARK: - Narrative Templates

    func testNarrativeTemplatesFillCorrectly() {
        let narrative = NarrativeTemplate(
            template: "从{date}开始，{owner}和{contact}的故事。",
            variables: ["date": "2023年1月15日", "owner": "我", "contact": "Alice"]
        )
        let filled = narrative.fill()
        XCTAssertEqual(filled, "从2023年1月15日开始，我和Alice的故事。")
    }

    func testAllChaptersHaveNarrativeOrSummary() {
        let timeline = makeTimeline(messages: 3000, days: 600)
        let story = StoryEngine.generate(from: timeline)

        for chapter in story.chapters {
            XCTAssertFalse(chapter.summary.isEmpty, "Chapter '\(chapter.title)' has empty summary")
        }
    }

    // MARK: - Emotion Mapping

    func testOpeningChapterIsNostalgic() {
        let timeline = makeTimeline(messages: 100, days: 10)
        let story = StoryEngine.generate(from: timeline)
        let opening = story.chapters.first { $0.chapterType == .opening }
        XCTAssertEqual(opening?.emotion, .nostalgic)
    }

    func testAnniversaryChapterIsJoyful() {
        let timeline = makeTimeline(messages: 5000, days: 800)  // > 1 year
        let story = StoryEngine.generate(from: timeline)
        let anniversary = story.chapters.filter { $0.chapterType == .anniversary }
        for chapter in anniversary {
            XCTAssertEqual(chapter.emotion, .joyful)
        }
    }

    // MARK: - Title Generation

    func testTitleIncludesContactName() {
        let timeline = makeTimeline(messages: 500, days: 400, contactName: "Alice")
        let story = StoryEngine.generate(from: timeline)
        XCTAssertTrue(story.title.contains("Alice"))
    }

    func testSubtitleForLongRelationship() {
        let timeline = makeTimeline(messages: 5000, days: 800, contactName: "Bob")
        let story = StoryEngine.generate(from: timeline)
        XCTAssertTrue(story.subtitle.contains("年"))
        XCTAssertTrue(story.subtitle.contains("陪伴"))
    }

    // MARK: - JSON Export

    func testStoryJSONExport() throws {
        let timeline = makeTimeline(messages: 1000, days: 300)
        let story = StoryEngine.generate(from: timeline)

        let json = try story.toJSON()
        XCTAssertTrue(json.contains("\"schemaVersion\""))
        XCTAssertTrue(json.contains("\"title\""))
        XCTAssertTrue(json.contains("\"chapters\""))

        // Verify round-trip
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Story.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.chapters.count, story.chapters.count)
    }

    // MARK: - Metadata

    func testStoryMetadata() {
        let timeline = makeTimeline(messages: 500, days: 100, contactName: "Charlie")
        let story = StoryEngine.generate(from: timeline)

        XCTAssertEqual(story.metadata.totalMessages, 500)
        XCTAssertEqual(story.metadata.totalChats, 1)
        XCTAssertEqual(story.metadata.topContactName, "Charlie")
        XCTAssertEqual(story.metadata.ownerName, "我")
    }

    // MARK: - Chapter Importance Range

    func testImportanceInValidRange() {
        let timeline = makeTimeline(messages: 2000, days: 500)
        let story = StoryEngine.generate(from: timeline)

        for chapter in story.chapters {
            XCTAssertGreaterThanOrEqual(chapter.importance, 1)
            XCTAssertLessThanOrEqual(chapter.importance, 10)
        }
    }
}

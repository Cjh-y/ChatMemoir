import Foundation
import XCTest
@testable import TimelineEngine
import ChatImportKit

final class TimelineEngineTests: XCTestCase {

    // MARK: - Empty Chat

    func testEmptyChatDatabase() throws {
        let db = ChatDatabase(
            platform: .wechat,
            owner: Participant(id: "me", displayName: "Me"),
            chats: []
        )
        let timeline = TimelineEngine.generate(from: db)
        XCTAssertEqual(timeline.statistics.totalMessages, 0)
        XCTAssertEqual(timeline.statistics.totalChats, 0)
        XCTAssertEqual(timeline.events.isEmpty, true)
        XCTAssertEqual(timeline.topContacts.isEmpty, true)

        let json = try timeline.toJSON()
        XCTAssertTrue(json.contains("\"totalMessages\" : 0"))
    }

    // MARK: - Single Contact

    func testSingleContact() throws {
        let owner = Participant(id: "me", displayName: "Me")
        let friend = Participant(id: "friend", displayName: "Alice")

        var messages: [Message] = []
        let start = Date(timeIntervalSince1970: 1700000000) // 2023-11-14
        for i in 0..<100 {
            let sender = i % 2 == 0 ? friend : owner
            messages.append(Message(
                id: "m\(i)",
                sender: sender,
                timestamp: start.addingTimeInterval(TimeInterval(i * 3600)),
                type: i % 5 == 0 ? .image : .text,
                content: "Message \(i)"
            ))
        }

        let chat = Chat(id: "chat1", displayName: "Alice", isGroupChat: false,
                         participants: [owner, friend], messages: messages,
                         lastMessageAt: messages.last?.timestamp)
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [chat])

        let timeline = TimelineEngine.generate(from: db)

        XCTAssertEqual(timeline.statistics.totalMessages, 100)
        XCTAssertEqual(timeline.statistics.totalChats, 1)
        XCTAssertEqual(timeline.statistics.privateChats, 1)
        XCTAssertEqual(timeline.statistics.groupChats, 0)

        // Should have events: first contact, milestones, etc.
        XCTAssertGreaterThan(timeline.events.count, 0)

        // Should have first contact event
        let firstContact = timeline.events.first { $0.kind == .firstContact }
        XCTAssertNotNil(firstContact)
        XCTAssertEqual(firstContact?.date, start)

        // Should have top contact
        XCTAssertEqual(timeline.topContacts.count, 1)
        XCTAssertEqual(timeline.topContacts[0].contact.displayName, "Alice")

        // Sections should exist
        XCTAssertGreaterThan(timeline.sections.count, 0)

        // JSON export
        let json = try timeline.toJSON()
        XCTAssertTrue(json.contains("Alice"))
    }

    // MARK: - Multiple Contacts

    func testMultipleContacts() throws {
        let owner = Participant(id: "me", displayName: "Me")
        let alice = Participant(id: "a", displayName: "Alice")
        let bob = Participant(id: "b", displayName: "Bob")

        var chats = [Chat]()
        for (friend, count) in [(alice, 200), (bob, 50)] {
            var msgs: [Message] = []
            let start = Date(timeIntervalSince1970: 1700000000)
            for i in 0..<count {
                msgs.append(Message(
                    id: "\(friend.id)_m\(i)",
                    sender: i % 3 == 0 ? owner : friend,
                    timestamp: start.addingTimeInterval(TimeInterval(i * 1800)),
                    type: .text,
                    content: "Hi"
                ))
            }
            chats.append(Chat(id: friend.id, displayName: friend.displayName,
                               isGroupChat: false, participants: [owner, friend],
                               messages: msgs))
        }

        let db = ChatDatabase(platform: .wechat, owner: owner, chats: chats)
        let timeline = TimelineEngine.generate(from: db)

        XCTAssertEqual(timeline.statistics.totalMessages, 250)
        XCTAssertEqual(timeline.statistics.totalChats, 2)
        XCTAssertEqual(timeline.topContacts.count, 2)
        XCTAssertEqual(timeline.topContacts[0].contact.displayName, "Alice")
        XCTAssertEqual(timeline.topContacts[0].rank, 1)
        XCTAssertGreaterThan(timeline.topContacts[0].percentageOfTotal, timeline.topContacts[1].percentageOfTotal)
    }

    // MARK: - Time Distribution

    func testTimeDistribution() throws {
        let owner = Participant(id: "me", displayName: "Me")
        let friend = Participant(id: "f", displayName: "F")

        var messages: [Message] = []
        let cal = Calendar.current
        // Create messages at specific hours
        for hour in 0..<24 {
            var comps = cal.dateComponents([.year, .month, .day], from: Date())
            comps.hour = hour
            if let date = cal.date(from: comps) {
                messages.append(Message(id: "m\(hour)", sender: friend, timestamp: date, type: .text, content: "h\(hour)"))
            }
        }

        let chat = Chat(id: "c", displayName: "F", isGroupChat: false,
                         participants: [owner, friend], messages: messages)
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
        let timeline = TimelineEngine.generate(from: db)

        // Hourly distribution should have 24 entries
        XCTAssertEqual(timeline.hourlyDistribution.count, 24)

        // Weekdays should work
        XCTAssertEqual(timeline.weekdayDistribution.count, 7)

        // Heatmap should be 7 rows × 24 columns
        XCTAssertEqual(timeline.activityHeatmap.rows.count, 7)
        for row in timeline.activityHeatmap.rows {
            XCTAssertEqual(row.hours.count, 24)
        }
    }

    // MARK: - Streaks

    func testStreaks() throws {
        let owner = Participant(id: "me", displayName: "Me")
        let friend = Participant(id: "f", displayName: "F")
        let cal = Calendar.current

        // Create 5 consecutive days of messages
        var messages: [Message] = []
        let today = cal.startOfDay(for: Date())
        for dayOffset in 0..<5 {
            if let date = cal.date(byAdding: .day, value: -dayOffset, to: today) {
                messages.append(Message(id: "m\(dayOffset)", sender: friend, timestamp: date, type: .text, content: "day\(dayOffset)"))
            }
        }

        let chat = Chat(id: "c", displayName: "F", isGroupChat: false,
                         participants: [owner, friend], messages: messages)
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
        let timeline = TimelineEngine.generate(from: db)

        XCTAssertEqual(timeline.streaks.longestStreak, 5)
        XCTAssertEqual(timeline.streaks.currentStreak, 5)
    }

    // MARK: - Message Type Breakdown

    func testMessageTypeBreakdown() throws {
        let owner = Participant(id: "me", displayName: "Me")
        let friend = Participant(id: "f", displayName: "F")

        let types: [MessageType] = [.text, .text, .image, .voice, .sticker, .system]
        let messages = types.enumerated().map {
            Message(id: "m\($0.offset)", sender: friend,
                    timestamp: Date(), type: $0.element, content: "m")
        }

        let chat = Chat(id: "c", displayName: "F", isGroupChat: false,
                         participants: [owner, friend], messages: messages)
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
        let timeline = TimelineEngine.generate(from: db)

        let b = timeline.messageTypeBreakdown
        XCTAssertEqual(b.text, 2)
        XCTAssertEqual(b.image, 1)
        XCTAssertEqual(b.voice, 1)
        XCTAssertEqual(b.sticker, 1)
        XCTAssertEqual(b.system, 1)
    }

    // MARK: - JSON Round-trip

    func testJSONExport() throws {
        let owner = Participant(id: "me", displayName: "Me")
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [])
        let timeline = TimelineEngine.generate(from: db)

        let json = try timeline.toJSON()
        XCTAssertTrue(json.contains("\"schemaVersion\""))

        // Verify it's valid JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Timeline.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.statistics.totalMessages, 0)
    }

    // MARK: - Group Stats

    func testGroupStats() throws {
        let owner = Participant(id: "me", displayName: "Me")
        let u1 = Participant(id: "u1", displayName: "A")
        let u2 = Participant(id: "u2", displayName: "B")
        let u3 = Participant(id: "u3", displayName: "C")

        let groupChat = Chat(id: "gc", displayName: "Friends", isGroupChat: true,
                              participants: [owner, u1, u2, u3], messages: [Message(id: "gm1", sender: owner, timestamp: Date(), type: .text, content: "hi")])
        let db = ChatDatabase(platform: .wechat, owner: owner, chats: [groupChat])
        let timeline = TimelineEngine.generate(from: db)

        XCTAssertEqual(timeline.groupStats.totalGroups, 1)
        XCTAssertEqual(timeline.groupStats.largestGroupSize, 4)
    }
}

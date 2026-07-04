import Foundation
import ChatImportKit
import TimelineEngine

// ============================================================
// ChatMemoir Demo — Timeline Engine
// ============================================================
// Generates a simulated ChatDatabase and runs the Timeline Engine.

// 1. Build simulated data
let owner = Participant(id: "wxid_owner", displayName: "我")
let alice = Participant(id: "wxid_alice", displayName: "Alice")
let bob = Participant(id: "wxid_bob", displayName: "Bob")
let group = Participant(id: "wxid_group", displayName: "健身群")

let cal = Calendar.current
let baseDate = cal.date(from: DateComponents(year: 2023, month: 1, day: 15))!

// Generate 500 days of chat with Alice
var aliceMessages: [Message] = []
var msgCount = 0
for day in 0..<500 {
    // Some days no chat (weekends less active)
    let messagesToday: Int
    let wd = cal.component(.weekday, from: cal.date(byAdding: .day, value: day, to: baseDate)!)
    switch wd {
    case 1, 7: messagesToday = Int.random(in: 0...3)
    default: messagesToday = Int.random(in: 2...15)
    }

    for _ in 0..<messagesToday {
        msgCount += 1
        let sender = msgCount.isMultiple(of: 3) ? owner : alice
        let hour = Int.random(in: 8...23)
        var comps = cal.dateComponents([.year, .month, .day], from: baseDate)
        comps.day! += day
        comps.hour = hour
        comps.minute = Int.random(in: 0...59)
        let ts = cal.date(from: comps) ?? baseDate

        let type: MessageType
        let content: String?
        switch Int.random(in: 1...10) {
        case 1: (type, content) = (.image, nil)
        case 2: (type, content) = (.sticker, nil)
        case 3: (type, content) = (.voice, nil)
        case 4: (type, content) = (.video, nil)
        default: (type, content) = (.text, "消息内容 #\(msgCount)")
        }

        aliceMessages.append(Message(
            id: "alice_m\(msgCount)",
            sender: sender,
            timestamp: ts,
            type: type,
            content: content
        ))
    }
}

let aliceChat = Chat(
    id: "alice",
    displayName: "Alice",
    isGroupChat: false,
    participants: [owner, alice],
    messages: aliceMessages,
    lastMessageAt: aliceMessages.last?.timestamp,
    lastMessagePreview: aliceMessages.last?.content
)

// Generate 100 days of chat with Bob (less active)
var bobMessages: [Message] = []
for day in 0..<100 {
    let messagesToday = Int.random(in: 0...5)
    for m in 0..<messagesToday {
        let sender = (day + m).isMultiple(of: 2) ? owner : bob
        let ts = cal.date(byAdding: .day, value: day + 200, to: baseDate)?
            .addingTimeInterval(TimeInterval(m * 1800)) ?? baseDate
        bobMessages.append(Message(
            id: "bob_m\(day)_\(m)",
            sender: sender,
            timestamp: ts,
            type: .text,
            content: "Bob消息"
        ))
    }
}

let bobChat = Chat(
    id: "bob",
    displayName: "Bob",
    isGroupChat: false,
    participants: [owner, bob],
    messages: bobMessages
)

// Group chat
var groupMessages: [Message] = []
for i in 0..<30 {
    let senders = [owner, alice, bob]
    groupMessages.append(Message(
        id: "group_m\(i)",
        sender: senders[i % 3],
        timestamp: baseDate.addingTimeInterval(TimeInterval(i * 86400 + 400 * 86400)),
        type: .text,
        content: "群聊消息 \(i)"
    ))
}

let groupChat = Chat(
    id: "group",
    displayName: "健身群",
    isGroupChat: true,
    participants: [owner, alice, bob],
    messages: groupMessages
)

let db = ChatDatabase(
    platform: .unknown,
    owner: owner,
    chats: [aliceChat, bobChat, groupChat]
)

// 2. Generate Timeline
print("=== Generating Timeline ===")
let timeline = TimelineEngine.generate(from: db)

// 3. Print statistics
print("""

📊 STATISTICS
═══════════════════════════════
""")
let s = timeline.statistics
print("Total chats: \(s.totalChats) (private: \(s.privateChats), group: \(s.groupChats))")
print("Total messages: \(s.totalMessages)")
print("Text messages: \(s.totalTextMessages)")
print("Media messages: \(s.totalMediaMessages)")
if let first = s.firstMessageDate {
    print("First message: \(first)")
}
if let last = s.lastMessageDate {
    print("Last message: \(last)")
}
print("Total days: \(s.totalDays)")
print(String(format: "Avg messages/day: %.1f", s.averageMessagesPerDay))

// 4. Print events
print("""

🎯 EVENTS (\(timeline.events.count) events)
═══════════════════════════════
""")
for event in timeline.events.prefix(15) {
    print("[\(event.kind.rawValue)] \(event.title)")
    print("  \(event.description)")
    print("  Date: \(event.date)")
}

// 5. Print top contacts
print("""

👥 TOP CONTACTS
═══════════════════════════════
""")
for contact in timeline.topContacts {
    print("#\(contact.rank) \(contact.contact.displayName): \(contact.messageCount) msgs (\(String(format: "%.1f", contact.percentageOfTotal))%)")
}

// 6. Print time distribution
print("""

🕐 TIME DISTRIBUTION
═══════════════════════════════
""")
if let peak = timeline.hourlyDistribution.max(by: { $0.count < $1.count }) {
    print("Peak hour: \(peak.label) (\(peak.count) messages)")
}

let weekdayPeak = timeline.weekdayDistribution.max(by: { $0.count < $1.count })
print("Busiest day: \(weekdayPeak?.name ?? "n/a")")

// 7. Print streaks
print("""

🔥 STREAKS
═══════════════════════════════
""")
print("Longest streak: \(timeline.streaks.longestStreak) days")
print("Current streak: \(timeline.streaks.currentStreak) days")
print("Longest silence: \(timeline.streaks.longestSilence) days")

// 8. Export JSON
print("""

📄 JSON EXPORT
═══════════════════════════════
""")
var lineCount = 0
if let json = try? timeline.toJSON(pretty: true) {
    let lines = json.split(separator: "\n")
    lineCount = lines.count
    print("Total lines: \(lines.count)")
    print("First 40 lines:")
    for line in lines.prefix(40) {
        print(line)
    }
    print("...")
    print("Last 5 lines:")
    for line in lines.suffix(5) {
        print(line)
    }
}

print("""

✅ Demo complete!
ChatDatabase (\(db.chats.count) chats, \(s.totalMessages) messages)
    → TimelineEngine
    → Timeline (\(timeline.events.count) events)
    → JSON (\(lineCount) lines)
""")

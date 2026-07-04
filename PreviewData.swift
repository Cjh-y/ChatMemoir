import Foundation
import ChatImportKit

/// A sample story ready for preview and demo.
public struct SampleStory: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let description: String
    public let themeColor: String  // hex

    /// Build a ChatDatabase from this sample.
    public func buildChatDatabase() -> ChatDatabase {
        switch id {
        case "alice": return Self.buildAlice()
        case "bob": return Self.buildBob()
        case "family": return Self.buildFamily()
        default: return Self.buildAlice()
        }
    }

    // MARK: - Presets

    public static let alice = SampleStory(
        id: "alice",
        title: "Alice 与我",
        subtitle: "温暖日常",
        description: "两年半的聊天，从第一句'你好'到每天睡前的一句'晚安'。这是一段关于陪伴的故事。",
        themeColor: "#D4A574"
    )

    public static let bob = SampleStory(
        id: "bob",
        title: "Bob 与我",
        subtitle: "深夜对话",
        description: "三年间，你们在深夜聊了无数次。从工作到人生，从困惑到释然。",
        themeColor: "#7B9EA8"
    )

    public static let family = SampleStory(
        id: "family",
        title: "我们的家",
        subtitle: "群聊记忆",
        description: "爸爸妈妈、弟弟妹妹——四口之家的群聊，记录了每一次节日、每一次关心。",
        themeColor: "#C49A6C"
    )

    // MARK: - Data Builders

    private static func buildAlice() -> ChatDatabase {
        let owner = Participant(id: "me", displayName: "我")
        let alice = Participant(id: "alice", displayName: "Alice")
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2023, month: 3, day: 15))!

        var messages: [Message] = []
        var msgCount = 0

        for day in 0..<900 {
            let date = cal.date(byAdding: .day, value: day, to: base) ?? base
            let wd = cal.component(.weekday, from: date)
            let count: Int
            switch wd {
            case 1, 7: count = Int.random(in: 1...6)
            default: count = Int.random(in: 3...20)
            }

            for _ in 0..<count {
                msgCount += 1
                let sender = msgCount.isMultiple(of: 3) ? owner : alice
                let hour = Int.random(in: 7...23)
                var comps = cal.dateComponents([.year, .month, .day], from: date)
                comps.hour = hour; comps.minute = Int.random(in: 0...59)
                let ts = cal.date(from: comps) ?? date

                let type: MessageType
                let content: String?
                switch Int.random(in: 1...12) {
                case 1: (type, content) = (.image, nil)
                case 2: (type, content) = (.sticker, nil)
                case 3: (type, content) = (.voice, nil)
                default: (type, content) = (.text, Self.aliceMessages.randomElement()!)
                }

                messages.append(Message(id: "a\(msgCount)", sender: sender, timestamp: ts, type: type, content: content))
            }
        }

        let chat = Chat(id: "alice", displayName: "Alice", isGroupChat: false,
                         participants: [owner, alice], messages: messages,
                         lastMessageAt: messages.last?.timestamp)
        return ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
    }

    private static func buildBob() -> ChatDatabase {
        let owner = Participant(id: "me", displayName: "我")
        let bob = Participant(id: "bob", displayName: "Bob")
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2021, month: 6, day: 1))!

        var messages: [Message] = []
        var msgCount = 0
        for day in 0..<1100 {
            let date = cal.date(byAdding: .day, value: day, to: base) ?? base
            // Bob is a night owl — mostly chat at night
            let count = Int.random(in: 0...8)
            for _ in 0..<count {
                msgCount += 1
                let sender = msgCount.isMultiple(of: 4) ? owner : bob
                let hour = Int.random(in: 20...23)
                var comps = cal.dateComponents([.year, .month, .day], from: date)
                comps.hour = hour
                let ts = cal.date(from: comps) ?? date
                let type: MessageType = (msgCount % 12 == 0) ? .image : .text
                messages.append(Message(id: "b\(msgCount)", sender: sender, timestamp: ts, type: type,
                                        content: Self.bobMessages.randomElement()!))
            }
        }
        let chat = Chat(id: "bob", displayName: "Bob", isGroupChat: false,
                         participants: [owner, bob], messages: messages,
                         lastMessageAt: messages.last?.timestamp)
        return ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
    }

    private static func buildFamily() -> ChatDatabase {
        let owner = Participant(id: "me", displayName: "我")
        let mom = Participant(id: "mom", displayName: "妈妈")
        let dad = Participant(id: "dad", displayName: "爸爸")
        let sis = Participant(id: "sis", displayName: "妹妹")
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2020, month: 1, day: 1))!

        var messages: [Message] = []
        var msgCount = 0
        let members = [owner, mom, dad, sis]
        for day in 0..<1800 {
            let date = cal.date(byAdding: .day, value: day, to: base) ?? base
            let count = Int.random(in: 0...5)
            for _ in 0..<count {
                msgCount += 1
                let sender = members[msgCount % 4]
                var comps = cal.dateComponents([.year, .month, .day], from: date)
                comps.hour = Int.random(in: 8...22)
                let ts = cal.date(from: comps) ?? date
                messages.append(Message(id: "f\(msgCount)", sender: sender, timestamp: ts, type: .text,
                                        content: Self.familyMessages.randomElement()!))
            }
        }
        let chat = Chat(id: "family", displayName: "我们的家", isGroupChat: true,
                         participants: members, messages: messages,
                         lastMessageAt: messages.last?.timestamp)
        return ChatDatabase(platform: .wechat, owner: owner, chats: [chat])
    }

    // MARK: - Message Banks

    private static let aliceMessages = [
        "早安☀️", "晚安🌙", "今天吃什么？", "哈哈哈哈", "想你了",
        "下班了吗？", "周末去哪？", "我刚看到一只猫🐱", "好困", "今天好累",
        "你怎么还不睡", "梦到你了", "外面下雨了", "路上小心", "到了",
        "嗯嗯", "好的", "知道啦", "那你早点休息", "明天见",
        "今天心情特别好", "谢谢你", "有你真好", "抱抱", "（语音消息）",
        "发了个表情", "吃饭了没", "我刚到家", "在看电影", "推荐你看那部",
        "周末约吗", "好久没见了", "想你做的饭了", "今天加班", "好无聊",
    ]

    private static let bobMessages = [
        "你睡了吗", "我也在想这个", "人生啊", "推荐你一本书", "最近怎么样",
        "工作还好吗", "有时候觉得", "其实我也不知道", "你说得对",
        "深夜了", "我也没睡", "刚喝完酒", "听首歌吧", "突然想到你",
        "有点emo", "但没事", "都会好起来的", "谢谢你听我说", "晚安兄弟",
        "改天一起喝酒", "有些事想通了", "今天去了个地方", "想起了以前",
        "好久不见", "你变了很多", "我也是", "一起加油吧",
    ]

    private static let familyMessages = [
        "吃饭了吗", "天冷了多穿点", "周末回来吗", "妈做了你爱吃的",
        "爸给你转钱了", "注意身体", "别太累了", "早点休息",
        "妹妹考试过了", "家里都好", "你最近瘦了", "放假回来吗",
        "你爸想你了", "今天买了你爱吃的", "路上注意安全",
        "到了打个电话", "钱够不够", "别熬夜", "新年快乐",
        "中秋节快乐", "生日快乐🎂", "我们都好", "你在外面照顾好自己",
    ]
}

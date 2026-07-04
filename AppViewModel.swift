import Foundation
import SwiftUI
import Observation
import TimelineEngine
import StoryEngine
import PresentationEngine

/// The single source of truth for the entire app's state.
///
/// Uses Swift Observation (iOS 17+). All state transitions
/// flow through this model. Views only read and react.
@MainActor
@Observable
public final class AppViewModel {
    // MARK: - State

    /// Current app phase.
    public enum Phase: Equatable {
        case launch
        case welcome
        case import_
        case generating(progress: String)
        case reader(document: RenderDocument)

        public static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.launch, .launch), (.welcome, .welcome), (.import_, .import_):
                return true
            case (.generating(let a), .generating(let b)):
                return a == b
            case (.reader, .reader):
                return true  // RenderDocument is not Equatable, compare by identity
            default:
                return false
            }
        }
    }

    public var phase: Phase = .launch

    /// Available sample stories.
    public let sampleStories: [SampleStory] = [
        .alice, .bob, .family,
    ]

    /// Currently selected sample story.
    public var selectedStory: SampleStory?

    // MARK: - The full data pipeline

    /// Cache for generated documents.
    private var documentCache: [String: RenderDocument] = [:]

    // MARK: - Actions

    /// Transition from launch to welcome.
    func showWelcome() {
        withAnimation(.easeInOut(duration: 0.8)) {
            phase = .welcome
        }
    }

    /// Start the import/generation flow.
    func startMaking(from story: SampleStory) {
        selectedStory = story
        phase = .generating(progress: "正在翻阅聊天记录……")
    }

    /// Run the full generation pipeline with animated progress.
    func generate(for story: SampleStory) async {
        let steps = [
            "正在翻阅聊天记录……",
            "正在寻找重要时刻……",
            "正在整理回忆……",
            "正在装订故事……",
            "快完成了……",
        ]

        for step in steps {
            phase = .generating(progress: step)
            try? await Task.sleep(for: .seconds(1.0))
        }

        // Check cache
        if let cached = documentCache[story.id] {
            withAnimation(.easeInOut(duration: 0.6)) {
                phase = .reader(document: cached)
            }
            return
        }

        // Build the database from sample data
        let db = story.buildChatDatabase()

        // Run the pipeline
        let timeline = TimelineEngine.generate(from: db)
        let storyObj = StoryEngine.generate(from: timeline)
        let document = PresentationEngine.render(story: storyObj, theme: .warm)

        // Cache
        documentCache[story.id] = document

        withAnimation(.easeInOut(duration: 0.6)) {
            phase = .reader(document: document)
        }
    }

    /// Go back to welcome.
    func goBack() {
        withAnimation(.easeInOut(duration: 0.5)) {
            phase = .welcome
        }
    }
}

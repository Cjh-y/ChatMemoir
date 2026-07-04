import SwiftUI

/// The root view that orchestrates the entire app flow.
///
/// Phase-driven: launch → welcome → import → generating → reader.
/// No navigation stack — uses transitions for a more cinematic feel.
@MainActor
public struct ContentView: View {
    @State private var viewModel = AppViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            switch viewModel.phase {
            case .launch:
                LaunchView {
                    viewModel.showWelcome()
                }

            case .welcome:
                WelcomeView {
                    viewModel.phase = .import_
                }
                .transition(.opacity)

            case .import_:
                ImportView(
                    sampleStories: viewModel.sampleStories
                ) { story in
                    viewModel.startMaking(from: story)
                    Task {
                        await viewModel.generate(for: story)
                    }
                }
                .transition(.opacity)

            case .generating(let progress):
                GeneratingView(progress: progress)
                    .transition(.opacity)

            case .reader(let document):
                ReaderView(document: document) {
                    viewModel.goBack()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: viewModel.phase)
        .onAppear {
            // Auto-transition from launch after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                viewModel.showWelcome()
            }
        }
    }
}

// MARK: - Launch View

struct LaunchView: View {
    let onComplete: () -> Void
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.9

    var body: some View {
        PageBackground {
            VStack {
                Spacer()
                Image(systemName: "book.closed")
                    .font(.system(size: 64))
                    .foregroundStyle(.primary.opacity(opacity * 0.6))
                    .scaleEffect(scale)
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                opacity = 1
                scale = 1
            }
        }
    }
}

#Preview("Full Flow") {
    ContentView()
}

import SwiftUI
import PresentationEngine

// MARK: - Welcome View

struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        PageBackground {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    Text("ChatMemoir")
                        .font(.system(.largeTitle, design: .serif))
                        .fontWeight(.medium)
                        .tracking(2)
                    Text("一本属于你的聊天回忆录")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                PrimaryButton(title: "开始制作") {
                    onStart()
                }
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Import View

struct ImportView: View {
    let sampleStories: [SampleStory]
    let onSelect: (SampleStory) -> Void
    @State private var selectedIndex: Int?

    var body: some View {
        PageBackground {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                Text("选择一个故事")
                    .font(.system(.title2, design: .serif))
                    .fontWeight(.medium)
                    .padding(.bottom, 32)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(sampleStories.enumerated()), id: \.offset) { index, story in
                            SampleStoryRow(
                                story: story,
                                isSelected: selectedIndex == index
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedIndex = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }

                PrimaryButton(
                    title: selectedIndex != nil ? "开始生成" : "请先选择一个故事",
                    disabled: selectedIndex == nil
                ) {
                    if let idx = selectedIndex {
                        onSelect(sampleStories[idx])
                    }
                }
                .padding(.vertical, 24)

                Spacer()
                    .frame(height: 40)
            }
        }
    }
}

struct SampleStoryRow: View {
    let story: SampleStory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: story.themeColor).opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(story.title.prefix(1)))
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Color(hex: story.themeColor))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(.body, design: .serif))
                    .fontWeight(.medium)
                Text(story.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: story.themeColor))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(hex: story.themeColor) : .clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Generating View

struct GeneratingView: View {
    let progress: String
    @State private var opacity: Double = 0

    var body: some View {
        PageBackground {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "book.pages")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .scaleEffect(opacity)

                Text(progress)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.secondary)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0.3), value: progress)

                Spacer()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    opacity = 1
                }
            }
        }
    }
}

// MARK: - Reader View

struct ReaderView: View {
    let document: RenderDocument
    let onBack: () -> Void

    @State private var currentPageIndex: Int = 0
    @State private var appeared = false

    private var pages: [RenderPage] {
        document.pages.filter { $0.pageType != .divider || $0.blocks.count > 1 }
    }

    var body: some View {
        ZStack {
            PageBackground {
                EmptyView()
            }

            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    Spacer()
                    Text("\(currentPageIndex + 1) / \(pages.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.5))
                        .monospacedDigit()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Page content
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        PageView(page: page, document: document)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPageIndex)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

// MARK: - Page View (single page within the reader)

struct PageView: View {
    let page: RenderPage
    let document: RenderDocument
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                switch page.pageType {
                case .cover:
                    CoverPageContent(document: document)
                case .closing:
                    ClosingPageContent(document: document)
                default:
                    ChapterPageContent(page: page)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

// MARK: - Cover Page Content

struct CoverPageContent: View {
    let document: RenderDocument

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            VStack(spacing: 16) {
                Text(document.title)
                    .font(.system(.largeTitle, design: .serif))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text(document.subtitle)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 40)

            // Statistics on cover
            let stats = document.pages.first(where: { $0.pageType == .cover })?.blocks ?? []
            ForEach(Array(stats.enumerated()), id: \.offset) { _, block in
                if case .statistic(let s) = block {
                    StatisticCardView(value: s.value, label: s.label, unit: s.unit)
                        .padding(.vertical, 6)
                }
            }

            Spacer().frame(height: 40)

            Text("一本属于我们的聊天回忆录")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.secondary.opacity(0.7))

            Spacer().frame(height: 60)
        }
    }
}

// MARK: - Chapter Page Content

struct ChapterPageContent: View {
    let page: RenderPage

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(page.blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: RenderBlock) -> some View {
        switch block {
        case .chapterHeader(let h):
            ChapterHeaderView(title: h.title, emotion: h.emotion)

        case .title(let t):
            Text(t.rewrittenText ?? t.rawText)
                .font(.system(.title2, design: .serif))
                .fontWeight(.medium)

        case .subtitle(let s):
            Text(s.rewrittenText ?? s.rawText)
                .font(.system(.body, design: .serif))
                .foregroundStyle(.secondary)
                .italic()

        case .paragraph(let p):
            Text(p.rewrittenText ?? p.rawText)
                .font(.system(.body, design: .serif))
                .lineSpacing(6)

        case .quote(let q):
            QuoteView(text: q.rewrittenText ?? q.rawText, attribution: q.attribution)

        case .statistic(let s):
            StatisticCardView(value: s.value, label: s.label, unit: s.unit)

        case .storyCard(let c):
            StoryCardView(
                title: c.card.title,
                subtitle: c.card.subtitle,
                highlight: c.card.highlight,
                emotion: c.card.emotion
            )

        case .emotionTag(let e):
            Text(e.label)
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.regularMaterial)
                )

        case .divider:
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 8)

        case .spacer(let s):
            Spacer().frame(height: spacerHeight(s.size))

        case .milestone(let m):
            VStack(alignment: .leading, spacing: 6) {
                Text("🏆 \(m.title)")
                    .font(.system(.title3, design: .serif))
                Text(m.rewrittenText ?? m.rawText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )

        case .imagePlaceholder(let i):
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.05))
                .frame(height: 160)
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary.opacity(0.3))
                        if let caption = i.caption {
                            Text(caption)
                                .font(.caption)
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                    }
                )
        }
    }

    private func spacerHeight(_ size: RenderBlock.SpacerBlock.SpacerSize) -> CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 24
        case .large: return 48
        }
    }
}

// MARK: - Closing Page Content

struct ClosingPageContent: View {
    let document: RenderDocument

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 80)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 60, height: 1)

            Spacer().frame(height: 16)

            Text("故事没有结束")
                .font(.system(.title2, design: .serif))
                .fontWeight(.medium)
                .foregroundStyle(.primary.opacity(0.7))

            Text("下一条消息，会开启新的章节。")
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundStyle(.secondary)

            Spacer().frame(height: 24)

            Text("— ChatMemoir")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.5))
                .tracking(2)

            Spacer().frame(height: 80)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Previews

#Preview("Welcome") {
    WelcomeView(onStart: {})
}

#Preview("Import") {
    ImportView(sampleStories: [.alice, .bob, .family], onSelect: { _ in })
}

#Preview("Generating") {
    GeneratingView(progress: "正在翻阅聊天记录……")
}

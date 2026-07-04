import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action, label: {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(disabled ? 0.3 : 0.85))
                )
        })
        .disabled(disabled)
    }
}

// MARK: - Story Card View

struct StoryCardView: View {
    let title: String
    let subtitle: String
    let highlight: String?
    let emotion: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let h = highlight {
                Text(h)
                    .font(.caption)
                    .foregroundStyle(emotionColor.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            Text(title)
                .font(.system(.title3, design: .serif))
                .fontWeight(.medium)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }

    private var emotionColor: Color {
        switch emotion {
        case "nostalgic": return .brown
        case "joyful": return .orange
        case "warm": return .yellow
        case "excited": return .red
        case "bittersweet": return .purple
        case "reflective": return .blue
        default: return .gray
        }
    }
}

// MARK: - Statistic Card View

struct StatisticCardView: View {
    let value: String
    let label: String
    let unit: String?

    @State private var displayedValue: Double = 0

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(Int(displayedValue))")
                    .font(.system(size: 42, weight: .light, design: .serif))
                    .contentTransition(.numericText())
                if let u = unit {
                    Text(u)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .onAppear {
            if let v = Double(value) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    displayedValue = v
                }
            }
        }
    }
}

// MARK: - Chapter Header

struct ChapterHeaderView: View {
    let title: String
    let emotion: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emotionEmoji)
                .font(.system(size: 32))
            Text(title)
                .font(.system(.title, design: .serif))
                .fontWeight(.medium)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private var emotionEmoji: String {
        switch emotion {
        case "nostalgic": return "🕰️"
        case "joyful": return "🎉"
        case "warm": return "☀️"
        case "excited": return "🔥"
        case "bittersweet": return "🌧️"
        case "calm": return "🌿"
        case "reflective": return "💭"
        case "proud": return "🏆"
        default: return ""
        }
    }
}

// MARK: - Quote View

struct QuoteView: View {
    let text: String
    let attribution: String?

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 3)
                .cornerRadius(1.5)
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundStyle(.primary.opacity(0.8))
                if let attr = attribution {
                    Text("— \(attr)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 16)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}

// MARK: - Page Background

struct PageBackground<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(pageColor)
    }

    private var pageColor: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.11, blue: 0.10)
            : Color(red: 0.98, green: 0.96, blue: 0.93)
    }
}

// MARK: - Cover View

struct CoverView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(.largeTitle, design: .serif))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Text("一本属于我们的聊天回忆录")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.secondary.opacity(0.7))
                .padding(.bottom, 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let text: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(.secondary)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .id(text)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
    }
}

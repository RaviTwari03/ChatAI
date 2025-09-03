import SwiftUI

struct HomeView: View {
    // API selector for the center chip
    @State private var selectedAPI: String = "ChatGPT mini"
    private let apiOptions: [String] = [
        "ChatGPT mini",
        "OpenAI Realtime",
        "Claude",
        "Gemini"
    ]
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            neonBackdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top chips row
                HStack(spacing: 12) {
                    // Left chip
                    CapsuleChip { Image(systemName: "ellipsis.circle") }

                    // Center chip: dropdown to switch APIs, single-line title
                    Menu {
                        ForEach(apiOptions, id: \.self) { option in
                            Button(option) { selectedAPI = option }
                        }
                    } label: {
                        CapsuleChip {
                            HStack(spacing: 6) {
                                Text(selectedAPI)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Image(systemName: "waveform")
                                    .font(.caption2)
                            }
                        }
                    }

                    Spacer()

                    // Right chip
                    CapsuleChip {
                        Text("Try Premium")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)

                // Headline
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create, Explore,\nBe inspired")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 18)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Search...")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.04))
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Feature cards grid (3 equal columns)
                let columns = Array(repeating: GridItem(.flexible(minimum: 90), spacing: 12, alignment: .top), count: 3)
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    FeatureCard(title: "Files", subtitle: "Upload", accent: .blue)
                    FeatureCard(title: "Web Links", subtitle: "Share", accent: .cyan)
                    FeatureCard(title: "Audio", subtitle: "Record", accent: .orange)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Spacer area with centered text
                Spacer()
                VStack(spacing: 6) {
                    Text("Chat Now")
                        .font(.headline)
                        .foregroundColor(.white)
                    Image(systemName: "sparkle")
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 24)

                // Bottom quick actions
                HStack(spacing: 12) {
                    RoundedQuickAction(title: "Create Images")
                    RoundedQuickAction(title: "Open Camera")
                    RoundedQuickAction(title: "Edit Images")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // Composer bar
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Text("Message ChatNow...")
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.12))
                    )

                    HStack(spacing: 18) {
                        CapsuleSmall { Image(systemName: "plus") }
                        CapsuleSmall { Text("Web Search").font(.caption) }
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                        Image(systemName: "viewfinder")
                        Image(systemName: "waveform")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }

    private var neonBackdrop: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.02, green: 0.03, blue: 0.06)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color.green.opacity(0.5), .clear], center: .topLeading, startRadius: 40, endRadius: 420)
                .blur(radius: 20)
                .offset(x: -80, y: -140)
                .blendMode(.plusLighter)
            RadialGradient(colors: [Color.purple.opacity(0.6), .clear], center: .topTrailing, startRadius: 40, endRadius: 520)
                .blur(radius: 26)
                .offset(x: 80, y: -20)
                .blendMode(.plusLighter)
            RadialGradient(colors: [Color.purple.opacity(0.5), .clear], center: .bottomTrailing, startRadius: 60, endRadius: 520)
                .blur(radius: 26)
                .offset(x: 40, y: 170)
                .blendMode(.plusLighter)
        }
    }
}

// MARK: - Components
private struct CapsuleChip<Label: View>: View {
    private let label: () -> Label
    init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }
    var body: some View {
        label()
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule().fill(Color.white.opacity(0.1))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }
}

private struct FeatureCard: View {
    var title: String
    var subtitle: String
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
            Text(subtitle)
                .foregroundColor(.white.opacity(0.75))
                .font(.caption)
            Spacer(minLength: 0)
            HStack { Spacer(); Image(systemName: "arrow.right").foregroundColor(.white) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.02))
                )
        )
    }
}

private struct RoundedQuickAction: View {
    var title: String
    var body: some View {
        Text(title)
            .foregroundColor(.white)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12)))
    }
}

private struct CapsuleSmall<Label: View>: View {
    private let label: () -> Label
    init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }
    var body: some View {
        label()
            .foregroundColor(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Capsule().fill(Color.white.opacity(0.15)))
    }
}

#Preview {
    NavigationStack { HomeView() }
}

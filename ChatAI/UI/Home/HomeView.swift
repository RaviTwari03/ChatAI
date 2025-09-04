//
//  HomeView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI

struct HomeView: View {
    // API selector for the center chip (driven by app registry)
    private let providers: [APIProvider] = APIRegistry.shared.providers
    @State private var selectedProviderId: String = APIRegistry.shared.providers.first?.id ?? ""
    private var selectedDisplayName: String {
        providers.first(where: { $0.id == selectedProviderId })?.displayName ?? ""
    }
    // Draft for bottom composer and navigation trigger
    @State private var homeDraft: String = ""
    @State private var goToChat: Bool = false
    // Left 2/3 slide-over
    @State private var showSidePanel: Bool = false
    // Alerts
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    // Recents
    @State private var recentChats: [RecentChat] = []
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            neonBackdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top chips row
                HStack(spacing: 12) {
                    // Left chip
                    Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showSidePanel = true } }) {
                        CapsuleChip { Image(systemName: "ellipsis.circle") }
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    // Center chip: dropdown to switch APIs, single-line title
                    Menu {
                        ForEach(providers) { provider in
                            Button(provider.displayName) { selectedProviderId = provider.id }
                        }
                    } label: {
                        CapsuleChip {
                            HStack(spacing: 6) {
                                Text(selectedDisplayName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Image(systemName: "waveform")
                                    .font(.caption2)
                            }
                        }
                    }

                    Spacer(minLength: 0)

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

                // Search bar -> navigates to ChatView
                NavigationLink {
                    ChatView()
                } label: {
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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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

                // Composer bar (editable)
                VStack(spacing: 10) {
                    TextField("Message ChatNow...", text: $homeDraft, axis: .vertical)
                        .lineLimit(1...4)
                        .foregroundColor(.white)
                        .submitLabel(.send)
                        .onSubmit {
                            let text = homeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !text.isEmpty { Task { await startChat() } }
                        }
                        .padding(.leading, 14)
                        .padding(.trailing, 44) // room for mic/send button
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.12))
                        )
                        .overlay(alignment: .trailing) {
                            let canSend = !homeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            Button(action: {
                                if canSend { Task { await startChat() } }
                                // else: mic tapped (hook voice input later)
                            }) {
                                Image(systemName: canSend ? "paperplane.fill" : "mic.fill")
                                    .foregroundColor(.white)
                                    .padding(.trailing, 10)
                            }
                            .buttonStyle(.plain)
                        }

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

                    // Hidden navigation when user hits send
                    NavigationLink(isActive: $goToChat) {
                        ChatView(initialText: homeDraft)
                    } label: { EmptyView() }
                    .onChange(of: goToChat) { active in
                        if !active { homeDraft = "" }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }

            // MARK: - 2/3 Left Slide-Over Panel
            if showSidePanel { sideOverlay }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: showSidePanel) { open in
            if open { Task { await loadRecents() } }
        }
    }

    // Slide-over overlay and panel
    private var sideOverlay: some View {
        GeometryReader { proxy in
            let panelWidth = proxy.size.width * 0.66
            ZStack(alignment: .leading) {
                // Dimmed tappable area to close
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showSidePanel = false } }

                // Panel
                VStack(alignment: .leading, spacing: 16) {
                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
                        Text("Search")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                    )

                    // Actions
                    VStack(alignment: .leading, spacing: 16) {
                        menuRow(icon: "square.and.pencil", title: "New chat")
                        menuRow(icon: "photo.on.rectangle", title: "Library")
                        menuRow(icon: "square.grid.3x3.fill", title: "GPTs")
                        Button {
                            Task {
                                let result = await SupabaseService().testConnection()
                                switch result {
                                case .success:
                                    alertTitle = "Supabase Connected"
                                    alertMessage = "Auth health endpoint returned 200."
                                case .failure(let err):
                                    alertTitle = "Supabase Error"
                                    alertMessage = err.localizedDescription
                                }
                                showAlert = true
                            }
                        } label: {
                            menuRow(icon: "checkmark.seal", title: "Check connection")
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().background(Color.white.opacity(0.15))

                    // Recents from Supabase
                    VStack(alignment: .leading, spacing: 12) {
                        if recentChats.isEmpty {
                            Text("No recent chats")
                                .foregroundColor(.white.opacity(0.6))
                        } else {
                            ForEach(recentChats) { rc in
                                NavigationLink(destination: ChatView(initialText: rc.title)) {
                                    HStack {
                                        Text(rc.title)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    showSidePanel = false
                                })
                            }
                        }
                    }
                    .font(.subheadline)

                    Spacer()
                }
                .padding(16)
                .frame(width: panelWidth, height: proxy.size.height)
                .background(Color.black)
                .transition(.move(edge: .leading))
            }
        }
    }

    @ViewBuilder
    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(title)
            Spacer()
        }
        .foregroundColor(.white)
        .font(.subheadline)
    }

    // MARK: - Supabase helpers
    private func loadRecents() async {
        let res = await SupabaseService().fetchRecentChats(limit: 20)
        switch res {
        case .success(let items):
            recentChats = items
        case .failure(let err):
            alertTitle = "Recents Error"
            alertMessage = err.localizedDescription
            showAlert = true
        }
    }

    private func startChat() async {
        // Save recent, then navigate
        let title = String(homeDraft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        let fallback = title.isEmpty ? "New chat" : title
        let chat = RecentChat(title: fallback)
        _ = await SupabaseService().saveRecentChat(chat)
        await MainActor.run {
            goToChat = true
        }
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

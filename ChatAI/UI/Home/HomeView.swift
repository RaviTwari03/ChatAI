//
//  HomeView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI
import AVFoundation
import Speech
import PhotosUI
import UniformTypeIdentifiers
import UIKit
import VisionKit


struct HomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    // API selector for the center chip (driven by app registry)
    private let providers: [APIProvider] = APIRegistry.shared.providers
    @State private var selectedProviderId: String = APIRegistry.shared.activeProvider().id
    private var selectedDisplayName: String {
        providers.first(where: { $0.id == selectedProviderId })?.displayName ?? ""
    }

// Floating account action card matching the screenshot
private struct AccountActionCard: View {
    var email: String
    var onSettings: () -> Void
    var onUpgrade: () -> Void
    var onLogout: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Email row (disabled)
            HStack(spacing: 10) {
                Image(systemName: "person.circle")
                Text(email)
                Spacer()
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(12)

            // Settings prominent pill
            Button(action: onSettings) {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                    Text("Settings")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)

            // Upgrade
            Button(action: onUpgrade) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.circle")
                    Text("Upgrade to go")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)

            Divider().background(Color.white.opacity(0.2))

            // Logout
            Button(role: .destructive, action: onLogout) {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log out")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .tint(.red)
            .foregroundColor(.red)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .onTapGesture { /* absorb taps */ }
    }
}

    private func startNewChatFromMenu() async {
        await MainActor.run {
            homeDraft = ""
            goToChat = true
        }
    }
    // Draft for bottom composer and navigation trigger
    @State private var homeDraft: String = ""
    @State private var goToChat: Bool = false
    // Speech recognizer for voice input
    @StateObject private var speech = SpeechRecognizer()
    // Paywall navigation
    @State private var showPaywall: Bool = false
    // Voice chat navigation
    @State private var showVoiceChat: Bool = false
    // Left 2/3 slide-over
    @State private var showSidePanel: Bool = false
    // Library navigation
    @State private var showLibrary: Bool = false
    // GPTs popup
    @State private var showProvidersSheet: Bool = false
    // Side search
    @State private var sideSearch: String = ""
    // Alerts
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    // Recents
    @State private var recentChats: [RecentChat] = []
    // Attachment flow to ChatView
    @State private var showPhotosPicker: Bool = false
    @State private var pickedItem: PhotosPickerItem? = nil
    @State private var showDocPicker: Bool = false
    @State private var goToChatWithAttachment: Bool = false
    @State private var attachmentData: Data? = nil
    @State private var attachmentMime: String? = nil
    // Quick actions & feature flows
    @State private var showImagePromptSheet: Bool = false
    @State private var imagePromptText: String = ""
    @State private var showLinkSheet: Bool = false
    @State private var linkURLText: String = ""
    @State private var showCamera: Bool = false
    @State private var showWebSearchSheet: Bool = false
    @State private var webSearchText: String = ""
    // Plus menu
    @State private var showPlusMenu: Bool = false
    // Barcode scanner
    @State private var showScanner: Bool = false
    // Keyboard focus for bottom composer
    @FocusState private var isComposerFocused: Bool
    // Delete confirmation state
    @State private var showDeleteConfirm: Bool = false
    @State private var chatToDelete: RecentChat? = nil
    // Account dialog
    @State private var showAccountDialog: Bool = false
    // Settings screen navigation
    @State private var showSettings: Bool = false
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            neonBackdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top chips row
                HStack(spacing: 12) {
                    // Left chip
                    Button(action: { withAnimation(.spring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.22)) { showSidePanel = true } }) {
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

                    // Right chip -> opens Paywall
                    Button(action: { showPaywall = true }) {
                        CapsuleChip {
                            Text("Premium")
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 2) // align tighter with Dynamic Island

                // Headline
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create, Explore,\nBe inspired")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 18)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

                // Removed search bar per request

                // Feature cards grid (3 equal columns)
                let columns = Array(repeating: GridItem(.flexible(minimum: 90), spacing: 12, alignment: .top), count: 3)
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    // Files -> open document picker and route to Chat with attachment
                    Button(action: { showDocPicker = true }) {
                        FeatureCard(title: "Files", subtitle: "Upload", icon: "folder", accent: .blue)
                    }
                    .buttonStyle(.plain)

                    // Web Links -> show URL input sheet, then navigate to Chat with prefilled text
                    Button(action: { showLinkSheet = true }) {
                        FeatureCard(title: "Web", subtitle: "Links", icon: "link", accent: .cyan)
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        VoiceChatView()
                    } label: {
                        FeatureCard(title: "Voice", subtitle: "Assist", icon: "waveform", accent: .orange)
                    }
                    .buttonStyle(.plain)
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

                // Bottom quick actions (gradient cards)
                HStack(spacing: 12) {
                    Button(action: { showImagePromptSheet = true }) {
                        GradientActionButton(title: "Create Images")
                    }
                    .buttonStyle(.plain)
                    Button(action: { showCamera = true }) {
                        GradientActionButton(title: "Open Camera")
                    }
                    .buttonStyle(.plain)
                    Button(action: { showPhotosPicker = true }) {
                        GradientActionButton(title: "Edit Images")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // Composer bar redesigned (single rounded container with actions)
                VStack(spacing: 10) {
                    // Content-hugging container
                    VStack(alignment: .leading, spacing: 10) {
                        // Message field
                        TextField("Message ChatNow...", text: $homeDraft, axis: .vertical)
                            .lineLimit(1...4)
                            .foregroundColor(.white)
                            .submitLabel(.send)
                            .focused($isComposerFocused)
                            .onSubmit {
                                let text = homeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !text.isEmpty {
                                    isComposerFocused = false
                                    Task { await startChat() }
                                }
                            }
                        // Bottom action row (left pills + right icons)
                        HStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Button { showPlusMenu = true } label: {
                                    CapsuleSmall { Image(systemName: "plus") }
                                }
                                .buttonStyle(.plain)
                                Button(action: { showWebSearchSheet = true }) {
                                    CapsuleSmall { Text("Web Search").font(.caption) }
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                            HStack(spacing: 18) {
                                // Scanner
                                Button {
                                    if #available(iOS 16.0, *) {
                                        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                                            showScanner = true
                                        } else {
                                            alertTitle = "Scanner Unavailable"
                                            alertMessage = "Barcode scanner requires iOS 16+ and a supported device."
                                            showAlert = true
                                        }
                                    } else {
                                        alertTitle = "Requires iOS 16+"
                                        alertMessage = "Update iOS to use barcode scanning."
                                        showAlert = true
                                    }
                                } label: { Image(systemName: "viewfinder") }
                                .font(.system(size: 16, weight: .semibold))
                                // Mic or Send toggle
                                Button(action: {
                                    let canSend = !homeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    if canSend {
                                        isComposerFocused = false
                                        Task { await startChat() }
                                    } else {
                                        if speech.isRecording { speech.stop() } else { try? speech.start() }
                                    }
                                }) {
                                    let canSend = !homeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    Image(systemName: canSend ? "paperplane.fill" : (speech.isRecording ? "stop.circle.fill" : "mic.fill"))
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 16, weight: .semibold))
                                // Voice chat
                                Button { showVoiceChat = true } label: { Image(systemName: "waveform") }
                                .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .foregroundColor(.white)
                    // Quick Actions for + button (no camera)
                    .confirmationDialog("Quick actions", isPresented: $showPlusMenu, titleVisibility: .visible) {
                        Button("Create Image Prompt…") { showImagePromptSheet = true }
                        Button("Attach Photo from Library") { showPhotosPicker = true }
                        Button("Attach File") { showDocPicker = true }
                        Button("Start New Chat") { Task { await startNewChatFromMenu() } }
                        Button("Cancel", role: .cancel) {}
                    }
                    // Attachments
                    .photosPicker(isPresented: $showPhotosPicker, selection: $pickedItem, matching: .images)
                    .onChange(of: pickedItem) { item in
                        Task {
                            if let item, let data = try? await item.loadTransferable(type: Data.self) {
                                attachmentData = data
                                attachmentMime = "image/jpeg"
                                goToChatWithAttachment = true
                            }
                        }
                    }
                    .sheet(isPresented: $showDocPicker) {
                        DocumentPickerRepresentable { url in
                            guard let url else { return }
                            do {
                                let data = try Data(contentsOf: url)
                                attachmentData = data
                                if let type = UTType(filenameExtension: url.pathExtension) {
                                    attachmentMime = type.preferredMIMEType ?? "application/octet-stream"
                                } else {
                                    attachmentMime = "application/octet-stream"
                                }
                                goToChatWithAttachment = true
                            } catch { }
                        }
                    }

                    // Hidden navigation when user hits send
                    NavigationLink(isActive: $goToChat) {
                        ChatView(initialText: homeDraft)
                    } label: { EmptyView() }
                    .onChange(of: goToChat) { active in
                        if !active { homeDraft = "" }
                    }

                    // Hidden navigation to Chat with attachment
                    NavigationLink(isActive: $goToChatWithAttachment) {
                        ChatView(initialAttachmentData: attachmentData, initialAttachmentMime: attachmentMime)
                    } label: { EmptyView() }

                    // Hidden navigation to Voice Chat
                    NavigationLink(isActive: $showVoiceChat) {
                        VoiceChatView()
                    } label: { EmptyView() }

                    // Hidden navigation to Paywall
                    NavigationLink(isActive: $showPaywall) {
                        PaywallView()
                    } label: { EmptyView() }

                    // Full-screen barcode scanner
                    .fullScreenCover(isPresented: $showScanner) {
                        if #available(iOS 16.0, *) {
                            BarcodeScannerContainer(
                                onPayload: { payload in
                                    homeDraft = "barcode: \(payload)"
                                    showScanner = false
                                    Task { await startChat() }
                                },
                                onCancel: { showScanner = false }
                            )
                        } else {
                            EmptyView()
                        }
                    }

                    // Hidden navigation to Library; when picking an image, attach to new chat
                    NavigationLink(isActive: $showLibrary) {
                        LibraryView { data, mime in
                            attachmentData = data
                            attachmentMime = mime
                            goToChatWithAttachment = true
                        }
                    } label: { EmptyView() }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                // Sheets for quick actions & links
                .sheet(isPresented: $showImagePromptSheet) {
                    PromptInputSheet(
                        title: "Create Image",
                        placeholder: "Describe the image you want to create",
                        actionTitle: "Create",
                        text: $imagePromptText,
                        onCommit: {
                            let t = imagePromptText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            homeDraft = "image: \(t)"
                            imagePromptText = ""
                            showImagePromptSheet = false
                            Task { await startChat() }
                        },
                        onCancel: { imagePromptText = "" }
                    )
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showLinkSheet) {
                    PromptInputSheet(
                        title: "Open Web Link",
                        placeholder: "Paste a URL (https://…)",
                        actionTitle: "Open",
                        text: $linkURLText,
                        onCommit: {
                            let t = linkURLText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            homeDraft = "Analyze this link: \(t)"
                            linkURLText = ""
                            showLinkSheet = false
                            Task { await startChat() }
                        },
                        onCancel: { linkURLText = "" }
                    )
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showWebSearchSheet) {
                    PromptInputSheet(
                        title: "Web Search",
                        placeholder: "What do you want to search?",
                        actionTitle: "Search",
                        text: $webSearchText,
                        onCommit: {
                            let t = webSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            homeDraft = "Search the web: \(t)"
                            webSearchText = ""
                            showWebSearchSheet = false
                            Task { await startChat() }
                        },
                        onCancel: { webSearchText = "" }
                    )
                    .presentationDetents([.medium])
                }
            }

            // MARK: - 2/3 Left Slide-Over Panel
            if showSidePanel { sideOverlay }
            // Hidden navigation to Settings
            NavigationLink(isActive: $showSettings) {
                SettingsView()
            } label: { EmptyView() }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.30, dampingFraction: 0.86, blendDuration: 0.2), value: showSidePanel)
        // Dismiss keyboard when tapping outside
        .contentShape(Rectangle())
        .onTapGesture { isComposerFocused = false }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("Delete chat?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { Task { await confirmDelete() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the chat from your recents.")
        }
        .onChange(of: showSidePanel) { open in
            if open {
                isComposerFocused = false
                Task { await loadRecents() }
            }
        }
        // Keep UI state in sync with persisted selection
        .onAppear {
            let current = APIRegistry.shared.activeProvider().id
            if selectedProviderId != current {
                selectedProviderId = current
            }
            // Request speech and mic permissions once
            Task { await speech.requestAuthorization() }
        }
        // When user picks a provider from the menu, switch it in the registry (persist + log)
        .onChange(of: selectedProviderId) { newId in
            APIRegistry.shared.setCurrentProvider(id: newId)
        }
        // Dismiss keyboard when app goes inactive or background
        .onChange(of: scenePhase) { phase in
            if phase != .active { isComposerFocused = false }
        }
        // Dismiss keyboard when opening any sheets/pickers
        .onChange(of: showImagePromptSheet) { if $0 { isComposerFocused = false } }
        .onChange(of: showLinkSheet) { if $0 { isComposerFocused = false } }
        .onChange(of: showWebSearchSheet) { if $0 { isComposerFocused = false } }
        .onChange(of: showPhotosPicker) { if $0 { isComposerFocused = false } }
        .onChange(of: showDocPicker) { if $0 { isComposerFocused = false } }
        .onChange(of: showCamera) { if $0 { isComposerFocused = false } }
        // Dismiss keyboard when navigating away
        .onChange(of: goToChat) { if $0 { isComposerFocused = false } }
        .onChange(of: goToChatWithAttachment) { if $0 { isComposerFocused = false } }
        .onChange(of: showVoiceChat) { if $0 { isComposerFocused = false } }
        .onChange(of: showPaywall) { if $0 { isComposerFocused = false } }
        // GPTs popup listing
        .sheet(isPresented: $showProvidersSheet) {
            VStack(spacing: 12) {
                Text("Available GPTs")
                    .font(.headline)
                Text("\(providers.count) providers available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                List(providers, id: \.id) { p in
                    HStack {
                        Text(p.displayName)
                        Spacer()
                        if p.id == selectedProviderId { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProviderId = p.id
                        APIRegistry.shared.setCurrentProvider(id: p.id)
                    }
                }
                Button("Close") { showProvidersSheet = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .presentationDetents([.medium, .large])
        }
        // Live update the draft from speech transcript
        .onChange(of: speech.transcript) { text in
            homeDraft = text
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && speech.isRecording {
                speech.stop()
            }
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
                    .onTapGesture { withAnimation(.spring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.22)) { showSidePanel = false } }

                // Panel with scrollable content and fixed footer
                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // (User header moved to fixed footer)

                            // Search
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
                                TextField("Search", text: $sideSearch)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.08))
                            )

                            // Actions
                            VStack(alignment: .leading, spacing: 16) {
                                // New chat
                                Button {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.22)) { showSidePanel = false }
                                    Task { await startNewChatFromMenu() }
                                } label: {
                                    menuRow(icon: "square.and.pencil", title: "New chat")
                                }
                                .buttonStyle(.plain)

                                // Library
                                Button {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.22)) { showSidePanel = false }
                                    showLibrary = true
                                } label: {
                                    menuRow(icon: "photo.on.rectangle", title: "Library")
                                }
                                .buttonStyle(.plain)

                                // GPTs popup
                                Button {
                                    showProvidersSheet = true
                                } label: {
                                    menuRow(icon: "square.grid.3x3.fill", title: "GPTs")
                                }
                                .buttonStyle(.plain)
                                // removed "Check connection" button per request
                            }

                            Divider().background(Color.white.opacity(0.15))

                            // Recents from Supabase
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Chats")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.caption)
                                    .padding(.bottom, 2)
                                let list: [RecentChat] = {
                                    let s = sideSearch.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if s.isEmpty { return recentChats }
                                    return recentChats.filter { $0.title.localizedCaseInsensitiveContains(s) }
                                }()
                                if list.isEmpty {
                                    Text("No recent chats")
                                        .foregroundColor(.white.opacity(0.6))
                                } else {
                                    ForEach(list) { rc in
                                        HStack(alignment: .center, spacing: 8) {
                                            NavigationLink(destination: ChatView(initialText: rc.title)) {
                                                Text(rc.title)
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(2)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .buttonStyle(.plain)
                                            Button {
                                                chatToDelete = rc
                                                showDeleteConfirm = true
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red.opacity(0.9))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                }
                            }

                            Spacer(minLength: 80) // Leave space above footer
                        }
                        .padding(16)
                    }

                    // Fixed footer pinned at bottom
                    VStack(alignment: .leading, spacing: 12) {
                        // Fixed user row at bottom
                        HStack(spacing: 10) {
                            let name = SupabaseAuth.shared.displayName
                            ZStack {
                                Circle().fill(Color.purple.opacity(0.8))
                                Text(String(name.prefix(1)).uppercased())
                                    .font(.subheadline).bold()
                                    .foregroundColor(.white)
                            }
                            .frame(width: 28, height: 28)
                            Text(name)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { showAccountDialog = true } }
                        .padding(16)
                        .background(Color.black.opacity(0.9))
                    }
                    // Floating account card like screenshot
                    .overlay(alignment: .bottomLeading) {
                        if showAccountDialog {
                            AccountActionCard(
                                email: SupabaseAuth.shared.lastEmail ?? SupabaseAuth.shared.displayName,
                                onSettings: {
                                    showSettings = true
                                    showAccountDialog = false
                                },
                                onUpgrade: { showPaywall = true },
                                onLogout: {
                                    SupabaseAuth.shared.signOut()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                        showSidePanel = false
                                        showAccountDialog = false
                                    }
                                    dismiss()
                                },
                                onDismiss: { withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { showAccountDialog = false } }
                            )
                            .padding(.leading, 12)
                            .padding(.bottom, 72)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                // Tap anywhere to dismiss the account card (behind the card)
                .background(
                    Group {
                        if showAccountDialog {
                            Color.black.opacity(0.001) // invisible tap catcher behind overlays
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                        showAccountDialog = false
                                    }
                                }
                        }
                    }
                )
                .frame(width: panelWidth, height: proxy.size.height)
                .background(Color.black)
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
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
        let uid = SupabaseAuth.shared.userId
        let res = await SupabaseService().fetchRecentChats(limit: 20, userId: uid)
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
        let chat = RecentChat(title: fallback, userId: SupabaseAuth.shared.userId)
        _ = await SupabaseService().saveRecentChat(chat)
        await MainActor.run {
            goToChat = true
        }
    }

    private func deleteRecent(_ rc: RecentChat) async {
        let res = await SupabaseService().deleteRecentChat(id: rc.id, userId: SupabaseAuth.shared.userId)
        switch res {
        case .success:
            await MainActor.run {
                recentChats.removeAll { $0.id == rc.id }
            }
        case .failure(let err):
            await MainActor.run {
                alertTitle = "Delete Failed"
                alertMessage = err.localizedDescription
                showAlert = true
            }
        }
    }

    private func confirmDelete() async {
        guard let rc = chatToDelete else { return }
        await deleteRecent(rc)
        await MainActor.run {
            chatToDelete = nil
            showDeleteConfirm = false
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
    var icon: String
    var accent: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Soft gradient background with subtle glow
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(colors: [accent.opacity(0.22), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18).stroke(accent, lineWidth: 1.5)
                )
                .shadow(color: accent.opacity(0.35), radius: 12, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                    Text(title)
                        .font(.headline)
                }
                .foregroundColor(.white)
                Text(subtitle)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
                Spacer(minLength: 0)
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
    }
}

private struct GradientActionButton: View {
    var title: String
    var body: some View {
        ZStack {
            // Vibrant gradient similar to iOS wallpaper swirls
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.93, green: 0.18, blue: 0.23), // red
                            Color(red: 0.61, green: 0.20, blue: 0.79), // purple
                            Color(red: 0.12, green: 0.38, blue: 0.97)  // blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 6)
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
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

// MARK: - Support Views
private struct PromptInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let placeholder: String
    let actionTitle: String
    @Binding var text: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).foregroundColor(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle) {
                        onCommit()
                        dismiss()
                    }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}


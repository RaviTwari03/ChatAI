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

// MARK: - Scan Action Sheet (matches PlusActionSheet style)
private struct ScanActionSheet: View {
    var onClose: () -> Void
    var onTextAuto: () -> Void
    var onTextEnglish: () -> Void
    var onBarcode: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Grabber + close
            HStack {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

            // Title
            HStack {
                Text("Scan")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Rows
            VStack(spacing: 0) {
                sheetRow(title: "Text (Auto)", system: "doc.text.viewfinder", tint: .cyan, action: onTextAuto)
                Divider().background(Color.white.opacity(0.12))
                sheetRow(title: "Text (English)", system: "textformat.abc.dottedunderline", tint: .blue, action: onTextEnglish)
                Divider().background(Color.white.opacity(0.12))
                sheetRow(title: "Barcode", system: "barcode.viewfinder", tint: .mint, action: onBarcode)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            ZStack {
                Color.black
                LinearGradient(colors: [Color.black.opacity(0.0), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func sheetRow(title: String, system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(tint.opacity(0.18)).frame(width: 28, height: 28)
                    Image(systemName: system)
                        .foregroundColor(tint)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .foregroundColor(.white)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Web Search Sheet with Change API
private struct WebSearchSheet: View {
    @Binding var text: String
    @Binding var selectedProviderId: String
    var onCommit: () -> Void
    var onCancel: () -> Void
    var onChangeProvider: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    private var providers: [APIProvider] { APIRegistry.shared.providers }

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Button("Cancel") { onCancel(); dismiss() }
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("Web Search")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
                Button("Search") {
                    onCommit()
                    dismiss()
                }
                .foregroundColor(.white.opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0))
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            // Provider chip + Change API
            HStack(spacing: 10) {
                Menu {
                    ForEach(providers) { p in
                        Button(p.displayName) {
                            selectedProviderId = p.id
                            onChangeProvider(p.id)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text(providerName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
                }
                Spacer()
//                Button("Change API") {
//                    // open same menu by program; fallback label covers UX
//                }
                .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)

            // Input
            TextField("What do you want to search?", text: $text, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            Spacer(minLength: 10)
        }
        .background(
            ZStack {
                Color.black
                RadialGradient(colors: [Color.purple.opacity(0.25), .clear], center: .topTrailing, startRadius: 40, endRadius: 420)
                    .blur(radius: 20)
                    .offset(x: 60, y: -80)
                RadialGradient(colors: [Color.green.opacity(0.22), .clear], center: .topLeading, startRadius: 40, endRadius: 420)
                    .blur(radius: 20)
                    .offset(x: -60, y: -120)
            }
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    private var providerName: String {
        providers.first(where: { $0.id == selectedProviderId })?.displayName ?? selectedProviderId
    }
}

// MARK: - Plus Action Sheet (Custom bottom sheet for +)
private struct PlusActionSheet: View {
    var onClose: () -> Void
    var onCreateImageVideo: () -> Void
    var onPromptGallery: () -> Void
    var onCamera: () -> Void
    var onPhotos: () -> Void
    var onAudio: () -> Void
    var onFile: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Grabber + close
            HStack {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

            // Rows
            VStack(spacing: 0) {
                sheetRow(title: "Create Image/Video", system: "sparkles.rectangle.stack", tint: Color.pink, action: onCreateImageVideo)
                Divider().background(Color.white.opacity(0.12))
                sheetRow(title: "Prompt Gallery", system: "square.grid.2x2", tint: Color.purple, action: onPromptGallery)
                Divider().background(Color.white.opacity(0.12))
                sheetRow(title: "Camera", system: "camera", tint: Color.green, action: onCamera)
                Divider().background(Color.white.opacity(0.12))
                sheetRow(title: "Photos", system: "photo.on.rectangle", tint: Color.blue, action: onPhotos)
                Divider().background(Color.white.opacity(0.12))
                sheetRow(title: "Audio", system: "waveform", tint: Color.mint, action: onAudio)
                Divider().background(Color.white.opacity(0.12))
                sheetRow(title: "File", system: "doc", tint: Color.yellow, action: onFile)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            ZStack {
                Color.black
                LinearGradient(colors: [Color.black.opacity(0.0), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func sheetRow(title: String, system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(tint.opacity(0.18)).frame(width: 28, height: 28)
                    Image(systemName: system)
                        .foregroundColor(tint)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .foregroundColor(.white)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Provider dropdown card
private struct ProviderMenuCard: View {
    let providers: [APIProvider]
    let selectedId: String
    var onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(providers) { p in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        providerIcon(for: p.id)
                            .foregroundColor(.white)
                        Text(p.displayName)
                            .foregroundColor(.white)
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 8)
                        HStack(spacing: 6) {
                            if badgeNew(for: p.id) {
                                Pill(text: "New", color: .blue)
                            }
                            if badgeBest(for: p.id) {
                                Pill(text: "Best", color: .purple)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(p.id) }
                    Text(subtitle(for: p.id))
                        .foregroundColor(.white.opacity(0.85))
                        .font(.caption)
                        .padding(.leading, 26)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                if p.id != providers.last?.id {
                    Divider().background(Color.white.opacity(0.12))
                }
            }
        }
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 10)
    }

    private func providerIcon(for id: String) -> some View {
        let symbol: String
        switch id.lowercased() {
        case let s where s.contains("grok"): symbol = "bolt.circle"
        case let s where s.contains("gemini"): symbol = "sparkles"
        default: symbol = "globe"
        }
        return Image(systemName: symbol)
    }

    private func subtitle(for id: String) -> String {
        let s = id.lowercased()
        if s.contains("chatgpt5") || s.contains("gpt-4o") { return "Most powerful AI model" }
        if s.contains("mini") { return "Fast for everyday tasks" }
        if s.contains("grok") { return "xAI's most powerful model" }
        if s.contains("gemini") { return "Google's best model" }
        return "Fast reasoning model"
    }

    private func badgeNew(for id: String) -> Bool {
        let s = id.lowercased()
        return s.contains("grok") || s.contains("gpt-4o") || s.contains("chatgpt5")
    }
    private func badgeBest(for id: String) -> Bool {
        let s = id.lowercased()
        return s.contains("chatgpt") || s.contains("gpt")
    }

    private struct Pill: View {
        let text: String
        let color: Color
        var body: some View {
            Text(text)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(color.opacity(0.9)))
                .foregroundColor(.white)
        }
    }
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
    
    // Present scanner with availability checks
    private func presentScanner(mode: ScanMode) {
        scanMode = mode
        showScanModeSheet = false
        if #available(iOS 16.0, *) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                // Slight delay to let the sheet dismiss before presenting full screen cover
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showScanner = true
                }
            } else {
                alertTitle = "Scanner Unavailable"
                alertMessage = (mode == .barcode) ?
                    "Barcode scanner requires iOS 16+ and a supported device." :
                    "Text scanner requires iOS 16+ and a supported device."
                showAlert = true
            }
        } else {
            alertTitle = "Requires iOS 16+"
            alertMessage = (mode == .barcode) ?
                "Update iOS to use barcode scanning." :
                "Update iOS to use text scanning."
            showAlert = true
        }
    }
    
    // Camera launcher with permission and availability checks
    private func openCamera() {
        // Ensure device has camera
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            alertTitle = "Camera Unavailable"
            alertMessage = "This device doesn't have a camera."
            showAlert = true
            return
        }
        // Check authorization
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.showCamera = true }
                    else {
                        self.alertTitle = "Camera Permission"
                        self.alertMessage = "Camera access is denied. Enable it in Settings > Privacy > Camera."
                        self.showAlert = true
                    }
                }
            }
        case .denied, .restricted:
            alertTitle = "Camera Permission"
            alertMessage = "Camera access is denied. Enable it in Settings > Privacy > Camera."
            showAlert = true
        @unknown default:
            showCamera = true
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
    @State private var docPickerTypes: [UTType] = []
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
    @State private var showScanModeSheet: Bool = false
    // OCR/Barcode scanning flow
    private enum ScanMode { case textAuto, textEnglish, barcode }
    @State private var scanMode: ScanMode = .textAuto
    @State private var showScanModePicker: Bool = false
    @State private var showScanReview: Bool = false
    @State private var scannedTextDraft: String = ""
    // Keyboard focus for bottom composer
    @FocusState private var isComposerFocused: Bool
    // Provider chip frame to anchor the dropdown animation
    @State private var providerChipFrame: CGRect = .zero
    // Delete confirmation state
    @State private var showDeleteConfirm: Bool = false
    @State private var chatToDelete: RecentChat? = nil
    // Account dialog
    @State private var showAccountDialog: Bool = false
    // Settings screen navigation
    @State private var showSettings: Bool = false
    // Provider dropdown
    @State private var showProviderMenu: Bool = false
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

                    // Center chip: custom dropdown to switch APIs
                    Button(action: { withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) { showProviderMenu.toggle() } }) {
                        CapsuleChip {
                            HStack(spacing: 6) {
                                Text(selectedDisplayName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .rotationEffect(.degrees(showProviderMenu ? 180 : 0))
                                    .animation(.easeInOut(duration: 0.2), value: showProviderMenu)
                            }
                            // Fix the width to keep the title visually centered relative to the chevron
                            .frame(width: 140, alignment: .center)
                        }
                    }
                    .buttonStyle(.plain)
                    // Capture the global frame of the provider chip to anchor the dropdown
                    .background(
                        GeometryReader { gp in
                            Color.clear
                                .onAppear { providerChipFrame = gp.frame(in: .global) }
                        }
                    )

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

                // Feature cards (one per page, full width) with page indicator
                TabView {
                    // Page: Creative Studio
                    VStack {
                        NavigationLink { CreativeStudioView() } label: {
                            FeatureCard(title: "Creative Studio", subtitle: "Create", icon: "sparkles.rectangle.stack", accent: .pink)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .tag(0)

                    // Page: Files
                    VStack { 
                        Button(action: { showDocPicker = true }) {
                            FeatureCard(title: "Files", subtitle: "Upload", icon: "folder", accent: .blue)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .tag(1)

                    // Page: Web
                    VStack { 
                        Button(action: { showLinkSheet = true }) {
                            FeatureCard(title: "Web", subtitle: "Links", icon: "link", accent: .cyan)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .tag(2)

                    // Page: Voice
                    VStack { 
                        NavigationLink { VoiceChatView() } label: {
                            FeatureCard(title: "Voice", subtitle: "Chat", icon: "waveform", accent: .orange)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .tag(3)
                }
                .frame(height: 190)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
                .padding(.bottom, 10)

                // Bottom quick actions (gradient cards)
                HStack(spacing: 20) {
                    Button(action: { showImagePromptSheet = true }) {
                        GradientActionButton(title: "Create Images")
                    }
                    .buttonStyle(.plain)
                    Button(action: { openCamera() }) {
                        GradientActionButton(title: "Open Camera")
                    }
                    .buttonStyle(.plain)
                    Button(action: { pickedItem = nil; showPhotosPicker = true }) {
                        GradientActionButton(title: "Edit Images")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

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
                                    // Present custom scan options sheet (styled like PlusActionSheet)
                                    showScanModeSheet = true
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
                    // Custom Plus bottom sheet
                    .sheet(isPresented: $showPlusMenu) {
                        PlusActionSheet(
                            onClose: { showPlusMenu = false },
                            onCreateImageVideo: {
                                showPlusMenu = false
                                // Reuse create image flow
                                showImagePromptSheet = true
                            },
                            onPromptGallery: {
                                showPlusMenu = false
                                // For now, reuse image prompt sheet as a gallery entry point
                                showImagePromptSheet = true
                            },
                            onCamera: {
                                showPlusMenu = false
                                openCamera()
                            },
                            onPhotos: {
                                showPlusMenu = false
                                pickedItem = nil
                                showPhotosPicker = true
                            },
                            onAudio: {
                                showPlusMenu = false
                                // Audio-only types
                                docPickerTypes = [.audio, .mp3, .mpeg4Audio, .wav, .aiff].compactMap { $0 }
                                showDocPicker = true
                            },
                            onFile: {
                                showPlusMenu = false
                                showDocPicker = true
                            }
                        )
                        .presentationDetents([.fraction(0.42), .medium])
                        .presentationDragIndicator(.hidden)
                    }
                    // Attachments
                    .photosPicker(isPresented: $showPhotosPicker, selection: $pickedItem, matching: .images)
                    .onChange(of: pickedItem) { item in
                        Task {
                            if let item, let data = try? await item.loadTransferable(type: Data.self) {
                                attachmentData = data
                                attachmentMime = "image/jpeg"
                                // Clear the selected item to avoid stale re-use
                                pickedItem = nil
                                // Navigate after state settles
                                DispatchQueue.main.async {
                                    goToChatWithAttachment = true
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showDocPicker) {
                        DocumentPickerRepresentable(contentTypes: docPickerTypes.isEmpty ? nil : docPickerTypes) { url in
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
                                // Reset types after use
                                docPickerTypes = []
                            } catch { docPickerTypes = [] }
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

                    // Full-screen scanner (OCR or Barcode based on selected mode)
                    .fullScreenCover(isPresented: $showScanner) {
                        if #available(iOS 16.0, *) {
                            Group {
                                switch scanMode {
                                case .textAuto:
                                    TextScannerContainer(
                                        onText: { text in
                                            // Insert as-is into composer and keep keyboard active
                                            homeDraft = text
                                            showScanner = false
                                            DispatchQueue.main.async { isComposerFocused = true }
                                        },
                                        onCancel: { showScanner = false },
                                        languages: nil
                                    )
                                case .textEnglish:
                                    TextScannerContainer(
                                        onText: { text in
                                            homeDraft = text
                                            showScanner = false
                                            DispatchQueue.main.async { isComposerFocused = true }
                                        },
                                        onCancel: { showScanner = false },
                                        languages: ["en"]
                                    )
                                    
                                case .barcode:
                                    BarcodeScannerContainer(
                                        onPayload: { payload in
                                            homeDraft = payload
                                            showScanner = false
                                            DispatchQueue.main.async { isComposerFocused = true }
                                        },
                                        onCancel: { showScanner = false }
                                    )
                                }
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    // Review & Edit sheet
                    .sheet(isPresented: $showScanReview) {
                        NavigationStack {
                            VStack(alignment: .leading, spacing: 12) {
                                TextEditor(text: $scannedTextDraft)
                                    .scrollContentBackground(.hidden)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .frame(minHeight: 160)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.black.ignoresSafeArea())
                            .toolbar {
                                ToolbarItem(placement: .principal) { Text("Review Text").foregroundColor(.white) }
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { scannedTextDraft = ""; showScanReview = false }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Send") {
                                        let t = scannedTextDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !t.isEmpty { homeDraft = t; showScanReview = false; Task { await startChat() } }
                                    }.disabled(scannedTextDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                        }
                        .preferredColorScheme(.dark)
                    }
                    // Mode picker sheet styled like the second screenshot
                    .sheet(isPresented: $showScanModeSheet) {
                        ScanActionSheet(
                            onClose: { showScanModeSheet = false },
                            onTextAuto: { presentScanner(mode: .textAuto) },
                            onTextEnglish: { presentScanner(mode: .textEnglish) },
                            onBarcode: { presentScanner(mode: .barcode) }
                        )
                        .presentationDetents([.fraction(0.32)])
                        .presentationDragIndicator(.hidden)
                    }

                    // Hidden navigation to Library (standalone; no redirect to chat on tap)
                    NavigationLink(isActive: $showLibrary) {
                        CloudLibraryView()
                    } label: { EmptyView() }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, -52)
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
                // Present camera when user taps Open Camera or Plus > Camera
                .fullScreenCover(isPresented: $showCamera) {
                    ImagePickerRepresentable(sourceType: .camera) { image in
                        // Convert to JPEG and store attachment
                        if let img = image, let data = img.jpegData(compressionQuality: 0.9) {
                            attachmentData = data
                            attachmentMime = "image/jpeg"
                        }
                        // Dismiss the camera first, then navigate on next run loop to avoid race
                        showCamera = false
                        DispatchQueue.main.async {
                            if attachmentData != nil { goToChatWithAttachment = true }
                        }
                    }
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
                    WebSearchSheet(
                        text: $webSearchText,
                        selectedProviderId: $selectedProviderId,
                        onCommit: {
                            let t = webSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            homeDraft = "Search the web: \(t)"
                            webSearchText = ""
                            showWebSearchSheet = false
                            Task { await startChat() }
                        },
                        onCancel: { webSearchText = "" },
                        onChangeProvider: { id in
                            selectedProviderId = id
                            APIRegistry.shared.setCurrentProvider(id: id)
                        }
                    )
                    .presentationDetents([.fraction(0.36), .medium])
                }
            }

            // MARK: - 2/3 Left Slide-Over Panel
            if showSidePanel { sideOverlay }
            // Hidden navigation to Settings
            NavigationLink(isActive: $showSettings) {
                SettingsView()
            } label: { EmptyView() }
        }
        // Frosted blur over the whole HomeView when + menu is open
        .overlay(
            Group {
                if showPlusMenu || showScanModeSheet {
                    Color.clear
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
        )
        .blur(radius: (showPlusMenu || showScanModeSheet) ? 14 : 0)
        .animation(.easeInOut(duration: 0.22), value: showPlusMenu)
        .animation(.easeInOut(duration: 0.22), value: showScanModeSheet)
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.30, dampingFraction: 0.86, blendDuration: 0.2), value: showSidePanel)
        // Provider menu overlay
        .overlay(alignment: .top) {
            if showProviderMenu {
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        // tap-catcher
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture { withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) { showProviderMenu = false } }
                        // Half-screen styled dropdown sized similarly to the reference
                        // Compute compact width anchored to the chip, with safe margins
                        let desiredWidth = min(geo.size.width * 0.80, 360)
                        let desiredHeight = geo.size.height * 0.5
                        // Center horizontally to the provider chip's midX, respecting safe margins
                        let centerX = max(desiredWidth/2 + 16, min(providerChipFrame.midX, geo.size.width - desiredWidth/2 - 16))
                        // Place the TOP of the card 8pt below the chip; convert to center Y for .position
                        let topY = providerChipFrame.maxY + 8
                        let centerYRaw = topY + desiredHeight/2
                        let centerY = min(max(centerYRaw, desiredHeight/2 + 24), geo.size.height - desiredHeight/2 - 24)

                        VStack(spacing: 0) {
                            ScrollView {
                                ProviderMenuCard(
                                    providers: providers,
                                    selectedId: selectedProviderId,
                                    onSelect: { id in
                                        selectedProviderId = id
                                        APIRegistry.shared.setCurrentProvider(id: id)
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) { showProviderMenu = false }
                                    }
                                )
                                .padding(.vertical, 8)
                            }
                        }
                        .frame(width: desiredWidth, height: desiredHeight)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
                        .position(x: centerX, y: centerY)
                        // Smooth pop-in from the chip location
                        .transition({ () -> AnyTransition in
                            let ax = max(0.0, min(1.0, providerChipFrame.midX / max(geo.size.width, 1)))
                            let ay = max(0.0, min(1.0, providerChipFrame.midY / max(geo.size.height, 1)))
                            let anchor = UnitPoint(x: ax, y: ay)
                            return AnyTransition.scale(scale: 0.92, anchor: anchor).combined(with: .opacity)
                        }())
                    }
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.88, blendDuration: 0.2), value: showProviderMenu)
            }
        }
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


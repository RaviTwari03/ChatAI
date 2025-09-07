//
//  ChatView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI
import UIKit
import Photos

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    // Optional image payload for assistant responses
    let imageData: Data?

    init(text: String, isUser: Bool, imageData: Data? = nil) {
        self.text = text
        self.isUser = isUser
        self.imageData = imageData
    }
}

final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        //ChatMessage(text: "Hi, Jason! Welcome to AI Chat. How can i help you today?", isUser: false)
    ]
    @Published var input: String = ""
    @Published var isSending: Bool = false

    func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        input = ""
        messages.append(ChatMessage(text: trimmed, isUser: true))
        isSending = true

        Task { @MainActor in
            do {
                if isImagePrompt(trimmed) {
                    let clean = cleanImagePrompt(trimmed)
                    do {
                        let data = try await APIRegistry.shared.generateImage(prompt: clean, size: "1024x1024")
                        messages.append(ChatMessage(text: "[Image generated] \(clean)", isUser: false, imageData: data))
                    } catch {
                        messages.append(ChatMessage(text: "Image generation failed: \(error.localizedDescription)", isUser: false))
                    }
                } else {
                    // Build full history for one-to-one context
                    var history: [[String: String]] = [["role": "system", "content": "You are a helpful assistant."]]
                    history.append(contentsOf: messages.map { msg in
                        ["role": msg.isUser ? "user" : "assistant", "content": msg.text]
                    })
                    // Route through registry so the active provider (OpenAI or GROK) is used
                    let reply = try await APIRegistry.shared.complete(messages: history)
                    messages.append(ChatMessage(text: reply, isUser: false))
                }
            } catch {
                messages.append(ChatMessage(text: "Sorry, I couldn't process that. \n\nError: \(error.localizedDescription)", isUser: false))
            }
            isSending = false
        }
    }
}

struct ChatView: View {
    var initialText: String? = nil
    @StateObject private var vm = ChatViewModel()
    @FocusState private var focused: Bool
    @State private var autoSent = false
    // no timer state; we'll show a typing indicator bubble instead

    var body: some View {
        ZStack {
            neonBackdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar (use native back button only)
                HStack {
                    Spacer()
                    Text("AI Chat")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(vm.messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                            if vm.isSending {
                                typingIndicatorBubble
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { focused = false }
                    .onChange(of: vm.messages) { _ in
                        if let last = vm.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Composer anchored to safe area to ensure taps reach the field
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type a message...", text: $vm.input, axis: .vertical)
                    .lineLimit(1...4)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .foregroundColor(.white)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit { vm.send() }

                Button(action: vm.send) {
                    Image(systemName: vm.isSending ? "hourglass" : "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(vm.isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
        }
        .onAppear {
            if let t = initialText, !t.isEmpty, !autoSent {
                vm.input = t
                vm.send()            // immediately send and let API process
                autoSent = true
            }
            focused = true
        }
        .preferredColorScheme(.dark)
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.isUser { Spacer(minLength: 50) }
            VStack(alignment: .leading, spacing: 8) {
                if let data = msg.imageData, let image = UIImage(data: data) {
                    ImageBubble(image: image)
                }
                Text(msg.text)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                msg.isUser ? AnyView(
                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                ) : AnyView(
                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.18))
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(msg.isUser ? 0.0 : 0.15), lineWidth: 1)
            )
            if !msg.isUser { Spacer(minLength: 50) }
        }
    }

    // Typing indicator bubble (orbiting loader)
    @ViewBuilder
    private var typingIndicatorBubble: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    OrbitLoader(size: 22)
                    Text("Thinking…")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.18)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            Spacer(minLength: 50)
        }
    }

    // Orbiting loader animation
    private struct OrbitLoader: View {
        let size: CGFloat
        @State private var rotation: Angle = .degrees(0)
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: size, height: size)
                ForEach(0..<6) { i in
                    let angle = Angle(degrees: Double(i) * 60)
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: size * 0.12, height: size * 0.12)
                        .offset(x: size/2)
                        .rotationEffect(angle)
                }
            }
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    rotation = .degrees(360)
                }
            }
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
        }
    }
}

// MARK: - Image Prompt Helpers (shared with VoiceChatView logic)
private func isImagePrompt(_ text: String) -> Bool {
    let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    if lower.hasPrefix("image:") { return true }
    let triggers = [
        "generate an image",
        "generate image",
        "create an image",
        "draw",
        "make an image",
        "image of",
        "picture of",
        "art of"
    ]
    return triggers.contains { lower.contains($0) }
}

private func cleanImagePrompt(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.lowercased().hasPrefix("image:") {
        return String(trimmed.dropFirst("image:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let patterns = [
        "generate an image of",
        "generate image of",
        "create an image of",
        "make an image of",
        "draw",
        "image of",
        "picture of",
        "art of"
    ]
    let lower = trimmed.lowercased()
    for p in patterns {
        if lower.hasPrefix(p) {
            let idx = trimmed.index(trimmed.startIndex, offsetBy: p.count)
            let rest = trimmed[idx...]
            return String(rest).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    return trimmed
}

// MARK: - ImageBubble subview with Save to Photos
private struct ImageBubble: View {
    let image: UIImage
    @State private var status: String? = nil
    @State private var saved: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300, maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
            HStack(spacing: 12) {
                Button(action: { Task { await saveToPhotos(image) } }) {
                    HStack(spacing: 6) {
                        Image(systemName: saved ? "checkmark.circle" : "square.and.arrow.down")
                        Text(saved ? "Saved" : "Save to Photos")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.18)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .disabled(saved)
                .foregroundColor(.white)
                if let s = status {
                    Text(s)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.top, 2)
        }
    }

    private func saveToPhotos(_ image: UIImage) async {
        await MainActor.run { status = "Saving…" }
        if #available(iOS 14, *) {
            let auth = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if auth == .notDetermined {
                let _ = await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                    PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in cont.resume() }
                }
            }
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            await MainActor.run {
                status = "Saved"
                saved = true
            }
        } catch {
            await MainActor.run { status = "Failed: \(error.localizedDescription)" }
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run { status = nil }
    }
}

#Preview {
    NavigationStack { ChatView() }
}

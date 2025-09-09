//
//  VoiceChatView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 07/09/25.
//

import SwiftUI
import AVFoundation
import UIKit
import Photos

// MARK: - Main View
struct VoiceChatView: View {
    @StateObject private var speech = SpeechRecognizer()
    @State private var messages: [ChatMessage] = []
    @State private var isSending = false
    @StateObject private var tts = TTSService()
    @State private var lastTranscriptUpdate: Date = Date()
    @State private var pulse: Bool = false
    @State private var generatedImage: UIImage? = nil
    @State private var saveMessage: String? = nil
    @State private var imageSaved: Bool = false
    @State private var showVoicePicker: Bool = false
    @State private var showPaywall: Bool = false
    
    var body: some View {
        ZStack {
            neonBackdrop.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header View
                headerView
                
                // Main Content Area
                mainContentView
                
                // Generated Image View
                if let image = generatedImage {
                    generatedImageView(image: image)
                        .transition(.opacity)
                }
                
                // Transcript View
                if !speech.transcript.isEmpty && speech.isRecording {
                    transcriptView
                }
                
                Spacer(minLength: 0)
            }
        }
        .sheet(isPresented: $showVoicePicker) {
            VoicePickerView(selectedVoice: $tts.selectedVoice, isPresented: $showVoicePicker)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear(perform: setupSpeechRecognition)
        .onChange(of: speech.transcript) { _ in
            lastTranscriptUpdate = Date()
        }
        .onReceive(Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()) { _ in
            checkForSilence()
        }
        .onDisappear(perform: cleanup)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        HStack {
            Spacer()
            Text("Voice Chat")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            
            // Voice Selection Button
            Button(action: { showVoicePicker = true }) {
                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.blue.opacity(0.2)))
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 12)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 16) {
            ParticleOrb()
                .frame(width: 300, height: 300)
                .accessibilityLabel("Listening animation")
            
            if isSending {
                HStack(spacing: 8) {
                    OrbitLoader(size: 22)
                    Text("Thinking…")
                        .foregroundColor(.cyan)
                        .font(.subheadline.weight(.medium))
                        .opacity(0.9)
                }
                .padding(.top, 4)
            } else {
                Text(statusCaption)
                    .foregroundColor(.cyan)
                    .font(.subheadline.weight(.medium))
                    .opacity(0.9)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 380)
    }
    
    private func generatedImageView(image: UIImage) -> some View {
        VStack(spacing: 10) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            HStack(spacing: 12) {
                Button(action: { Task { await saveToPhotos(image) } }) {
                    HStack(spacing: 6) {
                        Image(systemName: imageSaved ? "checkmark.circle" : "square.and.arrow.down")
                        Text(imageSaved ? "Saved" : "Save to Photos")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.18)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .disabled(imageSaved)
                .foregroundColor(.white)
                
                if let msg = saveMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var transcriptView: some View {
        Text(speech.transcript)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
    }
    
    // MARK: - Helper Methods
    private func setupSpeechRecognition() {
        Task {
            await speech.requestAuthorization()
            if !speech.isRecording {
                speech.transcript = ""
                try? speech.start()
            }
        }
        
        tts.onFinish = { [weak speech, isSending] in
            guard let speech = speech, !speech.isRecording, !isSending else { return }
            speech.transcript = ""
            try? speech.start()
        }
    }
    
    private func checkForSilence() {
        guard speech.isRecording else { return }
        let hasSpeech = !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasSpeech && Date().timeIntervalSince(lastTranscriptUpdate) >= 2.0 {
            micTapped()
        }
    }
    
    private func cleanup() {
        if speech.isRecording { speech.stop() }
        tts.stop()
    }

    private var statusCaption: String {
        if tts.isSpeaking { return "Speaking…" }
        if isSending { return "Thinking…" }
        if speech.isRecording { return "Say something…" }
        return "Starting…"
    }

    private func micTapped() {
        if speech.isRecording {
            // Stop recording and send transcript if available
            speech.stop()
            let prompt = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !prompt.isEmpty { Task { await send(prompt: prompt) } }
        } else {
            // If TTS is speaking, stop before resuming mic
            tts.stop()
            speech.transcript = ""
            try? speech.start()
        }
    }

    private func send(prompt: String) async {
        await MainActor.run {
            messages.append(ChatMessage(text: prompt, isUser: true))
            isSending = true
        }
        do {
            // Consume one token per send unless user is Pro
            let providerId = APIRegistry.shared.activeProvider().id
            let consume = await SupabaseService().rpcConsumeSearchToken(provider: providerId)
            switch consume {
            case .failure(let err):
                await MainActor.run {
                    messages.append(ChatMessage(text: "Credits check failed: \(err.localizedDescription)", isUser: false))
                    isSending = false
                    showPaywall = true
                }
                return
            case .success(let res):
                if !res.allowed {
                    await MainActor.run {
                        let msg: String
                        switch res.reason {
                        case "daily_limit": msg = "Daily usage limit reached. Upgrade to Pro to continue today."
                        case "insufficient_tokens": msg = "You're out of credits. Please upgrade to Pro or buy tokens."
                        default: msg = "Usage limit reached. Please upgrade to Pro."
                        }
                        messages.append(ChatMessage(text: msg, isUser: false))
                        isSending = false
                        showPaywall = true
                    }
                    return
                }
            }
            if isImagePrompt(prompt) {
                // Clear previous image to show fresh state
                await MainActor.run { generatedImage = nil }
                let clean = cleanImagePrompt(prompt)
                let data = try await APIRegistry.shared.generateImage(prompt: clean, size: "1024x1024")
                if let uiimg = UIImage(data: data) {
                    await MainActor.run {
                        generatedImage = uiimg
                        messages.append(ChatMessage(text: "[Image generated] \(clean)", isUser: false))
                        // Do not TTS the image
                        isSending = false
                    }
                } else {
                    throw NSError(domain: "VoiceChatView", code: -10, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image data"])
                }
            } else {
                // Build one-to-one conversation history
                var history: [[String: String]] = [["role": "system", "content": "You are a helpful assistant."]]
                history.append(contentsOf: messages.map { m in ["role": m.isUser ? "user" : "assistant", "content": m.text] })
                let reply = try await APIRegistry.shared.complete(messages: history)
                await MainActor.run {
                    // Keep conversation context internally but do not render assistant text on screen
                    messages.append(ChatMessage(text: reply, isUser: false))
                    speak(reply)
                    isSending = false
                }
            }
        } catch {
            await MainActor.run {
                messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false))
                isSending = false
            }
        }
    }

    private func speak(_ text: String) {
        tts.speak(text)
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.isUser { Spacer(minLength: 50) }
            Text(msg.text)
                .foregroundColor(.white)
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

    private var recordingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform")
            Text("Listening…")
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.18)))
    }

    private var typingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView().progressViewStyle(.circular)
            Text("Thinking…")
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.18)))
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

    // MARK: - Image Prompt Helpers
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
        // Remove leading trigger phrases to produce a better prompt
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
        var lower = trimmed.lowercased()
        for p in patterns {
            if lower.hasPrefix(p) {
                let idx = trimmed.index(trimmed.startIndex, offsetBy: p.count)
                let rest = trimmed[idx...]
                return rest.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return trimmed
    }

    // MARK: - Saving
    private func saveToPhotos(_ image: UIImage) async {
        await MainActor.run { saveMessage = "Saving…" }
        // Use Photos framework for add-only access
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if status == .notDetermined {
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
                saveMessage = "Saved"
                imageSaved = true
            }
        } catch {
            await MainActor.run { saveMessage = "Failed: \(error.localizedDescription)" }
        }
        // Clear status after a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run { saveMessage = nil }
    }

    // Orbiting loader animation (same as ChatView)
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
}

// MARK: - Voice Picker View
private struct VoicePickerView: View {
    @Binding var selectedVoice: VoiceOption
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(VoiceOption.availableVoices) { voice in
                    Button(action: {
                        selectedVoice = voice
                        isPresented = false
                    }) {
                        HStack {
                            Text(voice.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedVoice.id == voice.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Animations
/// Moving particle orb for listening state
private struct ParticleOrb: View {
    @State private var t: CGFloat = 0
    private let particleCount = 120
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let minSide = min(size.width, size.height)
                let radius = minSide * 0.42
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<particleCount {
                    let angle = (Double(i) / Double(particleCount)) * 2 * .pi + sin(time * 0.6 + Double(i)) * 0.08
                    let rJitter = radius + sin(time * 1.2 + Double(i) * 0.5) * 6.0
                    let x = center.x + CGFloat(cos(angle)) * CGFloat(rJitter)
                    let y = center.y + CGFloat(sin(angle)) * CGFloat(rJitter)
                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.9)))
                }
            }
        }
        .background(
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(12)
    }
}

private struct SpeakingAnimation: View {
    @State private var t: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 6) {
                ForEach(0..<5) { i in
                    let height = barHeight(i, totalHeight: geo.size.height)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: (geo.size.width - 24)/5, height: height)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    t = 1
                }
            }
        }
    }
    private func barHeight(_ i: Int, totalHeight: CGFloat) -> CGFloat {
        let base: CGFloat = totalHeight * 0.35
        let variance: CGFloat = totalHeight * 0.3
        let s = sin(Double(i) + Date().timeIntervalSinceReferenceDate * 3.0)
        return max(10, base + variance * CGFloat(abs(s)))
    }
}

//#Preview {
//    NavigationStack { VoiceChatView() }
//}

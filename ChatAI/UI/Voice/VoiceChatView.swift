//
//  VoiceChatView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 07/09/25.
//

import SwiftUI
import AVFoundation

struct VoiceChatView: View {
    @StateObject private var speech = SpeechRecognizer()
    @State private var messages: [ChatMessage] = []
    @State private var isSending = false
    @StateObject private var tts = TTSService()
    @State private var lastTranscriptUpdate: Date = Date()
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            neonBackdrop.ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Spacer()
                    Text("Voice Chat")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 12)

                // Center orb is always visible with a caption underneath
                VStack(spacing: 16) {
                    ZStack {
                        ParticleOrb()
                            .frame(width: 240, height: 240)
                            .accessibilityLabel("Listening animation")
                        if isSending || tts.isSpeaking {
                            SpeakingAnimation()
                                .frame(width: 180, height: 90)
                                .accessibilityLabel("Speaking animation")
                                .transition(.opacity)
                        }
                    }
                    Text(statusCaption)
                        .foregroundColor(.cyan)
                        .font(.subheadline.weight(.medium))
                        .opacity(0.9)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: 340)

                // Recognized text preview (optional while recording)
                if !speech.transcript.isEmpty && speech.isRecording {
                    Text(speech.transcript)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            Task {
                await speech.requestAuthorization()
                // Auto-start listening on enter once permissions are settled
                if !speech.isRecording {
                    speech.transcript = ""
                    try? speech.start()
                }
            }
            // After TTS finishes speaking, auto-resume listening for the next user turn
            tts.onFinish = {
                // Safety: don't auto-start if we're already recording or currently sending
                guard !speech.isRecording, !isSending else { return }
                speech.transcript = ""
                try? speech.start()
            }
        }
        .onChange(of: speech.transcript) { text in
            // Update silence timer marker when transcript changes
            lastTranscriptUpdate = Date()
        }
        // Silence detection: if recording and transcript is non-empty and 3s pass without change, auto-stop and send
        .onReceive(Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()) { _ in
            guard speech.isRecording else { return }
            let hasSpeech = !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if hasSpeech && Date().timeIntervalSince(lastTranscriptUpdate) >= 2.0 {
                micTapped() // this will stop and send
            }
        }
        .onDisappear {
            // Stop any audio when leaving
            if speech.isRecording { speech.stop() }
            tts.stop()
        }
        .preferredColorScheme(.dark)
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

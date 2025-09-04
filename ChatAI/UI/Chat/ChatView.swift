//
//  ChatView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
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
                // Route through registry so the active provider (OpenAI or GROK) is used
                let reply = try await APIRegistry.shared.complete(prompt: trimmed)
                messages.append(ChatMessage(text: reply, isUser: false))
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

    // Typing indicator bubble (three pulsing dots)
    @ViewBuilder
    private var typingIndicatorBubble: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    TypingDots()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.18)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            Spacer(minLength: 50)
        }
    }

    // Dots animation view
    private struct TypingDots: View {
        @State private var phase: CGFloat = 0
        var body: some View {
            HStack(spacing: 6) {
                Circle().fill(Color.white.opacity(0.9)).frame(width: 6, height: 6).scaleEffect(dotScale(0))
                Circle().fill(Color.white.opacity(0.9)).frame(width: 6, height: 6).scaleEffect(dotScale(1))
                Circle().fill(Color.white.opacity(0.9)).frame(width: 6, height: 6).scaleEffect(dotScale(2))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    phase = 1
                }
            }
        }
        private func dotScale(_ index: Int) -> CGFloat {
            let base: CGFloat = 0.6
            let t = (phase + CGFloat(index) * 0.2).truncatingRemainder(dividingBy: 1)
            return base + 0.4 * abs(sin(Double(t) * .pi))
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

#Preview {
    NavigationStack { ChatView() }
}

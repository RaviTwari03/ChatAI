//
//  VideoGenerationView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 17/09/25.
//

import SwiftUI

struct VideoGenerationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let prompt: String
    let aspect: String  // "square" | "landscape" | "portrait"
    let modelName: String // e.g., "Veo 3" or others

    @State private var statusText: String = "Queued"
    @State private var isWorking: Bool = true
    @State private var progress: Double? = nil
    @State private var videoURL: URL? = nil
    @State private var errorText: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Text("Generating Video")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top, 8)

            Spacer()

            if let url = videoURL {
                ZStack {
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill").font(.system(size: 64)).foregroundColor(.white)
                        Text("Open Video").foregroundColor(.white)
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 24)
                .onTapGesture { openURL(url) }
            } else if let err = errorText {
                Text(err)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .padding(.horizontal, 24)
                Text(statusText).foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text(videoURL == nil ? "Close" : "Done")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25), lineWidth: 1))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(colors: [Color.black, Color(red: 0.02, green: 0.03, blue: 0.06)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .task { await start() }
        .preferredColorScheme(.dark)
    }

    private func start() async {
        isWorking = true
        statusText = "Starting..."
        do {
            let provider: VideoProvider = (modelName == "Veo 3") ? .veo : .pika
            let svc = VideoServiceFactory.make(provider)
            let dims = dimensions()
            var job = try await svc.startVideo(prompt: prompt, options: VideoGenerationOptions(durationSeconds: 5, width: dims.w, height: dims.h))
            statusText = "Queued"

            let startTime = Date()
            // Poll loop
            while true {
                switch job.status {
                case .queued:
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    job = try await svc.getStatus(jobId: job.id)
                case .processing(let p):
                    progress = p
                    statusText = p != nil ? String(format: "Processing %.0f%%", (p ?? 0)*100) : "Processing..."
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    job = try await svc.getStatus(jobId: job.id)
                case .completed(let url):
                    videoURL = url
                    statusText = "Completed"
                    isWorking = false
                    return
                case .failed(let err):
                    errorText = err
                    statusText = "Failed"
                    isWorking = false
                    return
                }
                if Date().timeIntervalSince(startTime) > 180 { // 3 min timeout
                    errorText = "Timed out waiting for video generation. Please try again later."
                    isWorking = false
                    return
                }
            }
        } catch {
            errorText = error.localizedDescription
            statusText = "Failed"
            isWorking = false
        }
    }

    private func dimensions() -> (w: Int, h: Int) {
        switch aspect.lowercased() {
        case "square": return (1024, 1024)
        case "landscape": return (1280, 720)
        default: return (720, 1280)
        }
    }
}

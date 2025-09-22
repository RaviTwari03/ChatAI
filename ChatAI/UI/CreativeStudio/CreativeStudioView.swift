//
//  CreativeStudioView.swift
//  ChatAI
//
//  Created by Cascade on 17/09/25.
//

import SwiftUI
import AVKit
import UIKit

struct CreativeStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var prompt: String = ""
    @State private var showPhotosPicker: Bool = false
    @State private var showSettings: Bool = false
    @State private var isSending: Bool = false
    // New: generation options
    private enum MediaType: String { case image = "Image", video = "Video" }
    private enum Aspect: String { case square = "Square", landscape = "Landscape", portrait = "Portrait" }
    @State private var mediaType: MediaType = .image
    @State private var aspect: Aspect = .portrait
    @State private var modelName: String = "Flux"

    // Generated items (new)
    private enum StudioItem: Identifiable, Equatable {
        case image(UIImage)
        case video(URL)
        var id: String {
            switch self {
            case .image(let img): return "img-\(img.hash)"
            case .video(let url): return url.absoluteString
            }
        }
    }
    @State private var items: [StudioItem] = []
    // Video generation presentation
    @State private var showVideoGen: Bool = false
    @State private var pendingVideoPrompt: String = ""
    @State private var pendingVideoAspect: Aspect = .portrait
    @State private var pendingVideoModel: String = "Veo 3"

    var body: some View {
        ZStack {
            neonBackdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: Back only
                HStack(spacing: 12) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Title row
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Studio")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 8) {
                        pill(icon: "paintbrush.pointed.fill", text: "1,230")
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Preview grid (banner removed from here)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Generated/latest first
                        if !items.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(items) { it in
                                    switch it {
                                    case .image(let ui):
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 220)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    case .video(let url):
                                        ZStack {
                                            // Simple gradient thumb with play icon
                                            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 44))
                                                .foregroundColor(.white)
                                        }
                                        .frame(height: 220)
                                        .onTapGesture { openURL(url) }
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Static samples
                        HStack(spacing: 12) {
                            studioImage("img")
                            studioImage("image2")
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                }

                Spacer(minLength: 0)

                // High demand banner RIGHT ABOVE the composer
                HStack {
                    ZStack {
                        LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("High demand:")
                                    .font(.subheadline.bold())
                                Text("Media generation may be slow or produce errors.")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(102)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 106)

                // Bottom composer (controls INSIDE the same rounded container)
                HStack { Spacer(minLength: 0) }
                    .frame(height: 0) // spacer hack to keep safe-area bg same as before
                    .background(Color.black.opacity(0.55).ignoresSafeArea())
                    .overlay(
                        VStack(spacing: 8) {
                            // container
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Describe your image...", text: $prompt, axis: .vertical)
                                    .lineLimit(1...4)
                                    .foregroundColor(.white)

                                HStack(spacing: 10) {
                                    // left controls
                                    HStack(spacing: 10) {
                                        Button { /* plus menu in future */ } label: {
                                            controlPill(icon: "plus", title: nil)
                                        }

                                        // Type menu (Video / Image)
                                        Menu {
                                            Section(header: Text("Type")) {
                                                Button(action: { mediaType = .video }) { HStack { Image(systemName: "video.fill"); Text("Video"); Spacer() } }
                                                Button(action: { mediaType = .image }) { HStack { Image(systemName: "photo"); Text("Image"); Spacer() } }
                                            }
                                        } label: {
                                            controlPill(icon: mediaType == .image ? "photo" : "video.fill", title: mediaType.rawValue)
                                        }

                                        // Aspect ratio menu
                                        Menu {
                                            Section(header: Text("Aspect Ratio")) {
                                                Button(action: { aspect = .square }) { HStack { Image(systemName: "square"); Text("Square"); Spacer() } }
                                                Button(action: { aspect = .landscape }) { HStack { Image(systemName: "rectangle"); Text("Landscape"); Spacer() } }
                                                Button(action: { aspect = .portrait }) { HStack { Image(systemName: "rectangle.portrait"); Text("Portrait"); Spacer() } }
                                            }
                                        } label: { controlPill(icon: "slider.horizontal.3", title: nil) }
                                    }
                                    Spacer()
                                    // Right model pill + send
                                    HStack(spacing: 10) {
                                        Menu {
                                            Section(header: Text("Image Model")) {
                                                Button { modelName = "GPT 4o" } label: { modelRow(name: "GPT 4o", tokens: 100) }
                                                Button { modelName = "Flux" } label: { modelRow(name: "Flux", tokens: 50) }
                                                Button { modelName = "Flux Schnell" } label: { modelRow(name: "Flux Schnell", tokens: 10) }
                                            }
                                            Section(header: Text("Video Model")) {
                                                Button { modelName = "Veo 3" } label: { modelRow(name: "Veo 3", tokens: 15000) }
                                                Button { modelName = "Kling 2.1" } label: { modelRow(name: "Kling 2.1", tokens: 1000) }
                                            }
                                        } label: { controlPill(icon: nil, title: modelName) }
                                        Button(action: { generate() }) {
                                            Image(systemName: isSending ? "hourglass" : "arrow.up.circle.fill")
                                                .foregroundColor(.white)
                                                .font(.title2)
                                        }
                                        .disabled(isSending)
                                    }
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        }
                        , alignment: .bottom
                    )
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showVideoGen) {
            VideoGenerationView(
                prompt: pendingVideoPrompt,
                aspect: aspectString(pendingVideoAspect),
                modelName: pendingVideoModel
            )
        }
    }

    private func studioImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: (UIScreen.main.bounds.width - 16*2 - 12)/2, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }

    private func controlPill(icon: String?, title: String?) -> some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon) }
            if let title { Text(title) }
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }

    @ViewBuilder
    private func modelRow(name: String, tokens: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text(name)
            Spacer()
            TokenBadge(count: tokens)
        }
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.16)))
        .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
    }

    // Small token badge for model menu rows
    private struct TokenBadge: View {
        let count: Int
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.caption2)
                Text("\(count)")
                    .font(.caption2)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.18)))
            .foregroundColor(.white)
        }
    }

    private func generate() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        Task {
            defer { isSending = false }
            do {
                switch mediaType {
                case .image:
                    let size: String
                    switch aspect {
                    case .square: size = "1024x1024"
                    case .landscape: size = "1280x720"
                    case .portrait: size = "720x1280"
                    }
                    let data = try await APIRegistry.shared.generateImage(prompt: prompt, size: size)
                    if let ui = UIImage(data: data) {
                        items.insert(.image(ui), at: 0)
                    }
                case .video:
                    // Present separate generation screen
                    pendingVideoPrompt = prompt
                    pendingVideoAspect = aspect
                    pendingVideoModel = modelName
                    showVideoGen = true
                }
            } catch {
                print("Studio generation error: \(error.localizedDescription)")
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

    private func aspectString(_ a: Aspect) -> String {
        switch a { case .square: return "square"; case .landscape: return "landscape"; case .portrait: return "portrait" }
    }
}

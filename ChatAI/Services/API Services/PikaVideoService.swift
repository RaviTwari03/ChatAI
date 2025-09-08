//
//  PikaVideoService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 08/09/25.
//

import Foundation

final class PikaVideoService: VideoService {
    let provider: VideoProvider = .pika

    private var apiKey: String {
        get throws {
            try APIManager.shared.getValidatedPikaKey()
        }
    }

    // MARK: - API endpoints (placeholder)
    // Note: Replace with Pika's actual endpoints when enabling real calls
    private let baseURL = URL(string: "https://api.pika.art/v2")!

    // MARK: - Public
    func startVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoJob {
        _ = try apiKey // Validate key is present
        // For now, return a queued job stub. We'll wire real API next.
        let jobId = UUID().uuidString
        return VideoJob(
            id: jobId,
            provider: provider,
            prompt: prompt,
            status: .queued,
            durationSeconds: options.durationSeconds,
            width: options.width,
            height: options.height
        )
    }

    func startVideoFromImage(prompt: String, imageData: Data, mimeType: String, options: VideoGenerationOptions) async throws -> VideoJob {
        _ = try apiKey
        let jobId = UUID().uuidString
        return VideoJob(
            id: jobId,
            provider: provider,
            prompt: prompt,
            status: .queued,
            durationSeconds: options.durationSeconds,
            width: options.width,
            height: options.height
        )
    }

    func getStatus(jobId: String) async throws -> VideoJob {
        _ = try apiKey
        // Placeholder: return processing with dummy progress
        return VideoJob(
            id: jobId,
            provider: provider,
            prompt: "",
            status: .processing(progress: 0.2),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func cancel(jobId: String) async throws {
        _ = try apiKey
        // Placeholder: no-op for now
    }
}

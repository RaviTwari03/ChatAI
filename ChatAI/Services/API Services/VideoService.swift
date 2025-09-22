//
//  VideoService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 08/09/25.
//

import Foundation

public enum VideoProvider: String, Codable, CaseIterable {
    case pika
    case veo
    // case luma
    // case runway
    // case stability
}

public enum VideoStatus: Equatable, Codable {
    case queued
    case processing(progress: Double?)
    case completed(url: URL)
    case failed(error: String)
}

public struct VideoJob: Codable, Identifiable, Equatable {
    public let id: String
    public let provider: VideoProvider
    public var prompt: String
    public var status: VideoStatus
    public var createdAt: Date
    public var updatedAt: Date
    public var durationSeconds: Int?
    public var width: Int?
    public var height: Int?
    public var storagePath: String?

    public init(id: String, provider: VideoProvider, prompt: String, status: VideoStatus, createdAt: Date = Date(), updatedAt: Date = Date(), durationSeconds: Int? = nil, width: Int? = nil, height: Int? = nil, storagePath: String? = nil) {
        self.id = id
        self.provider = provider
        self.prompt = prompt
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.durationSeconds = durationSeconds
        self.width = width
        self.height = height
        self.storagePath = storagePath
    }
}

public struct VideoGenerationOptions {
    public var durationSeconds: Int
    public var width: Int
    public var height: Int
    public var seed: Int?

    public init(durationSeconds: Int = 4, width: Int = 720, height: Int = 720, seed: Int? = nil) {
        self.durationSeconds = durationSeconds
        self.width = width
        self.height = height
        self.seed = seed
    }
}

public protocol VideoService {
    var provider: VideoProvider { get }
    func startVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoJob
    func startVideoFromImage(prompt: String, imageData: Data, mimeType: String, options: VideoGenerationOptions) async throws -> VideoJob
    func getStatus(jobId: String) async throws -> VideoJob
    func cancel(jobId: String) async throws
}

public enum VideoServiceError: LocalizedError {
    case notImplemented
    case missingAPIKey(String)
    case badRequest(String)
    case badStatus(Int, String)
    case network(Error)
    case decoding(Error)

    public var errorDescription: String? {
        switch self {
        case .notImplemented: return "Not implemented"
        case .missingAPIKey(let k): return "Missing API key: \(k)"
        case .badRequest(let msg): return "Bad request: \(msg)"
        case .badStatus(let code, let body): return "Unexpected status: \(code) — \(body)"
        case .network(let err): return err.localizedDescription
        case .decoding(let err): return "Decoding error: \(err.localizedDescription)"
        }
    }
}

public enum VideoServiceFactory {
    public static func make(_ provider: VideoProvider) -> VideoService {
        switch provider {
        case .pika: return PikaVideoService()
        case .veo: return VeoVideoService()
        }
    }
}

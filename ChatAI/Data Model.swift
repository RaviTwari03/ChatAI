//
//  Data Model.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import Foundation

struct AppUser: Identifiable, Codable {
    var id: UUID
    var email: String
    var username: String?
    var displayName: String?
    var avatarURL: URL?
    var status: String
    var createdAt: Date
    var updatedAt: Date
    var devices: [UserDevice] = []
}

struct UserDevice: Identifiable, Codable {
    var id: UUID
    var userID: UUID
    var platform: String
    var pushToken: String?
    var lastSeenAt: Date?
    var createdAt: Date
}

struct Conversation: Identifiable, Codable {
    var id: UUID
    var title: String?
    var kind: String // "direct" | "group" | "assistant"
    var isArchived: Bool
    var createdBy: UUID
    var createdAt: Date
    var updatedAt: Date
    var members: [ConversationMember] = []
}

struct ConversationMember: Codable, Identifiable {
    var id: UUID { userID }
    var conversationID: UUID
    var userID: UUID
    var role: String // "owner", "admin", "member", "assistant"
    var joinedAt: Date
    var lastReadMessageID: UUID?
}

struct Message: Identifiable, Codable {
    var id: UUID
    var conversationID: UUID
    var senderID: UUID?
    var senderType: String // "user" | "assistant" | "system"
    var text: String?
    var metadata: [String: AnyCodable] // e.g., model, tokens
    var replyToMessageID: UUID?
    var createdAt: Date
    var attachments: [MessageAttachment] = []
    var reactions: [MessageReaction] = []
}

struct MessageReaction: Identifiable, Codable {
    var id: UUID
    var messageID: UUID
    var userID: UUID
    var reactionType: String
    var createdAt: Date
}

struct MessageAttachment: Identifiable, Codable {
    var id: UUID
    var messageID: UUID
    var kind: String // "file", "image", "audio", "video", "weblink", "transcript"
    var url: URL?
    var filename: String?
    var mimeType: String?
    var byteSize: Int64?
    var sha256: String?
    var meta: [String: AnyCodable]
    var createdAt: Date
    var linkPreview: LinkPreview?
    var audioTranscript: AudioTranscript?
}

struct LinkPreview: Codable {
    var attachmentID: UUID
    var siteName: String?
    var title: String?
    var description: String?
    var imageURL: URL?
}

struct AudioTranscript: Codable {
    var attachmentID: UUID
    var language: String?
    var text: String
    var createdAt: Date
}

struct Prompt: Identifiable, Codable {
    var id: UUID
    var ownerID: UUID
    var title: String
    var body: String
    var tags: [String]
    var isPublic: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct PromptFavorite: Codable {
    var userID: UUID
    var promptID: UUID
    var createdAt: Date
}

struct MediaAsset: Identifiable, Codable {
    var id: UUID
    var ownerID: UUID
    var kind: String // "image", "audio", "video", "file"
    var url: URL
    var filename: String?
    var mimeType: String?
    var byteSize: Int64?
    var meta: [String: AnyCodable]
    var createdAt: Date
}

struct MediaFavorite: Codable {
    var userID: UUID
    var assetID: UUID
    var createdAt: Date
}

struct UserSettings: Codable {
    var userID: UUID
    var preferences: [String: AnyCodable] // theme, markdown, voice_input, etc.
    var updatedAt: Date
}

struct ConversationSettings: Codable {
    var conversationID: UUID
    var defaults: [String: AnyCodable] // model, system_prompt, max_context_messages
    var updatedAt: Date
}

struct Feature: Identifiable, Codable {
    var id: UUID
    var key: String
    var description: String?
}

struct Plan: Identifiable, Codable {
    var id: UUID
    var code: String
    var name: String
    var description: String?
    var priceCents: Int
    var currency: String
    var isActive: Bool
    var createdAt: Date
}

struct PlanEntitlement: Codable {
    var planID: UUID
    var featureID: UUID
    var limitPeriod: String // "monthly" etc
    var quantity: Int64?
    var metadata: [String: AnyCodable]
}

struct Subscription: Identifiable, Codable {
    var id: UUID
    var userID: UUID
    var planID: UUID
    var provider: String
    var providerSubscriptionID: String?
    var status: String // "active", "trialing", etc.
    var currentPeriodStart: Date?
    var currentPeriodEnd: Date?
    var canceledAt: Date?
    var createdAt: Date
}

struct UserEntitlement: Identifiable, Codable {
    var id: UUID
    var userID: UUID
    var featureID: UUID
    var enabled: Bool
    var limitPeriod: String
    var quantity: Int64?
    var reason: String?
    var startsAt: Date?
    var endsAt: Date?
}

struct FeatureUsage: Identifiable, Codable {
    var id: UUID
    var userID: UUID
    var featureID: UUID
    var occurredAt: Date
    var quantity: Int64
    var metadata: [String: AnyCodable]
}

struct FeatureFlag: Codable {
    var key: String
    var description: String?
    var enabled: Bool
    var rules: [String: AnyCodable]
    var updatedAt: Date
}

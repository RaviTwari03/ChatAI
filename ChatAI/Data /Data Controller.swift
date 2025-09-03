//
//  Data Controller.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import Foundation

final class DataController {
    static let shared = DataController()

    private init() {
        // Private initializer to enforce singleton
    }

    // MARK: - Sample Data Storage
    private var users: [UUID: AppUser] = [:]
    private var conversations: [UUID: Conversation] = [:]
    private var messages: [UUID: Message] = [:]
    private var prompts: [UUID: Prompt] = [:]
    private var plans: [UUID: Plan] = [:]
    private var subscriptions: [UUID: Subscription] = [:]
    private var features: [UUID: Feature] = [:]
    
    // MARK: - User Management
    func addUser(_ user: AppUser) {
        users[user.id] = user
    }

    func getUser(by id: UUID) -> AppUser? {
        return users[id]
    }
    
    func updateUser(_ user: AppUser) {
        users[user.id] = user
    }
    
    func removeUser(by id: UUID) {
        users.removeValue(forKey: id)
    }
    
    func getAllUsers() -> [AppUser] {
        return Array(users.values)
    }
    
    // MARK: - Conversation Management
    func addConversation(_ conversation: Conversation) {
        conversations[conversation.id] = conversation
    }
    
    func getConversation(by id: UUID) -> Conversation? {
        return conversations[id]
    }
    
    func updateConversation(_ conversation: Conversation) {
        conversations[conversation.id] = conversation
    }
    
    func removeConversation(by id: UUID) {
        conversations.removeValue(forKey: id)
    }
    
    func getAllConversations() -> [Conversation] {
        return Array(conversations.values)
    }
    
    // MARK: - Message Management
    func addMessage(_ message: Message) {
        messages[message.id] = message
    }
    
    func getMessage(by id: UUID) -> Message? {
        return messages[id]
    }
    
    func updateMessage(_ message: Message) {
        messages[message.id] = message
    }
    
    func removeMessage(by id: UUID) {
        messages.removeValue(forKey: id)
    }
    
    func getMessagesForConversation(conversationId: UUID) -> [Message] {
        return messages.values.filter { $0.conversationID == conversationId }
    }
    
    // MARK: - Prompt Management
    func addPrompt(_ prompt: Prompt) {
        prompts[prompt.id] = prompt
    }
    
    func getPrompt(by id: UUID) -> Prompt? {
        return prompts[id]
    }
    
    func getAllPrompts() -> [Prompt] {
        return Array(prompts.values)
    }
    
    // MARK: - Plan Management
    func addPlan(_ plan: Plan) {
        plans[plan.id] = plan
    }
    
    func getPlan(by id: UUID) -> Plan? {
        return plans[id]
    }
    
    func getAllPlans() -> [Plan] {
        return Array(plans.values)
    }
    
    // MARK: - Subscription Management
    func addSubscription(_ subscription: Subscription) {
        subscriptions[subscription.id] = subscription
    }
    
    func getSubscription(by id: UUID) -> Subscription? {
        return subscriptions[id]
    }
    
    func getSubscriptionsForUser(userId: UUID) -> [Subscription] {
        return subscriptions.values.filter { $0.userID == userId }
    }
    
    // MARK: - Feature Management
    func addFeature(_ feature: Feature) {
        features[feature.id] = feature
    }
    
    func getFeature(by id: UUID) -> Feature? {
        return features[id]
    }
    
    func getAllFeatures() -> [Feature] {
        return Array(features.values)
    }
    
    // Additional utility functions can be added here as needed.
}

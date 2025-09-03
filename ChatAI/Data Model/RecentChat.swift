import Foundation

struct RecentChat: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var userId: String?

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), userId: String? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.userId = userId
    }
}

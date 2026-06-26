import Foundation
import SwiftData

@Model
final class RecoveryLetter {
    var id: UUID
    var createdAt: Date
    var content: String

    init(content: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.createdAt = createdAt
        self.content = content
    }
}

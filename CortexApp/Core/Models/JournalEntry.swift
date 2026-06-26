import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var createdAt: Date
    var text: String
    var mood: Int

    init(text: String, mood: Int, createdAt: Date = Date()) {
        self.id = UUID()
        self.createdAt = createdAt
        self.text = text
        self.mood = mood
    }
}

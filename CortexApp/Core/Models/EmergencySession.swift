import Foundation
import SwiftData

@Model
final class EmergencySession {
    var id: UUID
    var startedAt: Date
    var completedAt: Date
    var movementCount: Int
    var completed: Bool

    init(
        startedAt: Date,
        completedAt: Date = Date(),
        movementCount: Int,
        completed: Bool = true
    ) {
        self.id = UUID()
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.movementCount = movementCount
        self.completed = completed
    }
}

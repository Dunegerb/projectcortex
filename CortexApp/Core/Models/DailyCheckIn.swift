import Foundation
import SwiftData

enum CheckInStatus: String, Codable, Equatable {
    case aligned
    case slip

    var title: String {
        switch self {
        case .aligned: return "Dia alinhado"
        case .slip: return "Deslize registrado"
        }
    }
}

@Model
final class DailyCheckIn {
    var id: UUID
    var date: Date
    var statusRaw: String
    var note: String

    init(date: Date = Date(), status: CheckInStatus, note: String = "") {
        self.id = UUID()
        self.date = date
        self.statusRaw = status.rawValue
        self.note = note
    }

    var status: CheckInStatus {
        get { CheckInStatus(rawValue: statusRaw) ?? .aligned }
        set { statusRaw = newValue.rawValue }
    }
}

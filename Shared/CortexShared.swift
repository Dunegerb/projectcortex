import Foundation

public enum CortexShared {
    public static var appGroup: String {
        (Bundle.main.object(forInfoDictionaryKey: "CortexAppGroup") as? String) ?? "group.com.seudominio.cortex"
    }
    public static let snapshotKey = "cortex.widget.snapshot"
    public static let emergencyURL = URL(string: "cortex://emergency")!
}

public struct CortexWidgetSnapshot: Codable, Equatable {
    public var alterName: String
    public var recoveryScore: Double
    public var neuralState: String
    public var currentDay: Int
    public var cycleStartDate: Date?
    public var targetDays: Int?
    public var updatedAt: Date

    public init(
        alterName: String,
        recoveryScore: Double,
        neuralState: String,
        currentDay: Int,
        cycleStartDate: Date? = nil,
        targetDays: Int? = nil,
        updatedAt: Date = Date()
    ) {
        self.alterName = alterName
        self.recoveryScore = recoveryScore
        self.neuralState = neuralState
        self.currentDay = currentDay
        self.cycleStartDate = cycleStartDate
        self.targetDays = targetDays
        self.updatedAt = updatedAt
    }

    public static let placeholder = CortexWidgetSnapshot(
        alterName: "Atlas",
        recoveryScore: 0.48,
        neuralState: "EM FLUXO",
        currentDay: 18,
        cycleStartDate: Calendar.current.date(byAdding: .day, value: -17, to: Date()),
        targetDays: 90
    )
}

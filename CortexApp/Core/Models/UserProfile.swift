import Foundation
import SwiftData

enum Archetype: String, Codable, CaseIterable, Identifiable, Hashable {
    case builder
    case warrior
    case strategist
    case sage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .builder: return "Construtor"
        case .warrior: return "Guerreiro"
        case .strategist: return "Estrategista"
        case .sage: return "Sábio"
        }
    }

    var subtitle: String {
        switch self {
        case .builder: return "Construção, negócios e projetos"
        case .warrior: return "Disciplina, corpo e resistência"
        case .strategist: return "Estudos, carreira e execução"
        case .sage: return "Calma, espiritualidade e autodomínio"
        }
    }

    var symbol: String {
        switch self {
        case .builder: return "hammer.fill"
        case .warrior: return "shield.lefthalf.filled"
        case .strategist: return "scope"
        case .sage: return "leaf.fill"
        }
    }
}

@Model
final class UserProfile {
    var id: UUID
    var realName: String
    var alterName: String
    var archetypeRaw: String
    var mission: String
    var manifesto: String
    var lossesJSON: String
    var startDate: Date
    var targetDays: Int
    var dailyUsageMinutes: Int
    var onboardingCompleted: Bool
    var shieldEnabled: Bool
    var pendingShieldDisableDate: Date?
    var masterModeEnabled: Bool
    var day30Claimed: Bool
    var day60Claimed: Bool
    var day90Claimed: Bool
    var createdAt: Date

    init(
        realName: String,
        alterName: String,
        archetype: Archetype,
        mission: String,
        manifesto: String,
        losses: [String],
        startDate: Date = Date(),
        targetDays: Int = 90,
        dailyUsageMinutes: Int = 45,
        onboardingCompleted: Bool = true,
        shieldEnabled: Bool = false
    ) {
        self.id = UUID()
        self.realName = realName
        self.alterName = alterName
        self.archetypeRaw = archetype.rawValue
        self.mission = mission
        self.manifesto = manifesto
        self.lossesJSON = (try? String(data: JSONEncoder().encode(losses), encoding: .utf8)) ?? "[]"
        self.startDate = startDate
        self.targetDays = targetDays
        self.dailyUsageMinutes = dailyUsageMinutes
        self.onboardingCompleted = onboardingCompleted
        self.shieldEnabled = shieldEnabled
        self.pendingShieldDisableDate = nil
        self.masterModeEnabled = false
        self.day30Claimed = false
        self.day60Claimed = false
        self.day90Claimed = false
        self.createdAt = Date()
    }

    var archetype: Archetype {
        get { Archetype(rawValue: archetypeRaw) ?? .strategist }
        set { archetypeRaw = newValue.rawValue }
    }

    var losses: [String] {
        guard let data = lossesJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    func updateLosses(_ losses: [String]) {
        lossesJSON = (try? String(data: JSONEncoder().encode(losses), encoding: .utf8)) ?? "[]"
    }
}

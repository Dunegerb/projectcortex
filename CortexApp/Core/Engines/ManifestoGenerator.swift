import Foundation

struct ManifestoGenerator {
    static func make(realName: String, alterName: String, mission: String) -> String {
        let identity = alterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Minha melhor versão" : alterName
        let person = realName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mim" : realName
        let destination = mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "uma vida coerente com meus valores" : mission

        return """
        Eu, \(identity), assumo responsabilidade pelas escolhas de \(person).

        Minha energia será direcionada para:
        \(destination).

        Nos próximos 90 dias, praticarei autocontrole, aprenderei com os deslizes e retornarei ao plano sem vergonha.
        """
    }
}

import Foundation
import LocalAuthentication

struct BiometricService {
    static func confirmCommitment() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Confirmar seu compromisso pessoal no Projeto Córtex"
            )
        } catch {
            return false
        }
    }
}

import SwiftUI

struct CognitiveChallenge {
    let left: Int
    let right: Int
    var answer: Int { left + right }

    static func random() -> CognitiveChallenge {
        CognitiveChallenge(left: Int.random(in: 12...49), right: Int.random(in: 11...39))
    }
}

struct CognitiveStepView: View {
    let challenge: CognitiveChallenge
    let onComplete: () -> Void

    @State private var response = ""
    @State private var isIncorrect = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("ATIVE O RACIOCÍNIO")
                .cortexTextStyle(.caption1)
                .foregroundStyle(CortexTheme.muted)
            Text("\(challenge.left) + \(challenge.right) = ?")
                .cortexTextStyle(.largeTitle)
                .monospacedDigit()
            TextField("Resposta", text: $response)
                .cortexNativeNumberPad()
                .multilineTextAlignment(.center)
                .cortexTextStyle(.title1)
                .padding(18)
                .background(CortexTheme.quaternary, in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 42)
            if isIncorrect {
                Text("Tente novamente, sem pressa.")
                    .foregroundStyle(.orange)
            }
            Button("CONFIRMAR") {
                if Int(response) == challenge.answer {
                    HapticEngine.shared.softPulse()
                    onComplete()
                } else {
                    isIncorrect = true
                    HapticEngine.shared.impactFallback(.rigid)
                }
            }
            .buttonStyle(CortexPrimaryButtonStyle())
            .disabled(response.isEmpty)
            Spacer()
            Text("Uma tarefa simples cria distância entre a urgência e a decisão.")
                .cortexTextStyle(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .padding(24)
        .cortexFadeIn()
    }
}

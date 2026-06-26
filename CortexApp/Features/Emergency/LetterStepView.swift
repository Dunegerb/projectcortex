import SwiftUI

struct LetterStepView: View {
    let alterName: String
    let message: String
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("UMA MENSAGEM DO SEU MOMENTO DE CLAREZA")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(CortexTheme.muted)
                Text("O que \(alterName) faria agora?")
                    .cortexTextStyle(.largeTitle)
                Text(message)
                    .cortexTextStyle(.title3)
                    .lineSpacing(8)
                    .padding(22)
                    .background(CortexTheme.secondary, in: RoundedRectangle(cornerRadius: 22))
                Text("Leia devagar. A mensagem veio de você, não do aplicativo.")
                    .foregroundStyle(.secondary)
                Button(action: onComplete) {
                    Text("TRANSFORMAR EM AÇÃO").frame(maxWidth: .infinity)
                }
                .buttonStyle(CortexPrimaryButtonStyle())
            }
            .padding(24)
        }
        .cortexFadeIn()
    }
}

import SwiftUI

struct MovementStepView: View {
    let alterName: String
    let onComplete: (Int) -> Void

    @StateObject private var motion = MotionActivityService()
    @State private var seconds = 20
    private let target = 12
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 72))
                .foregroundStyle(CortexTheme.ice)
            Text("TRANSMUTAÇÃO ATIVA")
                .cortexTextStyle(.caption1)
                .foregroundStyle(CortexTheme.muted)
            Text("\(alterName), converta a energia em movimento.")
                .cortexTextStyle(.title1)
                .multilineTextAlignment(.center)
            Text("Faça flexões, agachamentos ou caminhe rapidamente com o aparelho seguro. Pare se sentir dor, tontura ou mal-estar.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ProgressView(value: Double(min(motion.movementCount, target)), total: Double(target))
                .tint(CortexTheme.moss)
                .padding(.horizontal, 30)
            Text("Movimentos detectados: \(motion.movementCount)/\(target)")
                .cortexTextStyle(.headline).monospacedDigit()
            if !motion.isAvailable {
                Text("O sensor de movimento não está disponível. Use a confirmação manual quando o tempo terminar.")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button {
                motion.stop()
                onComplete(motion.movementCount)
            } label: {
                Text(motion.movementCount >= target ? "ATIVIDADE CONCLUÍDA" : "CONCLUÍ MANUALMENTE (\(seconds)s)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CortexPrimaryButtonStyle())
            .disabled(motion.movementCount < target && seconds > 0)
            .opacity(motion.movementCount < target && seconds > 0 ? 0.35 : 1)
        }
        .padding(24)
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .onReceive(timer) { _ in
            if seconds > 0 { seconds -= 1 }
            if motion.movementCount >= target {
                motion.stop()
            }
        }
        .cortexFadeIn()
    }
}

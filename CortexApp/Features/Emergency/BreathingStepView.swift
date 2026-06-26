import SwiftUI

struct BreathingStepView: View {
    let onComplete: () -> Void

    @State private var elapsed = 0
    @State private var scale: CGFloat = 0.58
    private let totalSeconds = 42
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var cycleSecond: Int { elapsed % 14 }

    private var instruction: String {
        switch cycleSecond {
        case 0...3: return "Inspire"
        case 4...7: return "Segure"
        default: return "Expire"
        }
    }

    private var instructionRemaining: Int {
        switch cycleSecond {
        case 0...3: return 4 - cycleSecond
        case 4...7: return 8 - cycleSecond
        default: return 14 - cycleSecond
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("RESPIRAÇÃO GUIADA")
                .cortexTextStyle(.caption1)
                .foregroundStyle(CortexTheme.muted)
            Spacer()
            ZStack {
                Circle()
                    .stroke(CortexTheme.ice.opacity(0.18), lineWidth: 2)
                    .frame(width: 280, height: 280)
                Circle()
                    .fill(CortexTheme.ice.opacity(0.26))
                    .frame(width: 230, height: 230)
                    .scaleEffect(scale)
                    .blur(radius: 3)
                VStack(spacing: 6) {
                    Text(instruction)
                        .cortexTextStyle(.largeTitle)
                    Text("\(instructionRemaining)")
                        .cortexTextStyle(.title1).monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            Text("Respire com o círculo. Não tente expulsar o impulso; apenas deixe a intensidade cair.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 28)
            Spacer()
            Text("\(max(totalSeconds - elapsed, 0))s")
                .cortexTextStyle(.caption1).monospacedDigit()
                .foregroundStyle(CortexTheme.muted)
        }
        .padding(24)
        .onAppear { updateScale() }
        .onReceive(timer) { _ in
            guard elapsed < totalSeconds else { return }
            elapsed += 1
            updateScale()
            if elapsed >= totalSeconds { onComplete() }
        }
        .cortexFadeIn()
    }

    private func updateScale() {
        let target: CGFloat
        let duration: Double
        switch cycleSecond {
        case 0...3:
            target = 1.0
            duration = 4
        case 4...7:
            target = 1.0
            duration = 0.4
        default:
            target = 0.58
            duration = 6
        }
        withAnimation(.easeInOut(duration: duration)) { scale = target }
    }
}

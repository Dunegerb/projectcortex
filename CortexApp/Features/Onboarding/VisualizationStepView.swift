import SwiftUI

struct VisualizationStepView: View {
    let alterName: String
    let mission: String
    let onContinue: () -> Void

    @State private var secondsRemaining = 15
    @State private var expanded = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(CortexTheme.ice.opacity(0.18), lineWidth: 2)
                    .frame(width: 240, height: 240)
                Circle()
                    .fill(CortexTheme.ice.opacity(0.22))
                    .frame(width: expanded ? 200 : 112, height: expanded ? 200 : 112)
                    .blur(radius: 5)
            }
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: expanded)

            Text("Feche os olhos.")
                .cortexTextStyle(.largeTitle)
            Text("Imagine \(alterName) vivendo a realidade de:\n\n\(mission)")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text("\(secondsRemaining)")
                .cortexTextStyle(.largeTitle)
                .monospacedDigit()
                .foregroundStyle(CortexTheme.ice)

            Spacer()
            Button(action: onContinue) {
                Text("CONTINUAR").frame(maxWidth: .infinity)
            }
            .buttonStyle(CortexPrimaryButtonStyle())
            .disabled(secondsRemaining > 0)
            .opacity(secondsRemaining > 0 ? 0.25 : 1)
            .padding(24)
        }
        .onAppear { expanded = true; HapticEngine.shared.softPulse() }
        .onReceive(timer) { _ in
            guard secondsRemaining > 0 else { return }

            secondsRemaining -= 1

            if secondsRemaining == 0 {
                HapticEngine.shared.softPulse()
                onContinue()
            } else if secondsRemaining % 3 == 0 {
                HapticEngine.shared.softPulse()
            }
        }
        .cortexFadeIn()
    }
}

import SwiftUI

struct ContractStepView: View {
    let manifesto: String
    @Binding var signed: Bool
    let onContinue: () -> Void

    @State private var biometricConfirmed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("CONTRATO DIGITAL")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(CortexTheme.muted)
                Text("Um compromisso com seus valores")
                    .cortexTextStyle(.largeTitle)
                Text(manifesto)
                    .cortexTextStyle(.body)
                    .lineSpacing(7)
                    .padding(20)
                    .background(CortexTheme.secondary, in: RoundedRectangle(cornerRadius: 20))

                PressAndHoldCommitButton(isComplete: $signed)

                Button {
                    Task { biometricConfirmed = await BiometricService.confirmCommitment() }
                } label: {
                    Label(
                        biometricConfirmed ? "Compromisso confirmado" : "Confirmar com Face ID ou código (opcional)",
                        systemImage: biometricConfirmed ? "checkmark.seal.fill" : "faceid"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CortexTheme.ice)

                Button(action: onContinue) {
                    Text("VESTIR A ARMADURA").frame(maxWidth: .infinity)
                }
                .buttonStyle(CortexPrimaryButtonStyle())
                .disabled(!signed)
                .opacity(signed ? 1 : 0.3)
            }
            .padding(24)
        }
        .cortexFadeIn()
    }
}

private struct PressAndHoldCommitButton: View {
    @Binding var isComplete: Bool
    @State private var isPressing = false
    @State private var progress = 0.0
    @State private var startedAt: Date?
    @State private var timer: Timer?
    @State private var lastHapticStage = -1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(CortexTheme.secondary)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 20)
                    .fill(CortexTheme.moss)
                    .frame(width: geometry.size.width * progress)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            VStack(spacing: 4) {
                Text(isComplete ? "COMPROMISSO REGISTRADO" : "PRESSIONE E MANTENHA")
                    .cortexTextStyle(.headline)
                Text(isComplete ? "" : "\(Int((10 * (1 - progress)).rounded(.up))) segundos")
                    .cortexTextStyle(.caption1).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 72)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginPressing() }
                .onEnded { _ in endPressing() }
        )
        .accessibilityLabel("Pressione e mantenha por dez segundos")
        .onDisappear { timer?.invalidate() }
    }

    private func beginPressing() {
        guard !isComplete, !isPressing else { return }
        isPressing = true
        startedAt = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let startedAt else { return }
            let elapsed = Date().timeIntervalSince(startedAt)
            progress = min(elapsed / 10, 1)
            let stage = Int(progress * 5)
            if stage != lastHapticStage {
                lastHapticStage = stage
                HapticEngine.shared.ramp(level: max(progress, 0.15))
            }
            if progress >= 1 {
                isComplete = true
                isPressing = false
                timer?.invalidate()
                HapticEngine.shared.victory()
            }
        }
    }

    private func endPressing() {
        guard !isComplete else { return }
        isPressing = false
        timer?.invalidate()
        withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
        lastHapticStage = -1
    }
}

import SwiftData
import SwiftUI

private enum EmergencyPhase: Int, CaseIterable {
    case breathing
    case cognitive
    case letter
    case movement
    case complete
}

struct EmergencyFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile
    @Query(sort: \RecoveryLetter.createdAt, order: .reverse) private var letters: [RecoveryLetter]

    @State private var phase: EmergencyPhase = .breathing
    @State private var startedAt = Date()
    @State private var movementCount = 0
    private let challenge = CognitiveChallenge.random()

    var body: some View {
        ZStack {
            CortexTheme.base.ignoresSafeArea()

            switch phase {
            case .breathing:
                BreathingStepView { move(to: .cognitive) }
            case .cognitive:
                CognitiveStepView(challenge: challenge) { move(to: .letter) }
            case .letter:
                LetterStepView(
                    alterName: profile.alterName,
                    message: letters.first?.content ?? profile.manifesto
                ) { move(to: .movement) }
            case .movement:
                MovementStepView(alterName: profile.alterName) { count in
                    movementCount = count
                    completeSession()
                }
            case .complete:
                completionView
            }
        }
        .interactiveDismissDisabled(phase != .complete)
        .onAppear {
            startedAt = Date()
            HapticEngine.shared.heartbeat(bpm: 60, duration: 6)
        }
    }

    private var completionView: some View {
        VStack(spacing: 26) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(CortexTheme.moss)
            Text("Você atravessou a onda.")
                .cortexTextStyle(.largeTitle)
                .multilineTextAlignment(.center)
            Text("O objetivo não era lutar com o pensamento, mas criar tempo entre impulso e ação.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("VOLTAR AO MUNDO REAL") { dismiss() }
                .buttonStyle(CortexPrimaryButtonStyle())
        }
        .padding(28)
        .cortexFadeIn()
    }

    private func move(to next: EmergencyPhase) {
        withAnimation(.easeInOut(duration: 0.75)) { phase = next }
    }

    private func completeSession() {
        modelContext.insert(EmergencySession(
            startedAt: startedAt,
            completedAt: Date(),
            movementCount: movementCount
        ))
        try? modelContext.save()
        HapticEngine.shared.victory()
        move(to: .complete)
    }
}

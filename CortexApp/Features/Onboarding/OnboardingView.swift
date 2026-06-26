import SwiftData
import SwiftUI

struct OnboardingDraft {
    var realName = ""
    var losses = ["", "", ""]
    var alterName = ""
    var archetype: Archetype = .strategist
    var mission = ""
    var dailyUsageMinutes = 45
    var letter = ""
    var shieldEnabled = false

    var manifesto: String {
        ManifestoGenerator.make(realName: realName, alterName: alterName, mission: mission)
    }
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var draft = OnboardingDraft()
    @State private var contractSigned = false

    var body: some View {
        ZStack {
            CortexTheme.base.ignoresSafeArea()

            Group {
                switch step {
                case 0:
                    MirrorStepView(draft: $draft) { advance() }
                case 1:
                    ForgeStepView(draft: $draft) { advance() }
                case 2:
                    VisualizationStepView(alterName: draft.alterName, mission: draft.mission) { advance() }
                case 3:
                    ContractStepView(
                        manifesto: draft.manifesto,
                        signed: $contractSigned,
                        onContinue: { advance() }
                    )
                default:
                    LockdownStepView(draft: $draft, onFinish: finish)
                }
            }
            .transition(.opacity)
            .id(step)
        }
        .animation(.easeInOut(duration: 0.8), value: step)
    }

    private func advance() {
        withAnimation { step += 1 }
    }

    private func finish() {
        let profile = UserProfile(
            realName: draft.realName.trimmingCharacters(in: .whitespacesAndNewlines),
            alterName: draft.alterName.trimmingCharacters(in: .whitespacesAndNewlines),
            archetype: draft.archetype,
            mission: draft.mission.trimmingCharacters(in: .whitespacesAndNewlines),
            manifesto: draft.manifesto,
            losses: draft.losses.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            dailyUsageMinutes: draft.dailyUsageMinutes,
            shieldEnabled: draft.shieldEnabled
        )
        modelContext.insert(profile)
        modelContext.insert(RecoveryLetter(content: draft.letter.isEmpty ? draft.manifesto : draft.letter))
        UserDefaults.standard.set(draft.shieldEnabled, forKey: "cortex.shield.enabled")
        try? modelContext.save()
        HapticEngine.shared.victory()
    }
}

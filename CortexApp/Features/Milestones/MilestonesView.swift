import SwiftData
import SwiftUI

struct MilestonesView: View {
    @Bindable var profile: UserProfile
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @StateObject private var health = HealthKitService.shared
    @State private var isVerifyingWorkout = false
    @State private var workoutMessage: String?

    private var snapshot: RecoverySnapshot {
        RecoveryEngine.snapshot(profile: profile, checkIns: checkIns)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    milestone30
                    milestone60
                    milestone90
                    Text("Os marcos são rituais de reflexão e esforço. Eles não comprovam mudanças clínicas nem substituem acompanhamento profissional.")
                        .cortexTextStyle(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding(18)
            }
            .background(CortexTheme.background.ignoresSafeArea())
            .navigationTitle("Marcos")
        }
    }

    private var milestone30: some View {
        milestoneCard(
            day: 30,
            title: "O Despertar",
            subtitle: "Prova de retorno",
            unlocked: snapshot.currentDay >= 30,
            claimed: profile.day30Claimed
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(profile.alterName) recuperou aproximadamente \(String(format: "%.1f", snapshot.hoursRecovered)) horas para a própria missão.")
                Text("Para reivindicar: um treino de pelo menos 30 minutos com pico de frequência cardíaca acima de 120 bpm registrado no HealthKit nos últimos 7 dias.")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(.secondary)
                if let workoutMessage {
                    Text(workoutMessage).cortexTextStyle(.caption1).foregroundStyle(CortexTheme.ice)
                }
                Button(isVerifyingWorkout ? "Verificando…" : "Verificar treino") {
                    verifyWorkout()
                }
                .buttonStyle(.borderedProminent)
                .tint(CortexTheme.moss)
                .disabled(snapshot.currentDay < 30 || profile.day30Claimed || isVerifyingWorkout)
            }
        }
    }

    private var milestone60: some View {
        milestoneCard(
            day: 60,
            title: "A Maestria",
            subtitle: "Mudança de identidade",
            unlocked: snapshot.currentDay >= 60,
            claimed: profile.day60Claimed
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Modo Mestre: interface mais sóbria e a releitura da sua mensagem do Dia 0.")
                Button(profile.day60Claimed ? "Modo Mestre ativo" : "Ativar Modo Mestre") {
                    profile.day60Claimed = true
                    profile.masterModeEnabled = true
                    HapticEngine.shared.victory()
                }
                .buttonStyle(.borderedProminent)
                .tint(CortexTheme.moss)
                .disabled(snapshot.currentDay < 60 || profile.day60Claimed)
            }
        }
    }

    private var milestone90: some View {
        milestoneCard(
            day: 90,
            title: "O Legado",
            subtitle: "Identidade consolidada",
            unlocked: snapshot.currentDay >= 90,
            claimed: profile.day90Claimed
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Registre o que mudou e transforme a experiência em uma ação de impacto no mundo real escolhida por você.")
                Text("O plantio de árvore e o Modo Mentor exigem backend e parceria externa; o projeto inclui o ponto de extensão, mas não executa doações automáticas.")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(.secondary)
                Button(profile.day90Claimed ? "Identidade consolidada" : "Consolidar marco") {
                    profile.day90Claimed = true
                    HapticEngine.shared.victory()
                }
                .buttonStyle(.borderedProminent)
                .tint(CortexTheme.moss)
                .disabled(snapshot.currentDay < 90 || profile.day90Claimed)
            }
        }
    }

    private func milestoneCard<Content: View>(
        day: Int,
        title: String,
        subtitle: String,
        unlocked: Bool,
        claimed: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DIA \(day)")
                        .cortexTextStyle(.caption1)
                        .foregroundStyle(unlocked ? CortexTheme.ice : CortexTheme.muted)
                    Text(title).cortexTextStyle(.title2)
                    Text(subtitle).cortexTextStyle(.subhead).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: claimed ? "checkmark.seal.fill" : (unlocked ? "lock.open.fill" : "lock.fill"))
                    .cortexTextStyle(.title1)
                    .foregroundStyle(claimed ? CortexTheme.moss : CortexTheme.muted)
            }
            content()
                .opacity(unlocked ? 1 : 0.45)
        }
        .cortexCard()
    }

    private func verifyWorkout() {
        isVerifyingWorkout = true
        workoutMessage = nil
        Task {
            if !health.isAuthorized { await health.requestAuthorization() }
            let verified = await health.verifyMilestoneWorkout()
            if verified {
                profile.day30Claimed = true
                workoutMessage = "Treino verificado. Marco reivindicado."
                HapticEngine.shared.victory()
            } else {
                workoutMessage = "Nenhum treino compatível foi encontrado. Verifique as permissões e tente novamente após o treino."
            }
            isVerifyingWorkout = false
        }
    }
}

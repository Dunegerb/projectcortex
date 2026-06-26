import FamilyControls
import SwiftUI

struct LockdownStepView: View {
    @Binding var draft: OnboardingDraft
    let onFinish: () -> Void

    @StateObject private var screenTime = ScreenTimeService.shared
    @StateObject private var health = HealthKitService.shared
    @State private var showPicker = false
    @State private var notificationsGranted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("LOCKDOWN")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(CortexTheme.muted)
                Text("Iniciando protocolos de defesa do Córtex")
                    .cortexTextStyle(.largeTitle)

                permissionCard(
                    title: "1. Escudo de aplicativos e navegação",
                    detail: authorizationDetail,
                    symbol: "shield.lefthalf.filled"
                ) {
                    Task {
                        await screenTime.requestAuthorization()
                        if screenTime.authorizationStatus == .approved { showPicker = true }
                    }
                }

                permissionCard(
                    title: "2. Selecionar bloqueios",
                    detail: screenTime.selection.applicationTokens.isEmpty && screenTime.selection.categoryTokens.isEmpty
                        ? "Escolha aplicativos, categorias ou sites."
                        : "Seleção pronta para aplicar.",
                    symbol: "app.badge.checkmark"
                ) { showPicker = true }
                .disabled(screenTime.authorizationStatus != .approved)

                permissionCard(
                    title: "3. Métricas opcionais de Saúde",
                    detail: health.isAuthorized ? "Acesso solicitado." : "Sono, passos, treinos e frequência cardíaca.",
                    symbol: "heart.text.square"
                ) { Task { await health.requestAuthorization() } }

                permissionCard(
                    title: "4. Lembretes previsíveis",
                    detail: notificationsGranted ? "Lembretes silenciosos às 8h e 20h." : "Sem sons e sem horários aleatórios.",
                    symbol: "bell.slash"
                ) {
                    Task { notificationsGranted = await NotificationService.shared.requestAndSchedule() }
                }

                if let error = screenTime.lastError {
                    Text(error).cortexTextStyle(.caption1).foregroundStyle(.red)
                }

                Button {
                    if screenTime.authorizationStatus == .approved {
                        screenTime.applyShields()
                        draft.shieldEnabled = screenTime.shieldsApplied
                    }
                    onFinish()
                } label: {
                    VStack(spacing: 6) {
                        Text("FINALIZAR INICIAÇÃO")
                        Text("Sua armadura está ativa. Agora volte ao mundo real.")
                            .cortexTextStyle(.caption1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CortexPrimaryButtonStyle())
            }
            .padding(24)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $screenTime.selection)
        .cortexFadeIn()
    }

    private var authorizationDetail: String {
        switch screenTime.authorizationStatus {
        case .approved: return "Screen Time autorizado."
        case .denied: return "Autorização negada; você pode continuar sem bloqueio."
        case .notDetermined: return "Ativar Escudo Neural."
        @unknown default: return "Estado desconhecido."
        }
    }

    private func permissionCard(
        title: String,
        detail: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: symbol)
                    .cortexTextStyle(.title2)
                    .foregroundStyle(CortexTheme.ice)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).cortexTextStyle(.headline)
                    Text(detail).cortexTextStyle(.caption1).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(CortexTheme.muted)
            }
            .padding(18)
            .background(CortexTheme.secondary, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

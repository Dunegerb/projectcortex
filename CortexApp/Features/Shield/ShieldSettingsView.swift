import FamilyControls
import SwiftUI

struct ShieldSettingsView: View {
    @Bindable var profile: UserProfile
    @StateObject private var service = ScreenTimeService.shared
    @State private var showPicker = false
    @State private var showDisableConfirmation = false

    private var canDisableNow: Bool {
        guard let date = profile.pendingShieldDisableDate else { return false }
        return date <= Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    shieldStatus

                    Button {
                        Task {
                            await service.requestAuthorization()
                            if service.authorizationStatus == .approved { showPicker = true }
                        }
                    } label: {
                        settingsRow(
                            title: "Autorizar Screen Time",
                            detail: authorizationText,
                            icon: "person.badge.shield.checkmark"
                        )
                    }
                    .buttonStyle(.plain)

                    Button { showPicker = true } label: {
                        settingsRow(
                            title: "Escolher aplicativos, sites e categorias",
                            detail: selectionSummary,
                            icon: "app.badge.checkmark"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(service.authorizationStatus != .approved)

                    Button {
                        service.applyShields()
                        profile.shieldEnabled = service.shieldsApplied
                        profile.pendingShieldDisableDate = nil
                        UserDefaults.standard.set(profile.shieldEnabled, forKey: "cortex.shield.enabled")
                        HapticEngine.shared.victory()
                    } label: {
                        Label("APLICAR ESCUDO NEURAL", systemImage: "shield.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CortexPrimaryButtonStyle())
                    .disabled(service.authorizationStatus != .approved)

                    disableSection
                }
                .padding(18)
            }
            .background(CortexTheme.background.ignoresSafeArea())
            .navigationTitle("Escudo Neural")
            .familyActivityPicker(isPresented: $showPicker, selection: $service.selection)
            .alert("Remover bloqueios?", isPresented: $showDisableConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Remover", role: .destructive) {
                    service.removeShields()
                    profile.shieldEnabled = false
                    profile.pendingShieldDisableDate = nil
                    UserDefaults.standard.set(false, forKey: "cortex.shield.enabled")
                }
            } message: {
                Text("A espera terminou. Confirme apenas se esta decisão ainda fizer sentido fora do momento de impulso.")
            }
        }
    }

    private var shieldStatus: some View {
        VStack(spacing: 12) {
            Image(systemName: profile.shieldEnabled ? "shield.checkered" : "shield.slash")
                .font(.system(size: 58))
                .foregroundStyle(profile.shieldEnabled ? CortexTheme.moss : CortexTheme.muted)
            Text(profile.shieldEnabled ? "ESCUDO ATIVO" : "ESCUDO INATIVO")
                .cortexTextStyle(.title2)
            Text("O iOS exige a autorização Family Controls e um perfil de assinatura com a capacidade correspondente.")
                .cortexTextStyle(.caption1)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cortexCard()
    }

    @ViewBuilder
    private var disableSection: some View {
        if profile.shieldEnabled {
            VStack(alignment: .leading, spacing: 12) {
                Text("DESATIVAÇÃO COM ATRASO")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(CortexTheme.muted)

                if let date = profile.pendingShieldDisableDate {
                    Text(canDisableNow
                         ? "A janela de espera terminou. Você pode confirmar a remoção."
                         : "Remoção disponível em \(date.formatted(date: .abbreviated, time: .shortened)).")
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Cancelar solicitação") {
                            profile.pendingShieldDisableDate = nil
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        if canDisableNow {
                            Button("Confirmar remoção", role: .destructive) {
                                showDisableConfirmation = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(CortexTheme.danger)
                        }
                    }
                } else {
                    Text("O aplicativo não pode impedir desinstalação nem alterar regras do sistema. Ele pode, porém, adiar a remoção dos bloqueios dentro do próprio fluxo.")
                        .cortexTextStyle(.subhead)
                        .foregroundStyle(.secondary)
                    Button("Solicitar remoção em 24 horas", role: .destructive) {
                        profile.pendingShieldDisableDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
                        HapticEngine.shared.impactFallback(.heavy)
                    }
                    .buttonStyle(.bordered)
                    .tint(CortexTheme.danger)
                }
            }
            .cortexCard()
        }
    }

    private var authorizationText: String {
        switch service.authorizationStatus {
        case .approved: return "Autorizado"
        case .denied: return "Negado"
        case .notDetermined: return "Ainda não solicitado"
        @unknown default: return "Indefinido"
        }
    }

    private var selectionSummary: String {
        let apps = service.selection.applicationTokens.count
        let categories = service.selection.categoryTokens.count
        let sites = service.selection.webDomainTokens.count
        return "\(apps) apps • \(categories) categorias • \(sites) sites"
    }

    private func settingsRow(title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .cortexTextStyle(.title2)
                .foregroundStyle(CortexTheme.ice)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).cortexTextStyle(.headline)
                Text(detail).cortexTextStyle(.caption1).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(CortexTheme.muted)
        }
        .cortexCard()
    }
}

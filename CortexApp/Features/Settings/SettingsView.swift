import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRaw = AppAppearanceMode.system.rawValue
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Aparência") {
                    Picker("Tema", selection: $appearanceModeRaw) {
                        ForEach(AppAppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Label(appearanceDescription, systemImage: selectedAppearance.systemImage)
                        .cortexTextStyle(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(CortexTheme.secondary)

                Section("Identidade") {
                    TextField("Nome", text: $profile.realName)
                        .cortexNativeKeyboard(capitalization: .words, submitLabel: .next)
                    TextField("Alter Ego", text: $profile.alterName)
                        .cortexNativeKeyboard(capitalization: .words, submitLabel: .next)
                    TextField("Missão", text: $profile.mission, axis: .vertical)
                        .cortexNativeKeyboard(submitLabel: .done)
                    Picker("Arquétipo", selection: Binding(
                        get: { profile.archetype },
                        set: { profile.archetype = $0 }
                    )) {
                        ForEach(Archetype.allCases) { Text($0.title).tag($0) }
                    }
                }
                .listRowBackground(CortexTheme.secondary)

                Section {
                    Stepper("Meta: \(profile.targetDays) dias", value: $profile.targetDays, in: 30...365, step: 30)
                    Stepper("Tempo gasto no ato da autosatisfação: \(profile.dailyUsageMinutes) min/dia", value: $profile.dailyUsageMinutes, in: 5...240, step: 5)
                    Toggle("Modo Mestre", isOn: $profile.masterModeEnabled)
                        .disabled(!profile.day60Claimed)
                } header: {
                    Text("Plano")
                } footer: {
                    Text("A média diária é usada somente para estimar o tempo recuperado desde a última recaída.")
                }
                .listRowBackground(CortexTheme.secondary)

                Section("Notificações") {
                    Button("Reagendar lembretes silenciosos") {
                        Task { _ = await NotificationService.shared.requestAndSchedule() }
                    }
                }
                .listRowBackground(CortexTheme.secondary)

                Section("Segurança e limites") {
                    Text("O Córtex é uma ferramenta de autorregulação e não um dispositivo médico. Não diagnostica, trata ou garante resultados. Bloqueios dependem das permissões e capacidades da Apple.")
                        .cortexTextStyle(.footnote)
                    NavigationLink("Privacidade e uso responsável") {
                        ResponsibleUseView()
                    }
                }
                .listRowBackground(CortexTheme.secondary)

                Section {
                    Button("Reiniciar todos os dados", role: .destructive) { showResetAlert = true }
                }
                .listRowBackground(CortexTheme.secondary)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(CortexTheme.background.ignoresSafeArea())
            .navigationTitle("Ajustes")
            .alert("Apagar todos os dados?", isPresented: $showResetAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Apagar", role: .destructive) { resetAllData() }
            } message: {
                Text("Esta ação apaga perfil, diário, check-ins e sessões locais. Não pode ser desfeita.")
            }
        }
    }

    private var selectedAppearance: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    private var appearanceDescription: String {
        switch selectedAppearance {
        case .system:
            return "A aparência acompanha automaticamente o tema configurado no iPhone."
        case .light:
            return "O Córtex permanece no modo claro."
        case .dark:
            return "O Córtex permanece no modo escuro."
        }
    }

    private func resetAllData() {
        deleteAll(UserProfile.self)
        deleteAll(RecoveryLetter.self)
        deleteAll(DailyCheckIn.self)
        deleteAll(EmergencySession.self)
        deleteAll(JournalEntry.self)
        ScreenTimeService.shared.removeShields()
        UserDefaults.standard.removeObject(forKey: "cortex.shield.enabled")
        try? modelContext.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        if let items = try? modelContext.fetch(FetchDescriptor<T>()) {
            items.forEach { modelContext.delete($0) }
        }
    }
}

private struct ResponsibleUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Uso responsável")
                    .cortexTextStyle(.largeTitle)
                Group {
                    Text("Se o comportamento estiver causando sofrimento intenso, prejuízo funcional, risco, violência ou pensamentos de autoagressão, procure apoio profissional ou um serviço de emergência local.")
                    Text("O aplicativo evita linguagem de vergonha e não trata um deslize como perda total do progresso.")
                    Text("Dados do perfil, diário e check-ins permanecem no armazenamento local do aparelho nesta versão. HealthKit e Screen Time são acessados somente após autorização explícita.")
                    Text("A versão de demonstração não envia dados a servidor, não executa doações e não possui comunidade anônima.")
                }
                .foregroundStyle(.secondary)
            }
            .padding(22)
        }
        .background(CortexTheme.background.ignoresSafeArea())
        .navigationTitle("Privacidade")
        .navigationBarTitleDisplayMode(.inline)
    }
}

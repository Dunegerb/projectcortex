import SwiftUI

struct ForgeStepView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void

    private var canContinue: Bool {
        !draft.alterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !draft.mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("A FORJA")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(CortexTheme.muted)

                Text("Quem assume o comando agora?")
                    .cortexTextStyle(.largeTitle)

                TextField("Nome do Alter Ego — Atlas, Arquiteto, Você 2.0…", text: $draft.alterName)
                    .cortexNativeKeyboard(capitalization: .words, submitLabel: .next)
                    .padding(16)
                    .background(CortexTheme.quaternary, in: RoundedRectangle(cornerRadius: 16))

                Text("ARQUÉTIPO")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(CortexTheme.muted)

                ForEach(Archetype.allCases) { archetype in
                    Button {
                        draft.archetype = archetype
                        HapticEngine.shared.softPulse()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: archetype.symbol)
                                .cortexTextStyle(.title3)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(archetype.title).cortexTextStyle(.headline)
                                Text(archetype.subtitle).cortexTextStyle(.caption1).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: draft.archetype == archetype ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(draft.archetype == archetype ? CortexTheme.ice : CortexTheme.muted)
                        }
                        .padding(16)
                        .background(
                            draft.archetype == archetype ? CortexTheme.secondary : CortexTheme.tertiary,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Text("Qual será o principal destino da sua energia?")
                    .cortexTextStyle(.headline)

                TextField("Uma única meta para os próximos 90 dias", text: $draft.mission, axis: .vertical)
                    .cortexNativeKeyboard(submitLabel: .next)
                    .lineLimit(2...4)
                    .padding(16)
                    .background(CortexTheme.quaternary, in: RoundedRectangle(cornerRadius: 16))

                Stepper("Tempo médio gasto no ato da autosatisfação: \(draft.dailyUsageMinutes) min/dia", value: $draft.dailyUsageMinutes, in: 5...240, step: 5)
                    .padding(16)
                    .background(CortexTheme.tertiary, in: RoundedRectangle(cornerRadius: 16))

                TextEditor(text: $draft.letter)
                    .cortexNativeKeyboard(submitLabel: .done)
                    .frame(minHeight: 130)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(CortexTheme.quaternary, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topLeading) {
                        if draft.letter.isEmpty {
                            Text("Se eu estiver prestes a desistir, o que preciso ouvir de mim mesmo?")
                                .foregroundStyle(.secondary)
                                .padding(20)
                                .allowsHitTesting(false)
                        }
                    }

                Button(action: onContinue) {
                    Text("VISUALIZAR A MISSÃO").frame(maxWidth: .infinity)
                }
                .buttonStyle(CortexPrimaryButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.35)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .cortexFadeIn()
    }
}

import SwiftUI

struct MirrorStepView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void

    private var canContinue: Bool {
        !draft.realName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        draft.losses.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 30)
                Text("O ESPELHO")
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(CortexTheme.muted)

                Text("O que este comportamento custou para você?")
                    .cortexTextStyle(.largeTitle)
                    .foregroundStyle(.white)

                Text("Escreva com honestidade. Sem rótulos, sem humilhação: apenas o que você deseja recuperar.")
                    .cortexTextStyle(.body)
                    .foregroundStyle(.secondary)

                TextField("Seu primeiro nome", text: $draft.realName)
                    .textContentType(.name)
                    .cortexNativeKeyboard(capitalization: .words, submitLabel: .next)
                    .cortexTextField()

                ForEach(draft.losses.indices, id: \.self) { index in
                    TextField("Custo \(index + 1) — energia, foco, relações…", text: $draft.losses[index])
                        .cortexNativeKeyboard(submitLabel: index == draft.losses.count - 1 ? .done : .next)
                        .cortexTextField()
                }

                Button(action: onContinue) {
                    Text("ENCERRAR O CAPÍTULO ANTERIOR")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CortexPrimaryButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.35)

                Text("O passado não pode ser alterado. O próximo capítulo ainda não foi escrito.")
                    .cortexTextStyle(.footnote)
                    .foregroundStyle(CortexTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .cortexFadeIn()
    }
}

private extension View {
    func cortexTextField() -> some View {
        self
            .padding(16)
            .background(CortexTheme.quaternary, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(CortexTheme.tertiary))
    }
}

struct CortexPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .cortexTextStyle(.headline)
            .padding(.vertical, 17)
            .padding(.horizontal, 20)
            .background(CortexTheme.moss.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

import SwiftData
import SwiftUI

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showNewEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Diário vazio",
                        systemImage: "book.closed",
                        description: Text("Registre padrões, gatilhos e decisões úteis. Evite transformar o diário em contagem punitiva.")
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.createdAt.cortexShortDate)
                                        .cortexTextStyle(.caption1)
                                        .foregroundStyle(CortexTheme.ice)
                                    Spacer()
                                    Text(String(repeating: "●", count: entry.mood))
                                        .cortexTextStyle(.caption2)
                                        .foregroundStyle(CortexTheme.moss)
                                }
                                Text(entry.text)
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(CortexTheme.secondary)
                            .listRowSeparatorTint(CortexTheme.quaternary)
                        }
                        .onDelete { offsets in
                            offsets.map { entries[$0] }.forEach { modelContext.delete($0) }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(CortexTheme.background.ignoresSafeArea())
            .navigationTitle("Diário")
            .toolbar {
                Button { showNewEntry = true } label: { Image(systemName: "square.and.pencil") }
            }
            .sheet(isPresented: $showNewEntry) {
                NewJournalEntryView { text, mood in
                    modelContext.insert(JournalEntry(text: text, mood: mood))
                    try? modelContext.save()
                    showNewEntry = false
                }
            }
        }
    }
}

private struct NewJournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var mood = 3
    let onSave: (String, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Como você está?") {
                    Picker("Estado", selection: $mood) {
                        Text("Muito difícil").tag(1)
                        Text("Difícil").tag(2)
                        Text("Neutro").tag(3)
                        Text("Bem").tag(4)
                        Text("Muito bem").tag(5)
                    }
                }
                .listRowBackground(CortexTheme.secondary)
                Section("Registro") {
                    TextEditor(text: $text)
                        .cortexNativeKeyboard(submitLabel: .done)
                        .frame(minHeight: 180)
                }
                .listRowBackground(CortexTheme.secondary)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(CortexTheme.base)
            .navigationTitle("Novo registro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { onSave(text, mood) }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

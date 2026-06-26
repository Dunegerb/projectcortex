import Foundation
import SwiftData
import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var profile: UserProfile

    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \EmergencySession.startedAt, order: .reverse) private var emergencySessions: [EmergencySession]
    @StateObject private var health = HealthKitService.shared
    @State private var showCheckIn = false
    @State private var now = Date()

    private var snapshot: RecoverySnapshot {
        RecoveryEngine.snapshot(profile: profile, checkIns: checkIns, now: now)
    }

    private var activeChakras: Int {
        TransmutationStage.activeCount(for: snapshot.currentDay)
    }

    private var transmutationProgress: Double {
        TransmutationStage.progress(for: snapshot.currentDay)
    }

    private var stage: TransmutationStage {
        TransmutationStage.all[activeChakras - 1]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    transmutationHero
                    recoveredTimeCard
                    progressMetrics
                    wellbeingCard

                    if snapshot.isFlatlineWindow {
                        flatlineCard
                    }

                    dailyNoteButton
                    emergencyButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(homeBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showCheckIn) {
                DailyCheckInSheet(
                    existingNote: todayObservation?.note ?? "",
                    onSaveObservation: saveObservation,
                    onRegisterRelapse: registerRelapse
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .task {
                now = Date()
                await health.refreshDashboardMetrics()
                WidgetSharedState.update(profile: profile, snapshot: snapshot)
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 60_000_000_000)
                    now = Date()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                now = Date()
            }
            .onChange(of: checkIns.count) {
                WidgetSharedState.update(profile: profile, snapshot: snapshot)
            }
            .onChange(of: profile.startDate) {
                WidgetSharedState.update(profile: profile, snapshot: snapshot)
            }
        }
    }

    private var homeBackground: some View {
        ZStack {
            CortexTheme.base.ignoresSafeArea()
            RadialGradient(
                colors: [stage.color.opacity(0.10), .clear],
                center: UnitPoint(x: 0.52, y: 0.23),
                startRadius: 8,
                endRadius: 340
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .cortexTextStyle(.caption1, weight: .semibold)
                    .foregroundStyle(.secondary)
                Text(profile.alterName)
                    .cortexTextStyle(.title1, weight: .semibold)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            Image(systemName: profile.archetype.symbol)
                .cortexTextStyle(.title3)
                .foregroundStyle(stage.color)
                .frame(width: 44, height: 44)
                .background(CortexTheme.secondary, in: Circle())
                .overlay(Circle().stroke(CortexTheme.quaternary.opacity(0.8), lineWidth: 1))
                .accessibilityLabel("Arquétipo: \(profile.archetype.title)")
        }
    }

    private var transmutationHero: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("TRANSMUTAÇÃO")
                        .cortexTextStyle(.caption2, weight: .semibold, tracking: -0.05)
                        .foregroundStyle(stage.color)
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text("\(snapshot.currentDay)")
                            .font(.system(size: 48, weight: .semibold, design: .default))
                            .tracking(-1.2)
                            .monospacedDigit()
                        Text(snapshot.currentDay == 1 ? "dia" : "dias")
                            .cortexTextStyle(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(stage.shortTitle)
                        .cortexTextStyle(.headline)
                    Text("Centro \(activeChakras) de 7")
                        .cortexTextStyle(.caption1)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ChakraExperienceView(
                day: snapshot.currentDay,
                animated: !reduceMotion
            )
            .frame(height: 365)
            .padding(.horizontal, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Figura de transmutação. \(activeChakras) de 7 centros ativos.")

            VStack(spacing: 11) {
                HStack {
                    Text(stage.title)
                        .cortexTextStyle(.subhead, weight: .semibold)
                    Spacer()
                    Text(transmutationProgress.cortexPercentage)
                        .cortexTextStyle(.subhead, weight: .semibold)
                        .monospacedDigit()
                        .foregroundStyle(stage.color)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(CortexTheme.quaternary)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [TransmutationStage.all.first!.color, stage.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(5, proxy.size.width * transmutationProgress))
                    }
                }
                .frame(height: 5)

                HStack {
                    Label("Desde \(profile.startDate.cortexShortDate)", systemImage: "calendar")
                    Spacer()
                    Text(nextStageDescription)
                }
                .cortexTextStyle(.caption1)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CortexTheme.secondary)
                .overlay {
                    LinearGradient(
                        colors: [stage.color.opacity(0.10), .clear, CortexTheme.base.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CortexTheme.quaternary.opacity(0.78), lineWidth: 1)
        )
    }

    private var recoveredTimeCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text("TEMPO RECUPERADO")
                    .cortexTextStyle(.caption2, weight: .semibold, tracking: -0.05)
                    .foregroundStyle(.secondary)
                Text(recoveredTimeText)
                    .cortexTextStyle(.title1, weight: .semibold)
                    .monospacedDigit()
                Text("Estimativa \(recoveryOriginText) · base de \(profile.dailyUsageMinutes) min/dia")
                    .cortexTextStyle(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(CortexTheme.ice)
                .frame(width: 50, height: 50)
                .background(CortexTheme.tertiary, in: Circle())
        }
        .cortexCard(padding: 18)
    }

    private var progressMetrics: some View {
        HStack(spacing: 12) {
            compactMetric(
                title: "Meta",
                value: "\(max(profile.targetDays - snapshot.currentDay, 0))",
                detail: "dias restantes",
                icon: "flag.checkered"
            )
            compactMetric(
                title: "Registros",
                value: "\(snapshot.alignedDays)",
                detail: "notas no ciclo",
                icon: "note.text"
            )
        }
    }

    private func compactMetric(title: String, value: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .cortexTextStyle(.caption1)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon)
                    .foregroundStyle(CortexTheme.ice)
            }
            Text(value)
                .cortexTextStyle(.title2, weight: .semibold)
                .monospacedDigit()
            Text(detail)
                .cortexTextStyle(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .cortexCard(padding: 15)
    }


    private var wellbeingCard: some View {
        VStack(spacing: 0) {
            wellbeingRow(
                title: "Sono",
                value: health.sleepHours.map { String(format: "%.1fh", $0) } ?? "—",
                icon: "moon.zzz.fill"
            )
            Divider().overlay(CortexTheme.quaternary).padding(.leading, 48)
            wellbeingRow(
                title: "Frequência cardíaca média",
                value: health.averageHeartRate.map { "\(Int($0)) bpm" } ?? "—",
                icon: "heart.fill"
            )
            Divider().overlay(CortexTheme.quaternary).padding(.leading, 48)
            wellbeingRow(
                title: "Protocolos concluídos",
                value: "\(emergencySessions.filter(\.completed).count)",
                icon: "lifepreserver.fill"
            )
        }
        .background(CortexTheme.secondary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CortexTheme.quaternary.opacity(0.72), lineWidth: 1)
        )
    }

    private func wellbeingRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .foregroundStyle(CortexTheme.ice)
                .frame(width: 28)
            Text(title)
                .cortexTextStyle(.subhead)
            Spacer()
            Text(value)
                .cortexTextStyle(.subhead, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(value == "—" ? Color.secondary : Color.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var flatlineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("ENERGIA EM REORGANIZAÇÃO", systemImage: "cloud.fog.fill")
                .cortexTextStyle(.caption1, weight: .semibold)
                .foregroundStyle(CortexTheme.paper)
            Text("Você pode perceber apatia, cansaço ou irritação. Isso não é um diagnóstico nem uma certeza médica. Reduza a carga, durma bem e procure apoio profissional se o sofrimento for intenso ou persistente.")
                .cortexTextStyle(.subhead)
                .foregroundStyle(.secondary)
            Text("Esta fase é temporária. Continue com ações pequenas e concretas.")
                .cortexTextStyle(.headline)
        }
        .cortexCard()
    }

    private var dailyNoteButton: some View {
        Button {
            showCheckIn = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: todayObservation == nil ? "square.and.pencil" : "checkmark.circle.fill")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(CortexTheme.ice)
                    .frame(width: 42, height: 42)
                    .background(CortexTheme.tertiary, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(todayObservation == nil ? "Adicionar nota do dia" : "Editar nota de hoje")
                        .cortexTextStyle(.headline)
                    Text("Opcional · não altera sua contagem")
                        .cortexTextStyle(.caption1)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .cortexTextStyle(.caption1, weight: .semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(CortexTheme.secondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(CortexTheme.quaternary.opacity(0.72), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var emergencyButton: some View {
        Button {
            router.showEmergency = true
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "lifepreserver.fill")
                    .font(.system(size: 20, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Preciso de apoio agora")
                        .cortexTextStyle(.headline)
                    Text("Abrir protocolo de emergência")
                        .cortexTextStyle(.caption1)
                        .foregroundStyle(.white.opacity(0.70))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .cortexTextStyle(.caption1, weight: .semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(17)
            .foregroundStyle(.white)
            .background(CortexTheme.danger.opacity(0.86), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var todayObservation: DailyCheckIn? {
        checkIns.first {
            Calendar.current.isDateInToday($0.date) && $0.status == .aligned
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "BOM DIA"
        case 12..<18: return "BOA TARDE"
        default: return "BOA NOITE"
        }
    }

    private var nextStageDescription: String {
        guard let nextDay = TransmutationStage.nextActivationDay(after: snapshot.currentDay) else {
            return "Todos os centros ativos"
        }

        let remaining = max(nextDay - snapshot.currentDay, 0)
        return remaining == 0 ? "Próxima etapa hoje" : "Próxima etapa em \(remaining)d"
    }

    private var recoveryOriginText: String {
        snapshot.slips > 0 ? "desde a última recaída" : "desde a criação da conta"
    }

    private var recoveredTimeText: String {
        let totalMinutes = max(0, Int((snapshot.hoursRecovered * 60).rounded(.down)))
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours < 24 {
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)min"
        }

        let days = hours / 24
        let remainingHours = hours % 24
        return remainingHours == 0 ? "\(days)d" : "\(days)d \(remainingHours)h"
    }

    private func saveObservation(_ note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = todayObservation {
            existing.note = trimmed
            existing.date = Date()
        } else {
            modelContext.insert(DailyCheckIn(status: .aligned, note: trimmed))
        }

        try? modelContext.save()
        HapticEngine.shared.softPulse()
        now = Date()
        showCheckIn = false
    }

    private func registerRelapse(_ note: String) {
        let relapseDate = Date()
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(DailyCheckIn(date: relapseDate, status: .slip, note: trimmed))
        profile.startDate = relapseDate

        try? modelContext.save()
        HapticEngine.shared.softPulse()
        now = relapseDate
        showCheckIn = false
    }
}

private struct DailyCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    @State private var showRelapseConfirmation = false

    let onSaveObservation: (String) -> Void
    let onRegisterRelapse: (String) -> Void

    init(
        existingNote: String,
        onSaveObservation: @escaping (String) -> Void,
        onRegisterRelapse: @escaping (String) -> Void
    ) {
        _note = State(initialValue: existingNote)
        self.onSaveObservation = onSaveObservation
        self.onRegisterRelapse = onRegisterRelapse
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Registro do dia")
                            .cortexTextStyle(.title1, weight: .semibold)
                        Text("Este espaço é opcional. A contagem continua automaticamente, com ou sem registro.")
                            .cortexTextStyle(.subhead)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Escreva uma observação…", text: $note, axis: .vertical)
                        .cortexNativeKeyboard(submitLabel: .done)
                        .lineLimit(5...9)
                        .padding(16)
                        .background(CortexTheme.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button {
                        onSaveObservation(note)
                    } label: {
                        Label("Salvar observação", systemImage: "checkmark")
                            .cortexTextStyle(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .background(CortexTheme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Divider().overlay(CortexTheme.quaternary)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recomeçar o ciclo")
                            .cortexTextStyle(.headline)
                        Text("Registre uma recaída somente quando necessário. O dia atual voltará para 1 e o tempo recuperado passará a ser calculado a partir desse momento.")
                            .cortexTextStyle(.footnote)
                            .foregroundStyle(.secondary)

                        Button(role: .destructive) {
                            showRelapseConfirmation = true
                        } label: {
                            Label("Registrar recaída", systemImage: "arrow.counterclockwise")
                                .cortexTextStyle(.headline)
                        }
                    }
                }
                .padding(22)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(CortexTheme.base.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
            .alert("Reiniciar a contagem?", isPresented: $showRelapseConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Registrar e reiniciar", role: .destructive) {
                    onRegisterRelapse(note)
                }
            } message: {
                Text("Seu histórico será preservado, mas o ciclo atual voltará ao dia 1.")
            }
        }
    }
}

private struct TransmutationStage {
    let activationDay: Int
    let shortTitle: String
    let title: String
    let color: Color

    static let all: [TransmutationStage] = [
        .init(activationDay: 1, shortTitle: "Raiz", title: "Presença e estabilidade", color: Color(red: 168.0 / 255.0, green: 19.0 / 255.0, blue: 18.0 / 255.0)),
        .init(activationDay: 5, shortTitle: "Sacral", title: "Movimento e criação", color: Color(red: 208.0 / 255.0, green: 93.0 / 255.0, blue: 2.0 / 255.0)),
        .init(activationDay: 10, shortTitle: "Plexo solar", title: "Direção e vontade", color: Color(red: 240.0 / 255.0, green: 156.0 / 255.0, blue: 34.0 / 255.0)),
        .init(activationDay: 15, shortTitle: "Coração", title: "Integração e equilíbrio", color: Color(red: 57.0 / 255.0, green: 141.0 / 255.0, blue: 24.0 / 255.0)),
        .init(activationDay: 21, shortTitle: "Garganta", title: "Verdade e expressão", color: Color(red: 15.0 / 255.0, green: 158.0 / 255.0, blue: 226.0 / 255.0)),
        .init(activationDay: 30, shortTitle: "Terceiro olho", title: "Clareza e percepção", color: Color(red: 131.0 / 255.0, green: 58.0 / 255.0, blue: 247.0 / 255.0)),
        .init(activationDay: 90, shortTitle: "Coroa", title: "Consciência e propósito", color: Color(red: 249.0 / 255.0, green: 249.0 / 255.0, blue: 247.0 / 255.0))
    ]

    static func activeCount(for day: Int) -> Int {
        let safeDay = max(day, 1)
        let count = all.filter { safeDay >= $0.activationDay }.count
        return min(max(count, 1), all.count)
    }

    static func progress(for day: Int) -> Double {
        let safeDay = min(max(day, 1), 90)
        return Double(safeDay - 1) / 89.0
    }

    static func nextActivationDay(after day: Int) -> Int? {
        all.first { $0.activationDay > max(day, 1) }?.activationDay
    }
}


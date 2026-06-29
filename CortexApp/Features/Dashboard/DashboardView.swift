import Foundation
import SwiftData
import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @State private var showCheckIn = false
    @State private var showShield = false
    @State private var now = Date()
    @State private var dashboardOverscroll: CGFloat = 0
    @State private var previousOverscroll: CGFloat = 0
    @State private var elasticHapticStep = 0
    @State private var isStretchingHeader = false
    @State private var elasticContentShift: CGFloat = 0

    private var snapshot: RecoverySnapshot {
        RecoveryEngine.snapshot(profile: profile, checkIns: checkIns, now: now)
    }

    private var activeChakras: Int {
        TransmutationStage.activeCount(for: snapshot.currentDay)
    }

    private var stage: TransmutationStage {
        TransmutationStage.all[activeChakras - 1]
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let scale = HomeMetrics.scale(for: proxy.size.width)
                let topInset = proxy.safeAreaInsets.top > 0
                    ? proxy.safeAreaInsets.top
                    : (proxy.size.height >= 760 * scale ? 44 * scale : 20 * scale)
                let bottomInset = proxy.safeAreaInsets.bottom > 0
                    ? proxy.safeAreaInsets.bottom
                    : (proxy.size.height >= 760 * scale ? 34 * scale : 8 * scale)

                ScrollView {
                    VStack(spacing: 0) {
                        elasticTopPanel(scale: scale, topInset: topInset)

                        VStack(spacing: HomeMetrics.cardGap * scale) {
                            cycleCard(scale: scale)
                            currentEnergyCard(scale: scale)
                            recoveredTimeCard(scale: scale)
                            dashboardSummaryCards(scale: scale)
                            addTodayNoteCard(scale: scale)
                        }
                        .padding(.horizontal, HomeMetrics.cardInset * scale)
                        .padding(.top, HomeMetrics.cardGap * scale)
                        .padding(.bottom, 84 * scale + bottomInset)
                        .background(Color.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .coordinateSpace(name: DashboardScrollSpace.name)
                .scrollIndicators(.hidden)
                .background(Color.black)
                .onPreferenceChange(DashboardOverscrollPreferenceKey.self) { amount in
                    updateElasticOverscroll(amount, scale: scale)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            guard value.translation.height > 0 else { return }
                            if !isStretchingHeader {
                                isStretchingHeader = true
                                HapticEngine.shared.prepareElastic()
                            }

                            let normalized = min(
                                max(dashboardOverscroll / max(80 * scale, 1), 0),
                                1
                            )
                            let resisted = normalized * (2 - normalized)
                            elasticContentShift = resisted * 10 * scale
                        }
                        .onEnded { value in
                            let shouldRelease = isStretchingHeader && dashboardOverscroll > 3 * scale
                            isStretchingHeader = false
                            previousOverscroll = 0
                            elasticHapticStep = 0

                            if shouldRelease {
                                HapticEngine.shared.elasticRelease()
                            }

                            let velocity = min(
                                max(value.predictedEndTranslation.height / 120, 0.8),
                                4.0
                            )
                            withAnimation(
                                .interpolatingSpring(
                                    mass: 0.72,
                                    stiffness: 210,
                                    damping: 18,
                                    initialVelocity: velocity
                                )
                            ) {
                                elasticContentShift = 0
                            }
                        }
                )
            }
            .ignoresSafeArea(edges: .top)
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
            .sheet(isPresented: $showShield) {
                ShieldSettingsView(profile: profile)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                now = Date()
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

    private func elasticTopPanel(scale: CGFloat, topInset: CGFloat) -> some View {
        let baseHeight = topInset + (HomeMetrics.headerContentHeight * scale)

        return GeometryReader { geometry in
            let pullDistance = max(
                geometry.frame(in: .named(DashboardScrollSpace.name)).minY,
                0
            )

            topPanel(
                scale: scale,
                topInset: topInset,
                stretch: pullDistance,
                contentShift: elasticContentShift
            )
            .frame(width: geometry.size.width)
            .offset(y: -pullDistance)
            .preference(
                key: DashboardOverscrollPreferenceKey.self,
                value: pullDistance
            )
        }
        .frame(height: baseHeight)
    }

    private func topPanel(
        scale: CGFloat,
        topInset: CGFloat,
        stretch: CGFloat,
        contentShift: CGFloat
    ) -> some View {
        let headerHeight = topInset + (HomeMetrics.headerContentHeight * scale)
        let panelShape = UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 35 * scale,
            bottomTrailingRadius: 35 * scale,
            topTrailingRadius: 0,
            style: .continuous
        )

        return ZStack(alignment: .topLeading) {
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: HomeColors.welcomeDark, location: 0.00),
                    .init(color: HomeColors.welcomeMid, location: 0.73),
                    .init(color: HomeColors.welcomeLight, location: 1.00)
                ]),
                center: UnitPoint(x: 0.04, y: 0.96),
                startRadius: 0,
                endRadius: 460 * scale
            )

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: -1 * scale) {
                    Text(greeting)
                        .font(.system(size: 15 * scale, weight: .regular, design: .default))
                        .tracking(-0.18 * scale)
                        .foregroundStyle(HomeColors.muted)

                    Text(profile.alterName)
                        .font(.system(size: 34 * scale, weight: .medium, design: .default))
                        .tracking(-0.48 * scale)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(width: 230 * scale, alignment: .leading)
                .offset(x: 30 * scale, y: topInset + 36 * scale)

                Button {
                    showShield = true
                    HapticEngine.shared.softPulse()
                } label: {
                    ZStack {
                        Circle()
                            .fill(HomeColors.control)

                        Image("ShieldGlyph")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundStyle(HomeColors.muted)
                            .frame(width: 25 * scale, height: 25 * scale)

                        Circle()
                            .fill(profile.shieldEnabled ? HomeColors.statusGreen : HomeColors.muted)
                            .frame(width: 7 * scale, height: 7 * scale)
                            .offset(x: 15 * scale, y: -13 * scale)
                    }
                    .frame(width: 53 * scale, height: 53 * scale)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(profile.shieldEnabled ? "Escudo ativo" : "Escudo inativo")
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .padding(.trailing, 30 * scale)
                .offset(y: topInset + 37 * scale)

                chakraProgressStrip(scale: scale)
                    .padding(.horizontal, 24 * scale)
                    .offset(y: topInset + 111 * scale)

                Text("Keep transmuting")
                    .font(.system(size: 12 * scale, weight: .regular, design: .default))
                    .tracking(-0.12 * scale)
                    .foregroundStyle(HomeColors.muted)
                    .frame(maxWidth: .infinity)
                    .offset(y: topInset + 184 * scale)
            }
            .offset(y: contentShift)
        }
        .frame(height: headerHeight + stretch, alignment: .top)
        .clipShape(panelShape)
        .contentShape(panelShape)
    }

    private func updateElasticOverscroll(_ amount: CGFloat, scale: CGFloat) {
        dashboardOverscroll = max(amount, 0)
        defer { previousOverscroll = dashboardOverscroll }

        guard isStretchingHeader,
              dashboardOverscroll > previousOverscroll,
              dashboardOverscroll > 8 * scale else {
            if dashboardOverscroll <= 0.5 {
                previousOverscroll = 0
                elasticHapticStep = 0
            }
            return
        }

        let step = Int(dashboardOverscroll / max(13 * scale, 1))
        guard step > elasticHapticStep else { return }

        let intensity = min(0.16 + CGFloat(step) * 0.045, 0.48)
        HapticEngine.shared.elasticTick(intensity: intensity)
        elasticHapticStep = step
    }

    private func chakraProgressStrip(scale: CGFloat) -> some View {
        HStack(spacing: 5 * scale) {
            HStack(spacing: 0) {
                ForEach(visibleStages.indices, id: \.self) { index in
                    let item = visibleStages[index]
                    let isActive = item.activationDay == stage.activationDay

                    ZStack {
                        if isActive {
                            Circle()
                                .fill(item.color)
                                .frame(width: 47 * scale, height: 47 * scale)
                        }

                        Image(item.assetName)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundStyle(isActive ? Color.white : HomeColors.muted)
                            .frame(
                                width: (isActive ? 27 : 24) * scale,
                                height: (isActive ? 27 : 24) * scale
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56 * scale)
            .background(HomeColors.card, in: Capsule())

            HStack(spacing: 7 * scale) {
                Text("\(activeChakras)")
                    .foregroundStyle(.white)
                Rectangle()
                    .fill(HomeColors.muted)
                    .frame(width: 1, height: 15 * scale)
                Text("7")
                    .foregroundStyle(HomeColors.muted)
            }
            .font(.system(size: 15 * scale, weight: .regular, design: .default))
            .monospacedDigit()
            .frame(width: 56 * scale, height: 56 * scale)
            .background(HomeColors.card, in: Circle())
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Energia atual: \(stage.englishTitle). Centro \(activeChakras) de 7.")
    }

    private func cycleCard(scale: CGFloat) -> some View {
        Button {
            showCheckIn = true
            HapticEngine.shared.softPulse()
        } label: {
            HStack(spacing: 14 * scale) {
                VStack(alignment: .leading, spacing: 9 * scale) {
                    HStack(spacing: 8 * scale) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11 * scale, weight: .medium))
                        Text("Since \(profile.startDate.cortexEnglishLongDate)")
                            .font(.system(size: 14 * scale, weight: .regular, design: .default))
                            .tracking(-0.17 * scale)
                    }
                    .foregroundStyle(.white)

                    Text(nextEnergyText)
                        .font(.system(size: 13 * scale, weight: .regular, design: .default))
                        .tracking(-0.14 * scale)
                        .foregroundStyle(HomeColors.muted)
                }

                Spacer(minLength: 8 * scale)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [HomeColors.control.opacity(0.98), HomeColors.control.opacity(0.78)],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 74 * scale
                            )
                        )
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.035), lineWidth: 1)
                        )

                    VStack(spacing: -2 * scale) {
                        Text("\(snapshot.currentDay)")
                            .font(.system(size: 34 * scale, weight: .medium, design: .default))
                            .tracking(-0.55 * scale)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text(snapshot.currentDay == 1 ? "Dia" : "Dias")
                            .font(.system(size: 12 * scale, weight: .regular, design: .default))
                            .foregroundStyle(HomeColors.muted)
                    }
                }
                .frame(width: 92 * scale, height: 92 * scale)
            }
            .padding(.leading, 34 * scale)
            .padding(.trailing, 16 * scale)
            .frame(maxWidth: .infinity, minHeight: 120 * scale, maxHeight: 120 * scale)
            .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 27 * scale, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 27 * scale, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(snapshot.currentDay) dias desde \(profile.startDate.cortexEnglishLongDate). Toque para adicionar uma observação opcional.")
    }

    private func currentEnergyCard(scale: CGFloat) -> some View {
        Image(stage.cardAssetName)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .aspectRatio(699.0 / 383.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(height: 194 * scale)
            .id(stage.cardAssetName)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current energy: \(stage.englishTitle)")
    }

    private func recoveredTimeCard(scale: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 16 * scale) {
            Label {
                Text("Recovered time")
            } icon: {
                Image(systemName: "clock.arrow.circlepath")
            }
            .font(.system(size: 13 * scale, weight: .regular, design: .default))
            .tracking(-0.14 * scale)
            .foregroundStyle(HomeColors.muted)

            Spacer(minLength: 8 * scale)

            Text(recoveredTimeText)
                .font(.system(size: 34 * scale, weight: .medium, design: .default))
                .tracking(-0.60 * scale)
                .monospacedDigit()
                .foregroundStyle(HomeColors.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 34 * scale)
        .frame(maxWidth: .infinity, minHeight: 120 * scale, maxHeight: 120 * scale)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 27 * scale, style: .continuous))
    }

    private func dashboardSummaryCards(scale: CGFloat) -> some View {
        HStack(spacing: 14 * scale) {
            compactMetricCard(
                title: "Goal",
                value: "\(goalRemainingDays)",
                subtitle: goalRemainingDays == 1 ? "day remaining" : "days remaining",
                systemImage: "scope",
                scale: scale
            )

            compactMetricCard(
                title: "Notes",
                value: "\(savedNotesCount)",
                subtitle: savedNotesCount == 1 ? "note saved" : "notes saved",
                systemImage: "note.text",
                scale: scale
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func compactMetricCard(
        title: String,
        value: String,
        subtitle: String,
        systemImage: String,
        scale: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
            .font(.system(size: 13 * scale, weight: .regular, design: .default))
            .tracking(-0.14 * scale)
            .foregroundStyle(HomeColors.muted)

            Spacer().frame(height: 15 * scale)

            Text(value)
                .font(.system(size: 34 * scale, weight: .medium, design: .default))
                .tracking(-0.55 * scale)
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer().frame(height: 9 * scale)

            Text(subtitle)
                .font(.system(size: 12 * scale, weight: .regular, design: .default))
                .tracking(-0.12 * scale)
                .foregroundStyle(HomeColors.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 138 * scale, maxHeight: 138 * scale)
        .background(
            HomeColors.card,
            in: RoundedRectangle(cornerRadius: 27 * scale, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }

    private func addTodayNoteCard(scale: CGFloat) -> some View {
        Button {
            showCheckIn = true
            HapticEngine.shared.softPulse()
        } label: {
            HStack(spacing: 17 * scale) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 22 * scale, weight: .regular))
                    .foregroundStyle(HomeColors.muted)
                    .frame(width: 28 * scale)

                VStack(alignment: .leading, spacing: 4 * scale) {
                    Text("Add today's note")
                        .font(.system(size: 16 * scale, weight: .regular, design: .default))
                        .tracking(-0.22 * scale)
                        .foregroundStyle(.white)

                    Text("A fun fact about your day of transmutation")
                        .font(.system(size: 12 * scale, weight: .regular, design: .default))
                        .tracking(-0.12 * scale)
                        .foregroundStyle(HomeColors.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 8 * scale)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14 * scale, weight: .medium))
                    .foregroundStyle(HomeColors.muted)
            }
            .padding(.horizontal, 27 * scale)
            .frame(maxWidth: .infinity, minHeight: 87 * scale, maxHeight: 87 * scale)
            .background(
                HomeColors.card,
                in: RoundedRectangle(cornerRadius: 27 * scale, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 27 * scale, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Adicionar observação de hoje")
    }

    private var goalRemainingDays: Int {
        max(profile.targetDays - snapshot.currentDay, 0)
    }

    private var savedNotesCount: Int {
        checkIns.filter { checkIn in
            checkIn.status == .aligned &&
            !checkIn.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    private var visibleStages: [TransmutationStage] {
        let activeIndex = max(0, activeChakras - 1)
        let start = min(max(activeIndex - 2, 0), max(TransmutationStage.all.count - 5, 0))
        return Array(TransmutationStage.all[start..<min(start + 5, TransmutationStage.all.count)])
    }

    private var todayObservation: DailyCheckIn? {
        checkIns.first {
            Calendar.current.isDateInToday($0.date) && $0.status == .aligned
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Good Morning,"
        case 12..<18: return "Good Afternoon,"
        default: return "Good Evening,"
        }
    }

    private var nextEnergyText: String {
        guard let nextDay = TransmutationStage.nextActivationDay(after: snapshot.currentDay) else {
            return "All energies are active"
        }
        let remaining = max(nextDay - snapshot.currentDay, 0)
        if remaining == 0 { return "Next energy today" }
        return remaining == 1 ? "Next energy in 1 day" : "Next energy in \(remaining) days"
    }

    private var recoveredTimeText: String {
        let totalMinutes = max(0, Int((snapshot.hoursRecovered * 60).rounded(.down)))
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours < 24 {
            return minutes == 0 ? "\(hours) h" : "\(hours) h \(minutes) min"
        }

        let days = hours / 24
        let remainingHours = hours % 24
        return remainingHours == 0 ? "\(days) d" : "\(days) d \(remainingHours) h"
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

private enum DashboardScrollSpace {
    static let name = "DashboardScrollSpace"
}

private struct DashboardOverscrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private enum HomeMetrics {
    static let headerContentHeight: CGFloat = 211
    static let cardInset: CGFloat = 10
    static let cardGap: CGFloat = 17

    static func scale(for width: CGFloat) -> CGFloat {
        min(max(width / 375, 0.88), 1.12)
    }
}

private enum HomeColors {
    static let welcomeDark = Color(red: 38 / 255, green: 38 / 255, blue: 38 / 255)
    static let welcomeMid = Color(red: 87 / 255, green: 87 / 255, blue: 87 / 255)
    static let welcomeLight = Color(red: 106 / 255, green: 106 / 255, blue: 106 / 255)
    static let card = Color(red: 14 / 255, green: 14 / 255, blue: 14 / 255)
    static let control = Color(red: 35 / 255, green: 35 / 255, blue: 35 / 255)
    static let muted = Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255)
    static let statusGreen = Color(red: 19 / 255, green: 168 / 255, blue: 61 / 255)
}

private extension Date {
    var cortexEnglishLongDate: String {
        Self.cortexEnglishLongFormatter.string(from: self)
    }

    static let cortexEnglishLongFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
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
    let englishTitle: String
    let color: Color
    let assetName: String
    let cardAssetName: String

    static let all: [TransmutationStage] = [
        .init(activationDay: 1, englishTitle: "Root Chakra", color: Color(red: 168 / 255, green: 19 / 255, blue: 18 / 255), assetName: "ChakraRoot", cardAssetName: "CurrentEnergyRoot"),
        .init(activationDay: 5, englishTitle: "Sacral Chakra", color: Color(red: 208 / 255, green: 93 / 255, blue: 2 / 255), assetName: "ChakraSacral", cardAssetName: "CurrentEnergySacral"),
        .init(activationDay: 10, englishTitle: "Solar Plexus Chakra", color: Color(red: 240 / 255, green: 156 / 255, blue: 34 / 255), assetName: "ChakraSolar", cardAssetName: "CurrentEnergySolar"),
        .init(activationDay: 15, englishTitle: "Heart Chakra", color: Color(red: 57 / 255, green: 141 / 255, blue: 24 / 255), assetName: "ChakraHeart", cardAssetName: "CurrentEnergyHeart"),
        .init(activationDay: 21, englishTitle: "Throat Chakra", color: Color(red: 15 / 255, green: 158 / 255, blue: 226 / 255), assetName: "ChakraThroat", cardAssetName: "CurrentEnergyThroat"),
        .init(activationDay: 30, englishTitle: "Third Eye Chakra", color: Color(red: 131 / 255, green: 58 / 255, blue: 247 / 255), assetName: "ChakraThirdEye", cardAssetName: "CurrentEnergyThirdEye"),
        .init(activationDay: 90, englishTitle: "Crown Chakra", color: Color(red: 249 / 255, green: 249 / 255, blue: 247 / 255), assetName: "ChakraCrown", cardAssetName: "CurrentEnergyCrown")
    ]

    static func activeCount(for day: Int) -> Int {
        let safeDay = max(day, 1)
        let count = all.filter { safeDay >= $0.activationDay }.count
        return min(max(count, 1), all.count)
    }

    static func nextActivationDay(after day: Int) -> Int? {
        all.first { $0.activationDay > max(day, 1) }?.activationDay
    }
}

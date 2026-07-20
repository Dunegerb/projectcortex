import SwiftUI
import WidgetKit

struct CortexWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CortexWidgetSnapshot

    var currentDay: Int {
        guard let start = snapshot.cycleStartDate else { return max(snapshot.currentDay, 0) }
        let elapsedSeconds = max(0, date.timeIntervalSince(start))
        return Int(elapsedSeconds / 86_400)
    }

    var progress: Double {
        guard let start = snapshot.cycleStartDate,
              let targetDays = snapshot.targetDays,
              targetDays > 0 else {
            return snapshot.recoveryScore
        }
        let targetSpan = Double(max(targetDays, 1))
        return min(max(Double(currentDay) / targetSpan, 0), 1)
    }

    var transmutationState: String {
        switch progress {
        case ..<0.25: return "INÍCIO"
        case ..<0.55: return "EM FLUXO"
        case ..<0.82: return "INTEGRAÇÃO"
        default: return "CONSOLIDADO"
        }
    }
}

struct CortexWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CortexWidgetEntry {
        CortexWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CortexWidgetEntry) -> Void) {
        completion(CortexWidgetEntry(date: Date(), snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CortexWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = loadSnapshot()
        let entry = CortexWidgetEntry(date: now, snapshot: snapshot)
        let refresh = nextRefreshDate(after: now, snapshot: snapshot)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func nextRefreshDate(after date: Date, snapshot: CortexWidgetSnapshot) -> Date {
        guard let start = snapshot.cycleStartDate else {
            return date.addingTimeInterval(1_800)
        }

        let elapsedSeconds = max(0, date.timeIntervalSince(start))
        let completedDays = floor(elapsedSeconds / 86_400)
        return start.addingTimeInterval((completedDays + 1) * 86_400 + 1)
    }

    private func loadSnapshot() -> CortexWidgetSnapshot {
        let defaults = UserDefaults(suiteName: CortexShared.appGroup) ?? .standard
        guard let data = defaults.data(forKey: CortexShared.snapshotKey),
              let snapshot = try? JSONDecoder().decode(CortexWidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }
}

struct CortexWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CortexWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 12) {
            HStack {
                Image(systemName: "figure.mind.and.body")
                Text("CÓRTEX")
                    .cortexTextStyle(.caption1)
                Spacer()
                Text("D\(entry.currentDay)")
                    .cortexTextStyle(.caption1)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Text(entry.transmutationState)
                .cortexTextStyle(.caption2)
                .foregroundStyle(.cyan)
            Text(entry.progress, format: .percent.precision(.fractionLength(0)))
                .cortexTextStyle(.largeTitle)
                .monospacedDigit()
            ProgressView(value: entry.progress)
                .tint(.cyan)

            Link(destination: CortexShared.emergencyURL) {
                Label("Emergência", systemImage: "lifepreserver.fill")
                    .cortexTextStyle(.caption1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(.red.opacity(0.78), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .containerBackground(for: .widget) {
            CortexPalette.secondary
        }
    }
}

struct CortexWidget: Widget {
    let kind = "CortexWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CortexWidgetProvider()) { entry in
            CortexWidgetView(entry: entry)
        }
        .configurationDisplayName("Transmutação")
        .description("Mostra o ciclo automático e abre o protocolo de emergência.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

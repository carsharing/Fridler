import SwiftUI
import UIKit
import WidgetKit

/// Shows whether the app and the widget found the same shared storage, which
/// is the part sideloading is most likely to break.
struct DiagnosticsCard: View {
    @EnvironmentObject private var model: FridgeModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var heartbeat: FridgeStore.WidgetHeartbeat?
    @State private var copied = false

    private let group = AppGroup.current

    var body: some View {
        CartoonCard(title: "Behind the fridge") {
            row("Shared storage", group.identifier ?? "not found ✗")
            row("Found via", group.source.rawValue)
            row("Saved", model.lastSaveFailed ? "failed ✗" : format(model.lastSaved ?? nilIfEpoch(model.doc.updatedAt)))
            row("Widget last drew", heartbeat.map { "\(format($0.date)) · \($0.family)" } ?? "not yet")
            if let heartbeat, heartbeat.appGroupSource != group.source.rawValue {
                row("Widget found via", heartbeat.appGroupSource)
            }

            HStack(spacing: 10) {
                Button("Redraw widget") {
                    model.saveNow()
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        refresh()
                    }
                }
                Button(copied ? "Copied!" : "Copy report") {
                    UIPasteboard.general.string = report
                    copied = true
                }
            }
            .buttonStyle(.bordered)
            .tint(Palette.ink)
            .font(.callout.weight(.semibold))
        }
        .onAppear { refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
        .onChange(of: model.lastSaved) { _, _ in
            // The widget redraws a moment after each save.
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                refresh()
            }
        }
    }

    private func refresh() {
        heartbeat = model.store.lastWidgetRender()
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.ink.opacity(0.55))
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .textSelection(.enabled)
        }
    }

    private func nilIfEpoch(_ date: Date) -> Date? {
        date.timeIntervalSince1970 > 0 ? date : nil
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "never" }
        return date.formatted(date: .abbreviated, time: .standard)
    }

    private var report: String {
        [
            "Fridler \(Bundle.main.appVersion)",
            "iOS \(UIDevice.current.systemVersion)",
            "Bundle: \(Bundle.main.bundleIdentifier ?? "?")",
            "App group: \(group.identifier ?? "none") via \(group.source.rawValue)",
            "Tried: \(group.tried.joined(separator: ", "))",
            "Widget last drew: \(heartbeat.map { "\(format($0.date)) \($0.family) via \($0.appGroupSource)" } ?? "never")",
        ].joined(separator: "\n")
    }
}

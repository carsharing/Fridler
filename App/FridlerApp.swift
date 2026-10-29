import SwiftUI
import WidgetKit

@main
struct FridlerApp: App {
    @StateObject private var model = FridgeModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(model)
                .onOpenURL { _ in model.reload() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: model.reload()
            case .background: model.saveNow()
            default: break
            }
        }
    }
}

/// The app's copy of the fridge. Edits are saved shortly after they happen
/// and the widget is asked to redraw.
@MainActor
final class FridgeModel: ObservableObject {
    @Published var doc: FridgeDoc {
        didSet {
            if doc != oldValue && !isReloading { scheduleSave() }
        }
    }
    @Published private(set) var lastSaved: Date?
    @Published private(set) var lastSaveFailed = false

    let store: FridgeStore
    private var pendingSave: Task<Void, Never>?
    private var isReloading = false

    init(store: FridgeStore = .shared) {
        self.store = store
        self.doc = store.load()
    }

    /// Picks up changes made elsewhere (later: taps on the widget).
    /// Unsaved edits in the app win.
    func reload() {
        guard pendingSave == nil else { return }
        isReloading = true
        doc = store.load()
        isReloading = false
    }

    func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        lastSaveFailed = !store.save(doc)
        if !lastSaveFailed { lastSaved = Date() }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }
}

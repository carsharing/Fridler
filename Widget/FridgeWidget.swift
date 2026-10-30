import SwiftUI
import WidgetKit

@main
struct FridlerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FridgeWidget()
    }
}

struct FridgeWidget: Widget {
    let kind = "FridgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FridgeProvider()) { entry in
            FridgeWidgetView(entry: entry)
        }
        .configurationDisplayName("Fridge")
        .description("A doodle hanging on your fridge.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct FridgeEntry: TimelineEntry {
    let date: Date
    let doc: FridgeDoc
    let hasSharedStorage: Bool
    /// Full-color picture of the scene for Clear and Tinted home screens.
    let picture: UIImage?
}

struct FridgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> FridgeEntry {
        FridgeEntry(date: Date(), doc: FridgeDoc(), hasSharedStorage: true, picture: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (FridgeEntry) -> Void) {
        let size = context.displaySize
        let family = "\(context.family)"
        Task { @MainActor in
            completion(Self.makeEntry(size: size, family: family))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FridgeEntry>) -> Void) {
        let size = context.displaySize
        let family = "\(context.family)"
        Task { @MainActor in
            let entry = Self.makeEntry(size: size, family: family)
            let refresh = Calendar.current.date(byAdding: .hour, value: 3, to: entry.date) ?? entry.date
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    @MainActor
    private static func makeEntry(size: CGSize, family: String) -> FridgeEntry {
        let store = FridgeStore.shared
        let doc = store.load()
        store.recordWidgetRender(family: family)
        let picture = SceneRenderer.image(
            doc: doc,
            size: size,
            showsDoor: doc.clearModeStyle == .fridgeDoor
        )
        return FridgeEntry(
            date: Date(),
            doc: doc,
            hasSharedStorage: store.directory != nil,
            picture: picture
        )
    }
}

struct FridgeWidgetView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: FridgeEntry

    var body: some View {
        ZStack(alignment: .bottom) {
            if renderingMode != .fullColor, let picture = entry.picture {
                Image(uiImage: picture)
                    .resizable()
                    .widgetAccentedRenderingMode(.fullColor)
            } else {
                FridgeScene(doc: entry.doc, showsDoor: false)
            }
            if !entry.hasSharedStorage {
                Text("Open Fridler: no shared storage")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.paper)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Palette.markerRed))
                    .padding(.bottom, 4)
            }
        }
        .containerBackground(for: .widget) {
            FridgeDoorView(color: entry.doc.fridgeColor)
        }
        .widgetURL(URL(string: "fridler://draw"))
    }
}

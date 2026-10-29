import SwiftUI
import UIKit

/// The whole picture: fridge door, a sheet of paper and the magnet holding it.
///
/// Plain SwiftUI drawn relative to its own size, so the widget, the app
/// preview and the snapshot tests all draw exactly the same thing.
struct FridgeScene: View {
    var doc: FridgeDoc
    var showsDoor: Bool = true

    var body: some View {
        GeometryReader { geo in
            let layout = SceneLayout(size: geo.size)
            ZStack {
                if showsDoor {
                    FridgeDoorView(color: doc.fridgeColor)
                }
                PaperView(doc: doc, unit: layout.unit)
                    .frame(width: layout.paper.width, height: layout.paper.height)
                    .rotationEffect(.degrees(layout.paperTilt))
                    .position(x: layout.paper.midX, y: layout.paper.midY)
                MagnetView(kind: doc.magnet, unit: layout.unit)
                    .frame(width: layout.magnetSize.width, height: layout.magnetSize.height)
                    .rotationEffect(.degrees(layout.magnetTilt))
                    .position(layout.magnetCenter)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Where things go, in points, for a scene of a given size.
struct SceneLayout {
    let size: CGSize

    /// 1% of the short side: every size, line and font is a multiple of it.
    var unit: CGFloat { min(size.width, size.height) / 100 }

    var paper: CGRect {
        let insetX = max(size.width * 0.11, 9 * unit)
        let top = 15 * unit
        let bottom = 9 * unit
        return CGRect(
            x: insetX,
            y: top,
            width: max(0, size.width - 2 * insetX),
            height: max(0, size.height - top - bottom)
        )
    }

    var paperTilt: Double { -2 }

    var magnetSize: CGSize { CGSize(width: 18 * unit, height: 21 * unit) }
    var magnetCenter: CGPoint { CGPoint(x: paper.midX + 2 * unit, y: paper.minY + 2 * unit) }
    var magnetTilt: Double { 7 }
}

/// Home-screen widget sizes on a large iPhone, in points.
enum WidgetSize: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large: CGSize(width: 364, height: 382)
        }
    }

    var title: String { rawValue.capitalized }
}

enum SceneRenderer {
    /// A full-color picture of the scene. Home screens set to Clear or Tinted
    /// recolor every shape in a widget but leave full-color images alone.
    @MainActor
    static func image(doc: FridgeDoc, size: CGSize, showsDoor: Bool, scale: CGFloat = 3) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let renderer = ImageRenderer(
            content: FridgeScene(doc: doc, showsDoor: showsDoor)
                .frame(width: size.width, height: size.height)
        )
        renderer.scale = scale
        renderer.isOpaque = showsDoor
        return renderer.uiImage
    }
}

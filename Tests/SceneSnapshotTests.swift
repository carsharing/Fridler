import SwiftUI
import XCTest
@testable import Fridler

/// Pictures of the widget at every size. Names start with the version that
/// introduced them, so older looks stay pinned while new ones are added.
final class SceneSnapshotTests: XCTestCase {
    @MainActor
    func testDefaultFridgeAtEverySize() {
        for size in WidgetSize.allCases {
            Snapshot.check(FridgeScene(doc: FridgeDoc()), size: size.size, named: "v0.1-default-\(size.rawValue)")
        }
    }

    @MainActor
    func testEveryFridgeColor() {
        for color in FridgeColor.allCases {
            var doc = FridgeDoc()
            doc.fridgeColor = color
            doc.note = color.name
            Snapshot.check(FridgeScene(doc: doc), size: WidgetSize.medium.size, named: "v0.1-color-\(color.rawValue)")
        }
    }

    @MainActor
    func testLongNoteAndEmptyNote() {
        var doc = FridgeDoc()
        doc.note = "don't forget the milk and also the cat's birthday party"
        Snapshot.check(FridgeScene(doc: doc), size: WidgetSize.small.size, named: "v0.1-long-note-small")

        doc.note = ""
        Snapshot.check(FridgeScene(doc: doc), size: WidgetSize.large.size, named: "v0.1-no-note-large")
    }

    @MainActor
    func testPaperOnGlass() {
        Snapshot.check(
            ZStack {
                LinearGradient(colors: [.purple, .orange], startPoint: .top, endPoint: .bottom)
                FridgeScene(doc: FridgeDoc(), showsDoor: false)
            },
            size: WidgetSize.large.size,
            named: "v0.1-paper-on-glass-large"
        )
    }

    // MARK: v0.2

    @MainActor
    func testDrawingAtEverySize() {
        var doc = FridgeDoc()
        doc.drawing = TestDrawings.cat
        doc.note = "meow"
        for size in WidgetSize.allCases {
            Snapshot.check(FridgeScene(doc: doc), size: size.size, named: "v0.2-drawing-\(size.rawValue)")
        }
    }

    @MainActor
    func testWipedPaperKeepsTheNote() {
        var doc = FridgeDoc()
        doc.drawing = Drawing()
        doc.note = "nothing to see here"
        Snapshot.check(FridgeScene(doc: doc), size: WidgetSize.large.size, named: "v0.2-wiped-large")
    }

    @MainActor
    func testDrawingScreen() {
        let editor = DrawingEditor(drawing: TestDrawings.cat)
        editor.ink = .blue
        Snapshot.check(
            ZStack {
                FridgeDoorView(color: .mint)
                VStack(spacing: 18) {
                    DrawingBoard(editor: editor)
                    ToolTray(editor: editor) {}
                }
                .padding(16)
            },
            size: CGSize(width: 390, height: 560),
            named: "v0.2-drawing-screen"
        )
    }

    @MainActor
    func testRendererMakesFullColorPicture() {
        let picture = SceneRenderer.image(doc: FridgeDoc(), size: WidgetSize.small.size, showsDoor: true)
        XCTAssertEqual(picture?.size, WidgetSize.small.size)
        XCTAssertNil(SceneRenderer.image(doc: FridgeDoc(), size: .zero, showsDoor: true))
    }
}

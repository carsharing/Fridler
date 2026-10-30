import XCTest
@testable import Fridler

final class DrawingTests: XCTestCase {
    func testStraightLineIsSimplifiedToItsEnds() {
        var drawing = Drawing()
        let line = (0...50).map { CGPoint(x: 10 + CGFloat($0), y: 20) }
        XCTAssertTrue(drawing.add(line, ink: .red, size: 2.6))
        XCTAssertEqual(drawing.strokes.count, 1)
        XCTAssertEqual(drawing.strokes[0].points, [100, 200, 600, 200])
        XCTAssertEqual(drawing.strokes[0].ink, .red)
    }

    func testCornersSurviveSimplification() {
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 5, y: 0), CGPoint(x: 10, y: 0), CGPoint(x: 10, y: 5), CGPoint(x: 10, y: 10)]
        XCTAssertEqual(Drawing.simplify(points, tolerance: 0.35), [points[0], points[2], points[4]])
    }

    func testTapMakesADot() {
        var drawing = Drawing()
        drawing.add([CGPoint(x: 3, y: 4), CGPoint(x: 3.01, y: 4)], ink: .black, size: 2.6)
        XCTAssertEqual(drawing.strokes.first?.points, [30, 40])
    }

    func testEraserRemovesOnlyTouchedStrokes() {
        var drawing = Drawing()
        drawing.add([CGPoint(x: 10, y: 10), CGPoint(x: 50, y: 10)], ink: .black, size: 2.6)
        drawing.add([CGPoint(x: 10, y: 80), CGPoint(x: 50, y: 80)], ink: .blue, size: 2.6)

        XCTAssertFalse(drawing.erase(near: CGPoint(x: 30, y: 45), radius: 3))
        XCTAssertTrue(drawing.erase(near: CGPoint(x: 30, y: 12), radius: 3))
        XCTAssertEqual(drawing.strokes.map(\.ink), [.blue])
    }

    func testFullPaperRefusesMoreStrokes() {
        var drawing = Drawing(strokes: [Stroke(points: Array(repeating: 5, count: Drawing.maxPointValues))])
        XCTAssertFalse(drawing.add([CGPoint(x: 1, y: 1), CGPoint(x: 9, y: 9)], ink: .black, size: 2.6))
        XCTAssertEqual(drawing.strokes.count, 1)
    }

    func testRunsGroupNeighboursWithTheSameMarker() {
        let drawing = Drawing(strokes: [
            Stroke(ink: .black, size: 2.6, points: [0, 0]),
            Stroke(ink: .black, size: 2.6, points: [1, 1]),
            Stroke(ink: .red, size: 2.6, points: [2, 2]),
            Stroke(ink: .black, size: 2.6, points: [3, 3]),
        ])
        XCTAssertEqual(drawing.runs.map(\.strokes.count), [2, 1, 1])
    }

    func testBoxPointMapsBackFromTheScreen() {
        let space = SketchSpace(CGRect(x: 0, y: 0, width: 250, height: 300))
        let back = space.boxPoint(space(40, 60))
        XCTAssertEqual(back.x, 40, accuracy: 0.001)
        XCTAssertEqual(back.y, 60, accuracy: 0.001)
        XCTAssertEqual(space.boxPoint(CGPoint(x: -50, y: 9999)), CGPoint(x: 0, y: 100))
    }

    func testLenientDecoding() throws {
        let json = #"{"drawing": {"strokes": [{"ink": "glitter", "points": [10, 20, 30]}, {"size": "big"}]}}"#
        let doc = try FridgeStore.decoder.decode(FridgeDoc.self, from: Data(json.utf8))
        let strokes = try XCTUnwrap(doc.drawing?.strokes)
        XCTAssertEqual(strokes.count, 2)
        XCTAssertEqual(strokes[0].ink, .black)
        XCTAssertEqual(strokes[0].boxPoints, [CGPoint(x: 1, y: 2)])
        XCTAssertEqual(strokes[1].size, MarkerSize.marker.width)
    }

    func testOlderFilesHaveNoDrawing() throws {
        let doc = try FridgeStore.decoder.decode(FridgeDoc.self, from: Data(#"{"note": "hi"}"#.utf8))
        XCTAssertNil(doc.drawing)
    }

    func testDrawingSurvivesSaveAndCanBeRemoved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FridgeStore(directory: directory)

        var doc = FridgeDoc()
        doc.drawing = TestDrawings.cat
        XCTAssertTrue(store.save(doc))
        XCTAssertEqual(store.load().drawing, TestDrawings.cat)

        doc.drawing = nil
        XCTAssertTrue(store.save(doc))
        XCTAssertNil(store.load().drawing)
    }

    @MainActor
    func testEditorUndoRedoAndWipe() {
        var saved: [Drawing] = []
        let editor = DrawingEditor(drawing: Drawing()) { saved.append($0) }

        editor.drag(to: CGPoint(x: 10, y: 10))
        editor.drag(to: CGPoint(x: 40, y: 30))
        editor.endDrag()
        XCTAssertEqual(editor.drawing.strokes.count, 1)
        XCTAssertTrue(editor.canUndo)

        editor.wipe()
        XCTAssertTrue(editor.drawing.strokes.isEmpty)

        editor.undo()
        XCTAssertEqual(editor.drawing.strokes.count, 1)
        editor.redo()
        XCTAssertTrue(editor.drawing.strokes.isEmpty)

        editor.undo()
        editor.erasing = true
        editor.drag(to: CGPoint(x: 25, y: 20))
        editor.endDrag()
        XCTAssertTrue(editor.drawing.strokes.isEmpty)
        XCTAssertEqual(saved.count, 6)
    }
}

/// Drawings built from code, for tests and snapshots.
enum TestDrawings {
    static func stroke(_ ink: InkColor, _ size: MarkerSize = .marker, _ points: [(CGFloat, CGFloat)]) -> Stroke {
        Stroke(ink: ink, size: size.width, boxPoints: points.map { CGPoint(x: $0.0, y: $0.1) })
    }

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, from: Double = 0, to: Double = 360) -> [(CGFloat, CGFloat)] {
        stride(from: from, through: to, by: 15).map {
            (cx + r * CGFloat(cos($0 * .pi / 180)), cy + r * CGFloat(sin($0 * .pi / 180)))
        }
    }

    /// A cat face in all four markers.
    static let cat = Drawing(strokes: [
        stroke(.black, .marker, circle(62, 56, 30)),
        stroke(.black, .marker, [(38, 40), (40, 14), (56, 27)]),
        stroke(.black, .marker, [(68, 27), (84, 14), (86, 40)]),
        stroke(.green, .chunky, [(51, 50)]),
        stroke(.green, .chunky, [(73, 50)]),
        stroke(.red, .marker, [(58, 60), (66, 60), (62, 65), (58, 60)]),
        stroke(.blue, .marker, circle(62, 64, 9, from: 30, to: 150)),
        stroke(.black, .fine, [(44, 62), (22, 58)]),
        stroke(.black, .fine, [(44, 66), (23, 68)]),
        stroke(.black, .fine, [(80, 62), (102, 58)]),
        stroke(.black, .fine, [(80, 66), (101, 68)]),
    ])
}

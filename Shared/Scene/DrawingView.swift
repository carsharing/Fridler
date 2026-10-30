import SwiftUI

/// What's drawn on the paper: the person's drawing, or the sample doodle
/// until they've drawn something.
struct DoodleView: View {
    var drawing: Drawing?
    var sampleLineWidth: CGFloat

    var body: some View {
        if let drawing {
            DrawingView(drawing: drawing)
        } else {
            SampleDoodle(lineWidth: sampleLineWidth)
        }
    }
}

/// Renders a `Drawing` in the 125 × 100 sketch box, aspect fit.
struct DrawingView: View, Equatable {
    var drawing: Drawing

    var body: some View {
        GeometryReader { geo in
            let space = SketchSpace(CGRect(origin: .zero, size: geo.size))
            ZStack {
                ForEach(Array(drawing.runs.enumerated()), id: \.offset) { _, run in
                    StrokesShape(strokes: run.strokes)
                        .stroke(run.ink.color, style: MarkerStyle.stroke(width: CGFloat(run.size) * space.scale))
                }
            }
        }
        .aspectRatio(SketchSpace.box.width / SketchSpace.box.height, contentMode: .fit)
    }
}

enum MarkerStyle {
    static func stroke(width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}

struct StrokesShape: Shape {
    var strokes: [Stroke]

    func path(in rect: CGRect) -> Path {
        let space = SketchSpace(rect)
        var path = Path()
        for stroke in strokes {
            path.addSmoothLine(through: stroke.boxPoints.map { space($0.x, $0.y) })
        }
        return path
    }
}

/// A stroke still being drawn, in sketch-box units.
struct LiveStrokeShape: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        let space = SketchSpace(rect)
        var path = Path()
        path.addSmoothLine(through: points.map { space($0.x, $0.y) })
        return path
    }
}

extension Path {
    /// Curves through the midpoints between samples so strokes look like
    /// marker lines rather than polygons. A single point becomes a dot.
    mutating func addSmoothLine(through points: [CGPoint]) {
        guard let first = points.first else { return }
        move(to: first)
        if points.count == 1 {
            addLine(to: CGPoint(x: first.x + 0.01, y: first.y))
            return
        }
        if points.count > 2 {
            for i in 1..<(points.count - 1) {
                let next = points[i + 1]
                let mid = CGPoint(x: (points[i].x + next.x) / 2, y: (points[i].y + next.y) / 2)
                addQuadCurve(to: mid, control: points[i])
            }
        }
        addLine(to: points[points.count - 1])
    }
}

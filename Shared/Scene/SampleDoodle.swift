import SwiftUI

/// The marker drawing on the paper until people draw their own (v0.2):
/// a house, a sun, a flower and a little red heart.
struct SampleDoodle: View {
    var lineWidth: CGFloat

    var body: some View {
        let marker = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        ZStack {
            HouseSketch().stroke(Palette.marker, style: marker)
            HeartSketch().fill(Palette.markerRed)
        }
        .aspectRatio(SketchSpace.box.width / SketchSpace.box.height, contentMode: .fit)
    }
}

/// Maps points drawn in a 125×100 box onto `rect` (aspect fit, centered).
struct SketchSpace {
    static let box = CGSize(width: 125, height: 100)

    let scale: CGFloat
    let origin: CGPoint

    init(_ rect: CGRect) {
        scale = min(rect.width / Self.box.width, rect.height / Self.box.height)
        origin = CGPoint(
            x: rect.midX - Self.box.width * scale / 2,
            y: rect.midY - Self.box.height * scale / 2
        )
    }

    func callAsFunction(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    /// The inverse: a point in `rect` to sketch-box units, clamped to the box.
    func boxPoint(_ point: CGPoint) -> CGPoint {
        guard scale > 0 else { return .zero }
        return CGPoint(
            x: min(max((point.x - origin.x) / scale, 0), Self.box.width),
            y: min(max((point.y - origin.y) / scale, 0), Self.box.height)
        )
    }

    func circle(_ x: CGFloat, _ y: CGFloat, r: CGFloat) -> CGRect {
        CGRect(x: origin.x + (x - r) * scale, y: origin.y + (y - r) * scale, width: 2 * r * scale, height: 2 * r * scale)
    }
}

struct HouseSketch: Shape {
    func path(in rect: CGRect) -> Path {
        let s = SketchSpace(rect)
        var p = Path()

        func line(_ points: [(CGFloat, CGFloat)]) {
            guard let first = points.first else { return }
            p.move(to: s(first.0, first.1))
            for point in points.dropFirst() { p.addLine(to: s(point.0, point.1)) }
        }

        // Sun
        p.addEllipse(in: s.circle(18, 18, r: 8))
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 + 0.2
            let (c, d) = (CGFloat(cos(angle)), CGFloat(sin(angle)))
            p.move(to: s(18 + 11.5 * c, 18 + 11.5 * d))
            p.addLine(to: s(18 + 16 * c, 18 + 16 * d))
        }

        // House, slightly wonky like a real marker drawing
        line([(46, 46), (47, 88), (96, 87), (95, 45)])
        line([(40, 48), (70, 21), (101, 47)])
        line([(42, 47.5), (99, 46)])
        line([(84, 33), (84, 20), (91, 20.5), (91, 39)])
        line([(62, 87.5), (62, 67), (75, 67.5), (75, 87)])
        p.addEllipse(in: s.circle(72, 78, r: 0.9))
        line([(80, 55), (91, 55), (91, 65), (80, 65), (80, 55)])
        line([(85.5, 55), (85.5, 65)])
        line([(80, 60), (91, 60)])
        line([(50, 55), (57, 55), (57, 62), (50, 62), (50, 55)])

        // Chimney smoke
        p.move(to: s(88, 16))
        p.addQuadCurve(to: s(91, 10), control: s(84, 12))
        p.addQuadCurve(to: s(95, 4), control: s(97, 8))

        // Flower
        line([(21, 89), (20.5, 69)])
        for i in 0..<5 {
            let angle = Double(i) * 2 * .pi / 5 - .pi / 2
            p.addEllipse(in: s.circle(20.5 + 4.6 * CGFloat(cos(angle)), 64 + 4.6 * CGFloat(sin(angle)), r: 3.2))
        }
        p.move(to: s(20.8, 81))
        p.addQuadCurve(to: s(13, 77), control: s(15, 83))

        // Wavy ground
        p.move(to: s(4, 90))
        var x: CGFloat = 4
        var up = true
        while x < 118 {
            p.addQuadCurve(to: s(x + 13, 90), control: s(x + 6.5, up ? 87.5 : 92.5))
            x += 13
            up.toggle()
        }
        return p
    }
}

struct HeartSketch: Shape {
    func path(in rect: CGRect) -> Path {
        let s = SketchSpace(rect)
        let (cx, cy): (CGFloat, CGFloat) = (112, 22)
        var p = Path()
        p.move(to: s(cx, cy + 6))
        p.addCurve(to: s(cx, cy - 2.5), control1: s(cx - 9, cy - 1), control2: s(cx - 4.5, cy - 8.5))
        p.addCurve(to: s(cx, cy + 6), control1: s(cx + 4.5, cy - 8.5), control2: s(cx + 9, cy - 1))
        p.closeSubpath()
        return p
    }
}

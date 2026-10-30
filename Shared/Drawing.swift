import SwiftUI

/// Marker colors. Saved by raw value, so cases are only ever added.
enum InkColor: String, Codable, CaseIterable, Identifiable {
    case black, red, blue, green

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .black: Palette.marker
        case .red: Palette.markerRed
        case .blue: Color(hex: 0x2F6FDB)
        case .green: Color(hex: 0x2E9E5B)
        }
    }

    var name: String { rawValue.capitalized }
}

/// Marker tip widths, in sketch-box units (the box is 125 × 100).
enum MarkerSize: String, CaseIterable, Identifiable {
    case fine, marker, chunky

    var id: String { rawValue }

    var width: Double {
        switch self {
        case .fine: 1.7
        case .marker: 2.6
        case .chunky: 4.2
        }
    }
}

/// A freehand drawing, stored as strokes in the same 125 × 100 sketch box
/// as the sample doodle so it fits every widget size the same way.
struct Drawing: Codable, Equatable {
    /// Keeps the saved file (and the widget's memory) small.
    static let maxPointValues = 24_000

    var strokes: [Stroke] = []

    init(strokes: [Stroke] = []) {
        self.strokes = strokes
    }

    enum CodingKeys: String, CodingKey {
        case strokes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        strokes = c.value(.strokes, default: [])
    }

    var pointValueCount: Int { strokes.reduce(0) { $0 + $1.points.count } }

    /// Adds a stroke drawn through `points` (sketch-box units).
    /// Returns false, adding nothing, when the paper is full.
    @discardableResult
    mutating func add(_ points: [CGPoint], ink: InkColor, size: Double) -> Bool {
        let stroke = Stroke(ink: ink, size: size, boxPoints: Self.simplify(points, tolerance: 0.35))
        guard !stroke.points.isEmpty else { return true }
        guard pointValueCount + stroke.points.count <= Self.maxPointValues else { return false }
        strokes.append(stroke)
        return true
    }

    /// Removes every stroke passing within `radius` of `point`.
    @discardableResult
    mutating func erase(near point: CGPoint, radius: CGFloat) -> Bool {
        let count = strokes.count
        strokes.removeAll { $0.passes(near: point, within: radius + CGFloat($0.size) / 2) }
        return strokes.count != count
    }

    /// Consecutive strokes sharing ink and size, drawn as one shape each.
    struct Run {
        var ink: InkColor
        var size: Double
        var strokes: [Stroke]
    }

    var runs: [Run] {
        var runs: [Run] = []
        for stroke in strokes {
            if let last = runs.last, last.ink == stroke.ink, last.size == stroke.size {
                runs[runs.count - 1].strokes.append(stroke)
            } else {
                runs.append(Run(ink: stroke.ink, size: stroke.size, strokes: [stroke]))
            }
        }
        return runs
    }

    /// Ramer–Douglas–Peucker: drops points that stay within `tolerance` of
    /// the line through their neighbours.
    static func simplify(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var keep = [Bool](repeating: false, count: points.count)
        keep[0] = true
        keep[points.count - 1] = true
        var pending = [(0, points.count - 1)]
        while let range = pending.popLast() {
            let (start, end) = range
            guard end > start + 1 else { continue }
            var farthest = start
            var maxDistance: CGFloat = 0
            for i in (start + 1)..<end {
                let distance = segmentDistance(points[i], points[start], points[end])
                if distance > maxDistance {
                    maxDistance = distance
                    farthest = i
                }
            }
            if maxDistance > tolerance {
                keep[farthest] = true
                pending.append((start, farthest))
                pending.append((farthest, end))
            }
        }
        return points.indices.filter { keep[$0] }.map { points[$0] }
    }
}

struct Stroke: Codable, Equatable {
    var ink: InkColor = .black
    var size: Double = MarkerSize.marker.width
    /// x0, y0, x1, y1… in tenths of a sketch-box unit.
    var points: [Int] = []

    init(ink: InkColor = .black, size: Double = MarkerSize.marker.width, points: [Int] = []) {
        self.ink = ink
        self.size = size
        self.points = points
    }

    /// Rounds to tenths and drops repeated points.
    init(ink: InkColor, size: Double, boxPoints: [CGPoint]) {
        var values: [Int] = []
        for point in boxPoints {
            let x = Int((point.x * 10).rounded())
            let y = Int((point.y * 10).rounded())
            if values.count >= 2, values[values.count - 2] == x, values[values.count - 1] == y { continue }
            values.append(contentsOf: [x, y])
        }
        self.init(ink: ink, size: size, points: values)
    }

    enum CodingKeys: String, CodingKey {
        case ink, size, points
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Stroke()
        ink = c.value(.ink, default: defaults.ink)
        size = c.value(.size, default: defaults.size)
        points = c.value(.points, default: defaults.points)
    }

    var boxPoints: [CGPoint] {
        stride(from: 0, to: points.count - 1, by: 2).map {
            CGPoint(x: CGFloat(points[$0]) / 10, y: CGFloat(points[$0 + 1]) / 10)
        }
    }

    func passes(near point: CGPoint, within radius: CGFloat) -> Bool {
        let path = boxPoints
        guard let first = path.first else { return false }
        if path.count == 1 { return hypot(point.x - first.x, point.y - first.y) <= radius }
        for i in 1..<path.count where segmentDistance(point, path[i - 1], path[i]) <= radius {
            return true
        }
        return false
    }
}

/// Distance from `p` to the segment `a`–`b`.
func segmentDistance(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = b.x - a.x
    let dy = b.y - a.y
    let lengthSquared = dx * dx + dy * dy
    guard lengthSquared > 0 else { return hypot(p.x - a.x, p.y - a.y) }
    let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared))
    return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
}

import SwiftUI

/// A patch of fridge door with two cartoon shine stripes.
struct FridgeDoorView: View {
    var color: FridgeColor

    var body: some View {
        ZStack {
            Rectangle().fill(color.door)
            ShineBands().fill(color.shine)
        }
        .clipped()
    }
}

struct ShineBands: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let slant = rect.height * 0.35
        for (start, width) in [(0.52, 0.10), (0.66, 0.035)] as [(CGFloat, CGFloat)] {
            let left = rect.minX + rect.width * start
            let right = left + rect.width * width
            path.move(to: CGPoint(x: left + slant, y: rect.minY))
            path.addLine(to: CGPoint(x: right + slant, y: rect.minY))
            path.addLine(to: CGPoint(x: right, y: rect.maxY))
            path.addLine(to: CGPoint(x: left, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

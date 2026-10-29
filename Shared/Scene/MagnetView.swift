import SwiftUI

/// Every magnet that can hold the paper. New magnets are new cases; existing
/// raw values never change because they are saved in the fridge file.
enum MagnetKind: String, Codable, CaseIterable, Identifiable {
    case pizza

    var id: String { rawValue }

    var name: String {
        switch self {
        case .pizza: "Pizza slice"
        }
    }
}

struct MagnetView: View {
    var kind: MagnetKind
    var unit: CGFloat

    var body: some View {
        Group {
            switch kind {
            case .pizza: PizzaMagnet(unit: unit)
            }
        }
        .compositingGroup()
        .shadow(color: Palette.shadow, radius: 0, x: 0.8 * unit, y: 1.3 * unit)
    }
}

// MARK: - Pizza slice

struct PizzaMagnet: View {
    var unit: CGFloat

    private static let cheese = Color(hex: 0xFFC94A)
    private static let crust = Color(hex: 0xD98E3E)
    private static let pepperoni = Color(hex: 0xD6453D)

    /// Pepperoni as (x, y, radius) relative to the magnet's width/height.
    private static let toppings: [(CGFloat, CGFloat, CGFloat)] = [
        (0.38, 0.42, 0.10), (0.63, 0.47, 0.085), (0.49, 0.68, 0.07),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let line = StrokeStyle(lineWidth: max(1, 0.7 * unit), lineJoin: .round)
            ZStack {
                PizzaSliceShape().fill(Self.cheese)
                PizzaSliceShape().stroke(Palette.ink, style: line)
                ForEach(Self.toppings.indices, id: \.self) { i in
                    let topping = Self.toppings[i]
                    Circle().fill(Self.pepperoni)
                        .overlay(Circle().stroke(Palette.ink, style: line))
                        .frame(width: 2 * topping.2 * w, height: 2 * topping.2 * w)
                        .position(x: topping.0 * w, y: topping.1 * h)
                }
                RoundedRectangle(cornerRadius: h * 0.12, style: .continuous)
                    .fill(Self.crust)
                    .overlay(
                        RoundedRectangle(cornerRadius: h * 0.12, style: .continuous)
                            .stroke(Palette.ink, style: line)
                    )
                    .frame(width: w, height: h * 0.27)
                    .position(x: w / 2, y: h * 0.135)
                Capsule().fill(Color.white.opacity(0.55))
                    .frame(width: w * 0.34, height: h * 0.045)
                    .position(x: w * 0.34, y: h * 0.085)
            }
        }
    }
}

struct PizzaSliceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.07, y: rect.minY + rect.height * 0.15))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.93, y: rect.minY + rect.height * 0.15))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.98))
        path.closeSubpath()
        return path
    }
}

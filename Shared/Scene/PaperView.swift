import SwiftUI

/// A sheet of paper with a dog-eared corner, the doodle and the note.
struct PaperView: View {
    var doc: FridgeDoc
    var unit: CGFloat

    private var outline: CGFloat { max(1, 0.8 * unit) }

    var body: some View {
        GeometryReader { geo in
            let fold = 8 * unit
            let wide = geo.size.width > geo.size.height * 1.45
            ZStack {
                DogEaredSheet(fold: fold).fill(Palette.paper)
                content(wide: wide)
                    .padding(.top, (wide ? 8 : 10) * unit)
                    .padding(.horizontal, 6 * unit)
                    .padding(.bottom, 6 * unit)
                DogEaredSheet(fold: fold)
                    .stroke(Palette.ink, style: StrokeStyle(lineWidth: outline, lineJoin: .round))
                DogEarFlap(fold: fold).fill(Palette.paperShade)
                DogEarFlap(fold: fold)
                    .stroke(Palette.ink, style: StrokeStyle(lineWidth: outline, lineJoin: .round))
            }
        }
        .compositingGroup()
        .shadow(color: Palette.shadow, radius: 0, x: 1.2 * unit, y: 1.8 * unit)
    }

    @ViewBuilder
    private func content(wide: Bool) -> some View {
        let doodle = DoodleView(drawing: doc.drawing, sampleLineWidth: max(1.2, 0.9 * unit))
        if doc.note.isEmpty {
            doodle
        } else if wide {
            HStack(spacing: 4 * unit) {
                doodle
                note
            }
        } else {
            VStack(spacing: 2 * unit) {
                doodle
                // Keeps long notes clear of the folded corner.
                note
                    .padding(.horizontal, 2 * unit)
                    .layoutPriority(1)
            }
        }
    }

    private var note: some View {
        Text(doc.note)
            .font(.custom("MarkerFelt-Wide", size: 8 * unit))
            .foregroundStyle(Palette.marker)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.4)
            .layoutPriority(1)
    }
}

struct DogEaredSheet: Shape {
    var fold: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - fold))
        path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The folded-over corner flap.
struct DogEarFlap: Shape {
    var fold: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - fold))
        path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.maxY - fold))
        path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

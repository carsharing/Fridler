import SwiftUI

/// Full-screen paper to draw on with markers. Every finished stroke is saved
/// and hung on the fridge right away.
struct DrawView: View {
    @ObservedObject var model: FridgeModel
    @StateObject private var editor: DrawingEditor
    @State private var confirmWipe = false

    init(model: FridgeModel) {
        self.model = model
        _editor = StateObject(wrappedValue: DrawingEditor(drawing: model.doc.drawing ?? Drawing()) { [weak model] in
            model?.doc.drawing = $0
        })
    }

    var body: some View {
        ZStack {
            FridgeDoorView(color: model.doc.fridgeColor)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                topBar
                DrawingBoard(editor: editor)
                if editor.isFull {
                    Text("This paper is full: erase something or wipe it.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.paper)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Palette.markerRed))
                }
                ToolTray(editor: editor) { confirmWipe = true }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .preferredColorScheme(.light)
        .confirmationDialog("Wipe the paper clean?", isPresented: $confirmWipe, titleVisibility: .visible) {
            Button("Wipe it", role: .destructive) { editor.wipe() }
        } message: {
            Text("You can still undo it.")
        }
    }

    private var topBar: some View {
        HStack {
            Text("Draw")
                .font(.custom("MarkerFelt-Wide", size: 34))
                .foregroundStyle(model.doc.fridgeColor.isDark ? Palette.paper : Palette.ink)
            Spacer()
            Button {
                model.saveNow()
                model.isDrawing = false
            } label: {
                Text("Hang it up")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
            }
            .buttonStyle(CartoonButtonStyle(fill: Palette.markerRed, text: Palette.paper))
        }
    }
}

/// The paper itself, taking marker strokes or erasing them.
struct DrawingBoard: View {
    @ObservedObject var editor: DrawingEditor

    var body: some View {
        let sheet = DogEaredSheet(fold: 22)
        GeometryReader { geo in
            let space = SketchSpace(CGRect(origin: .zero, size: geo.size))
            ZStack {
                DrawingView(drawing: editor.drawing)
                    .equatable()
                if !editor.livePoints.isEmpty {
                    LiveStrokeShape(points: editor.livePoints)
                        .stroke(
                            editor.ink.color,
                            style: MarkerStyle.stroke(width: CGFloat(editor.size.width) * space.scale)
                        )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { editor.drag(to: space.boxPoint($0.location)) }
                    .onEnded { _ in editor.endDrag() }
            )
        }
        .aspectRatio(SketchSpace.box.width / SketchSpace.box.height, contentMode: .fit)
        .padding(14)
        .background(sheet.fill(Palette.paper))
        .overlay(sheet.stroke(Palette.ink, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)))
        .overlay(DogEarFlap(fold: 22).fill(Palette.paperShade))
        .overlay(DogEarFlap(fold: 22).stroke(Palette.ink, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)))
        .background(sheet.fill(Palette.cardShadow).offset(x: 4, y: 5))
    }
}

/// Marker caps, tip sizes, eraser, undo/redo and wipe.
struct ToolTray: View {
    @ObservedObject var editor: DrawingEditor
    var onWipe: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ForEach(InkColor.allCases) { ink in
                    let selected = !editor.erasing && editor.ink == ink
                    Button {
                        editor.ink = ink
                        editor.erasing = false
                    } label: {
                        Circle()
                            .fill(ink.color)
                            .frame(width: selected ? 30 : 24, height: selected ? 30 : 24)
                    }
                    .buttonStyle(CartoonButtonStyle(selected: selected))
                    .accessibilityLabel("\(ink.name) marker")
                }
                Spacer(minLength: 0)
                Button {
                    editor.erasing.toggle()
                } label: {
                    Image(systemName: "eraser.fill")
                        .font(.system(size: 21, weight: .bold))
                }
                .buttonStyle(CartoonButtonStyle(selected: editor.erasing))
                .accessibilityLabel("Eraser")
            }

            HStack(spacing: 12) {
                ForEach(MarkerSize.allCases) { size in
                    let selected = editor.size == size
                    Button {
                        editor.size = size
                    } label: {
                        Circle()
                            .fill(Palette.ink)
                            .frame(width: CGFloat(size.width) * 3.2, height: CGFloat(size.width) * 3.2)
                    }
                    .buttonStyle(CartoonButtonStyle(selected: selected))
                    .accessibilityLabel("\(size.rawValue.capitalized) tip")
                }
                Spacer(minLength: 0)
                Button { editor.undo() } label: {
                    Image(systemName: "arrow.uturn.backward").font(.system(size: 19, weight: .bold))
                }
                .buttonStyle(CartoonButtonStyle())
                .disabled(!editor.canUndo)
                .accessibilityLabel("Undo")
                Button { editor.redo() } label: {
                    Image(systemName: "arrow.uturn.forward").font(.system(size: 19, weight: .bold))
                }
                .buttonStyle(CartoonButtonStyle())
                .disabled(!editor.canRedo)
                .accessibilityLabel("Redo")
                Button { onWipe() } label: {
                    Image(systemName: "trash.fill").font(.system(size: 19, weight: .bold))
                }
                .buttonStyle(CartoonButtonStyle())
                .disabled(editor.drawing.strokes.isEmpty)
                .accessibilityLabel("Wipe the paper")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.paper))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.ink, lineWidth: 2.5))
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.cardShadow).offset(x: 3, y: 4))
    }
}

/// Chunky round-cornered button with an outline and a hard shadow that
/// squashes flat when pressed.
struct CartoonButtonStyle: ButtonStyle {
    var fill: Color = Palette.paper
    var text: Color = Palette.ink
    var selected = false

    func makeBody(configuration: Configuration) -> some View {
        CartoonButton(configuration: configuration, fill: selected ? Color(hex: 0xFFE07A) : fill, text: text)
    }

    private struct CartoonButton: View {
        let configuration: ButtonStyleConfiguration
        let fill: Color
        let text: Color
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
            let lift: CGFloat = configuration.isPressed ? 0 : 3
            configuration.label
                .foregroundStyle(text)
                .frame(minWidth: 44, minHeight: 44)
                .background(shape.fill(fill))
                .overlay(shape.stroke(Palette.ink, lineWidth: 2.5))
                .background(shape.fill(Palette.cardShadow).offset(x: lift, y: lift))
                .offset(x: 3 - lift, y: 3 - lift)
                .opacity(isEnabled ? 1 : 0.4)
                .animation(.spring(duration: 0.15), value: configuration.isPressed)
        }
    }
}

/// Drawing state while the paper is open: the drawing, the stroke in
/// progress, the chosen tool and the undo history.
@MainActor
final class DrawingEditor: ObservableObject {
    @Published private(set) var drawing: Drawing
    @Published private(set) var livePoints: [CGPoint] = []
    @Published var ink: InkColor = .black
    @Published var size: MarkerSize = .marker
    @Published var erasing = false
    @Published private(set) var isFull = false

    private var undoStack: [Drawing] = []
    private var redoStack: [Drawing] = []
    private var beforeErasing: Drawing?
    private let onChange: @MainActor (Drawing) -> Void

    init(drawing: Drawing, onChange: @escaping @MainActor (Drawing) -> Void = { _ in }) {
        self.drawing = drawing
        self.onChange = onChange
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func drag(to point: CGPoint) {
        if erasing {
            if beforeErasing == nil { beforeErasing = drawing }
            drawing.erase(near: point, radius: 3)
        } else {
            livePoints.append(point)
        }
    }

    func endDrag() {
        if let before = beforeErasing {
            beforeErasing = nil
            if before != drawing { commit(from: before) }
        } else if !livePoints.isEmpty {
            let before = drawing
            if drawing.add(livePoints, ink: ink, size: size.width) {
                if before != drawing { commit(from: before) }
            } else {
                isFull = true
            }
            livePoints = []
        }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(drawing)
        drawing = previous
        changed()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(drawing)
        drawing = next
        changed()
    }

    func wipe() {
        guard !drawing.strokes.isEmpty else { return }
        let before = drawing
        drawing = Drawing()
        commit(from: before)
    }

    private func commit(from before: Drawing) {
        undoStack.append(before)
        if undoStack.count > 60 { undoStack.removeFirst() }
        redoStack.removeAll()
        changed()
    }

    private func changed() {
        isFull = false
        onChange(drawing)
    }
}

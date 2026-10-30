import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: FridgeModel
    @State private var previewSize: WidgetSize = .large
    @State private var previewClear = false

    var body: some View {
        ZStack {
            FridgeDoorView(color: model.doc.fridgeColor)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    previewCard
                    drawCard
                    noteCard
                    colorCard
                    clearModeCard
                    DiagnosticsCard()
                    Text("Fridler \(Bundle.main.appVersion)")
                        .font(.custom("MarkerFelt-Thin", size: 14))
                        .foregroundStyle(onDoor.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $model.isDrawing) {
            DrawView(model: model)
        }
    }

    /// Text drawn straight on the door.
    private var onDoor: Color { model.doc.fridgeColor.isDark ? Palette.paper : Palette.ink }

    private var header: some View {
        VStack(spacing: 2) {
            Text("Fridler")
                .font(.custom("MarkerFelt-Wide", size: 46))
            Text("the fridge on your home screen")
                .font(.custom("MarkerFelt-Thin", size: 17))
        }
        .foregroundStyle(onDoor)
        .padding(.top, 8)
    }

    private var previewCard: some View {
        CartoonCard(title: "On your fridge") {
            Picker("Widget size", selection: $previewSize) {
                ForEach(WidgetSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            }
            .pickerStyle(.segmented)

            let size = previewSize.size
            let widgetShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
            ZStack {
                if previewClear {
                    LinearGradient(
                        colors: [Color(hex: 0x8FB3E0), Color(hex: 0x6E7F55)],
                        startPoint: .top, endPoint: .bottom
                    )
                    widgetShape.fill(.ultraThinMaterial)
                }
                FridgeScene(doc: model.doc, showsDoor: !previewClear || model.doc.clearModeStyle == .fridgeDoor)
            }
            .aspectRatio(size.width / size.height, contentMode: .fit)
            .frame(maxWidth: size.width)
            .clipShape(widgetShape)
            .overlay(widgetShape.stroke(Palette.ink, lineWidth: 2.5))
            .frame(maxWidth: .infinity)
            .animation(.spring(duration: 0.35), value: previewSize)

            Toggle("Preview a Clear home screen", isOn: $previewClear.animation())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .tint(Palette.markerRed)
        }
    }

    private var drawCard: some View {
        CartoonCard(title: "Draw on the paper") {
            Button {
                model.isDrawing = true
            } label: {
                Label("Grab a marker", systemImage: "pencil.tip")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CartoonButtonStyle(fill: Palette.markerRed, text: Palette.paper))
            Text("Tip: tapping the widget opens the paper straight away.")
                .font(.footnote)
                .foregroundStyle(Palette.ink.opacity(0.6))
        }
    }

    private var noteCard: some View {
        CartoonCard(title: "Write on the paper") {
            TextField("Something for the fridge…", text: $model.doc.note)
                .font(.custom("MarkerFelt-Wide", size: 20))
                .foregroundStyle(Palette.marker)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.paperShade.opacity(0.45)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink, lineWidth: 2))
                .onChange(of: model.doc.note) { _, note in
                    if note.count > FridgeDoc.noteLimit {
                        model.doc.note = String(note.prefix(FridgeDoc.noteLimit))
                    }
                }
        }
    }

    private var colorCard: some View {
        CartoonCard(title: "Fridge color") {
            HStack(spacing: 10) {
                ForEach(FridgeColor.allCases) { color in
                    let selected = model.doc.fridgeColor == color
                    Button {
                        model.doc.fridgeColor = color
                    } label: {
                        Circle()
                            .fill(color.door)
                            .overlay(Circle().stroke(Palette.ink, lineWidth: selected ? 4 : 2))
                            .overlay {
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .black))
                                        .foregroundStyle(color.isDark ? Palette.paper : Palette.ink)
                                }
                            }
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color.name)
                }
            }
            .frame(maxWidth: .infinity)
            Text(model.doc.fridgeColor.name)
                .font(.custom("MarkerFelt-Thin", size: 16))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
        }
    }

    private var clearModeCard: some View {
        CartoonCard(title: "Clear & tinted home screens") {
            Picker("Clear mode", selection: $model.doc.clearModeStyle) {
                ForEach(ClearModeStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            Text("Only used when your home screen is set to Clear or Tinted (long-press the home screen → Edit → Customize). With the default look, the fridge door always shows. Use the preview toggle above to see both.")
                .font(.footnote)
                .foregroundStyle(Palette.ink.opacity(0.6))
        }
    }
}

/// Paper card with a thick outline and a hard offset shadow.
struct CartoonCard<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("MarkerFelt-Wide", size: 21))
                .foregroundStyle(Palette.ink)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(Palette.paper))
        .overlay(shape.stroke(Palette.ink, lineWidth: 2.5))
        .background(shape.fill(Palette.cardShadow).offset(x: 3, y: 4))
    }
}

extension Bundle {
    var appVersion: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }
}

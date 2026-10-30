import Foundation

/// Everything on the fridge, saved as JSON in the shared App Group.
///
/// Additive-only: every field has a default and is decoded leniently, and
/// fields are never renamed or removed. An older file (or one with a value a
/// newer version invented) still opens, so an update never wipes the fridge.
struct FridgeDoc: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = FridgeDoc.currentSchemaVersion
    var note: String = "hello fridge!"
    var fridgeColor: FridgeColor = .white
    var magnet: MagnetKind = .pizza
    var clearModeStyle: ClearModeStyle = .fridgeDoor
    var updatedAt: Date = Date(timeIntervalSince1970: 0)
    /// v0.2. `nil` until something is drawn: the paper shows the sample doodle.
    var drawing: Drawing? = nil

    static let noteLimit = 60

    init() {}

    enum CodingKeys: String, CodingKey, CaseIterable {
        case schemaVersion, note, fridgeColor, magnet, clearModeStyle, updatedAt
        case drawing
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = FridgeDoc()
        schemaVersion = c.value(.schemaVersion, default: defaults.schemaVersion)
        note = c.value(.note, default: defaults.note)
        fridgeColor = c.value(.fridgeColor, default: defaults.fridgeColor)
        magnet = c.value(.magnet, default: defaults.magnet)
        clearModeStyle = c.value(.clearModeStyle, default: defaults.clearModeStyle)
        updatedAt = c.value(.updatedAt, default: defaults.updatedAt)
        drawing = c.value(.drawing, default: defaults.drawing)
    }
}

/// How the widget looks when the home screen is set to Clear or Tinted.
enum ClearModeStyle: String, Codable, CaseIterable, Identifiable {
    /// Keep the colored fridge door inside the glass.
    case fridgeDoor
    /// Only the paper and magnet, floating on the glass.
    case paperOnGlass

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fridgeDoor: "Keep the fridge door"
        case .paperOnGlass: "Paper on glass"
        }
    }
}

extension KeyedDecodingContainer {
    /// The stored value when it is present and readable, otherwise `fallback`.
    func value<T: Decodable>(_ key: Key, default fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
}

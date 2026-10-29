import Foundation

/// Reads and writes the fridge in the shared App Group folder.
final class FridgeStore {
    static let shared = FridgeStore(directory: AppGroup.current.containerURL)

    /// `nil` when no App Group could be found; the fridge then only lives in memory.
    let directory: URL?

    init(directory: URL?) {
        self.directory = directory
    }

    private var docURL: URL? { directory?.appendingPathComponent("fridge.json") }
    private var heartbeatURL: URL? { directory?.appendingPathComponent("widget-heartbeat.json") }

    func load() -> FridgeDoc {
        guard let url = docURL, let data = try? Data(contentsOf: url) else { return FridgeDoc() }
        do {
            return try Self.decoder.decode(FridgeDoc.self, from: data)
        } catch {
            // Unreadable JSON: keep a copy rather than overwrite it on the next save.
            let backup = url.deletingLastPathComponent()
                .appendingPathComponent("fridge.unreadable-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: url, to: backup)
            return FridgeDoc()
        }
    }

    /// Saves `doc`, keeping any keys written by a newer version of the app
    /// so going back to an older build doesn't lose them.
    @discardableResult
    func save(_ doc: FridgeDoc) -> Bool {
        guard let url = docURL else { return false }
        var doc = doc
        doc.updatedAt = Date()
        do {
            let encoded = try Self.encoder.encode(doc)
            var merged = (try? Data(contentsOf: url)).flatMap {
                try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
            } ?? [:]
            if let fresh = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
                merged.merge(fresh) { _, new in new }
            }
            let data = try JSONSerialization.data(withJSONObject: merged, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    // MARK: Widget heartbeat (lets the app show when the widget last drew)

    struct WidgetHeartbeat: Codable {
        var date: Date
        var family: String
        var appGroupSource: String
    }

    func recordWidgetRender(family: String) {
        guard let url = heartbeatURL else { return }
        let beat = WidgetHeartbeat(date: Date(), family: family, appGroupSource: AppGroup.current.source.rawValue)
        if let data = try? Self.encoder.encode(beat) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func lastWidgetRender() -> WidgetHeartbeat? {
        guard let url = heartbeatURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? Self.decoder.decode(WidgetHeartbeat.self, from: data)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

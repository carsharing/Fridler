import Foundation

/// Finds the App Group folder shared by the app and the widget.
///
/// Sideloading re-signs the app and renames its App Group: AltStore turns
/// `group.io.github.carsharing.fridler` into `group.….fridler.<TEAMID>` and
/// writes the new name into each bundle's Info.plist under `ALTAppGroups`.
/// SideStore puts it only in the provisioning profile. The identifier we ship
/// with is therefore only the last thing we try.
enum AppGroup {
    static let baseIdentifier = "group.io.github.carsharing.fridler"

    enum Source: String {
        case altStoreInfoPlist = "AltStore Info.plist (ALTAppGroups)"
        case hostAppInfoPlist = "Host app Info.plist (ALTAppGroups)"
        case provisioningProfile = "Provisioning profile"
        case builtIn = "Built-in identifier"
        case none = "Not found"
    }

    struct Resolution {
        let identifier: String?
        let containerURL: URL?
        let source: Source
        let tried: [String]
    }

    static let current: Resolution = resolve()

    static func resolve(bundle: Bundle = .main, fileManager: FileManager = .default) -> Resolution {
        var candidates: [(Source, [String])] = [
            (.altStoreInfoPlist, altStoreGroups(in: bundle)),
        ]
        if let host = hostAppBundle(of: bundle) {
            candidates.append((.hostAppInfoPlist, altStoreGroups(in: host)))
        }
        candidates.append((.provisioningProfile, provisioningProfileGroups(in: bundle)))
        candidates.append((.builtIn, [baseIdentifier]))

        var tried: [String] = []
        for (source, identifiers) in candidates {
            for identifier in preferred(identifiers) where !tried.contains(identifier) {
                tried.append(identifier)
                if let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
                    return Resolution(identifier: identifier, containerURL: url, source: source, tried: tried)
                }
            }
        }
        return Resolution(identifier: nil, containerURL: nil, source: .none, tried: tried)
    }

    /// Our own group first, in case the bundle lists others.
    static func preferred(_ identifiers: [String]) -> [String] {
        identifiers.filter { $0.hasPrefix(baseIdentifier) } + identifiers.filter { !$0.hasPrefix(baseIdentifier) }
    }

    static func altStoreGroups(in bundle: Bundle) -> [String] {
        bundle.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] ?? []
    }

    /// The widget runs from `Fridler.app/PlugIns/FridlerWidget.appex`.
    static func hostAppBundle(of bundle: Bundle) -> Bundle? {
        guard bundle.bundleURL.pathExtension == "appex" else { return nil }
        return Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())
    }

    static func provisioningProfileGroups(in bundle: Bundle) -> [String] {
        guard let url = bundle.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url)
        else { return [] }
        return groups(fromProvisioningProfile: data)
    }

    /// A provisioning profile is a signed blob with a plain XML plist inside.
    static func groups(fromProvisioningProfile data: Data) -> [String] {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data.subdata(in: start.lowerBound..<end.upperBound), format: nil
              ) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any]
        else { return [] }
        return entitlements["com.apple.security.application-groups"] as? [String] ?? []
    }
}

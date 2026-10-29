import XCTest
@testable import Fridler

final class FridgeStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func decode(_ json: String) throws -> FridgeDoc {
        try FridgeStore.decoder.decode(FridgeDoc.self, from: Data(json.utf8))
    }

    func testEmptyFileGivesDefaults() throws {
        XCTAssertEqual(try decode("{}"), FridgeDoc())
    }

    func testUnknownValuesFallBackInsteadOfFailing() throws {
        let doc = try decode(#"{"note": "hi", "fridgeColor": "plaid", "magnet": "unicorn", "futureThing": 3}"#)
        XCTAssertEqual(doc.note, "hi")
        XCTAssertEqual(doc.fridgeColor, .white)
        XCTAssertEqual(doc.magnet, .pizza)
    }

    func testWrongTypeFallsBackForThatFieldOnly() throws {
        let doc = try decode(#"{"note": 42, "fridgeColor": "mint"}"#)
        XCTAssertEqual(doc.note, FridgeDoc().note)
        XCTAssertEqual(doc.fridgeColor, .mint)
    }

    func testSaveAndLoadRoundTrip() {
        let store = FridgeStore(directory: directory)
        var doc = FridgeDoc()
        doc.note = "pizza night"
        doc.fridgeColor = .cherry
        doc.clearModeStyle = .paperOnGlass
        XCTAssertTrue(store.save(doc))

        let loaded = store.load()
        XCTAssertEqual(loaded.note, "pizza night")
        XCTAssertEqual(loaded.fridgeColor, .cherry)
        XCTAssertEqual(loaded.clearModeStyle, .paperOnGlass)
        XCTAssertGreaterThan(loaded.updatedAt.timeIntervalSince1970, 0)
    }

    func testSaveKeepsKeysFromNewerVersions() throws {
        let url = directory.appendingPathComponent("fridge.json")
        try Data(#"{"note": "old", "stickers": ["star"]}"#.utf8).write(to: url)

        let store = FridgeStore(directory: directory)
        var doc = store.load()
        doc.note = "new"
        XCTAssertTrue(store.save(doc))

        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        XCTAssertEqual(json?["note"] as? String, "new")
        XCTAssertEqual(json?["stickers"] as? [String], ["star"])
    }

    func testUnreadableFileIsBackedUpNotLost() throws {
        let url = directory.appendingPathComponent("fridge.json")
        try Data("not json".utf8).write(to: url)

        XCTAssertEqual(FridgeStore(directory: directory).load(), FridgeDoc())
        let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("fridge.unreadable-") }
        XCTAssertEqual(backups.count, 1)
    }

    func testNoSharedStorageMeansDefaultsAndNoSave() {
        let store = FridgeStore(directory: nil)
        XCTAssertEqual(store.load(), FridgeDoc())
        XCTAssertFalse(store.save(FridgeDoc()))
    }

    func testWidgetHeartbeat() {
        let store = FridgeStore(directory: directory)
        XCTAssertNil(store.lastWidgetRender())
        store.recordWidgetRender(family: "systemLarge")
        XCTAssertEqual(store.lastWidgetRender()?.family, "systemLarge")
    }
}

final class AppGroupTests: XCTestCase {
    func testReadsGroupsFromProvisioningProfile() {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict>
        <key>Entitlements</key><dict>
        <key>com.apple.security.application-groups</key>
        <array><string>group.io.github.carsharing.fridler.ABCDE12345</string></array>
        </dict></dict></plist>
        """
        var data = Data([0x30, 0x82, 0x01, 0xFF, 0x00])
        data.append(Data(plist.utf8))
        data.append(Data([0x00, 0xA0, 0x82]))

        XCTAssertEqual(
            AppGroup.groups(fromProvisioningProfile: data),
            ["group.io.github.carsharing.fridler.ABCDE12345"]
        )
    }

    func testGarbageProfileGivesNothing() {
        XCTAssertEqual(AppGroup.groups(fromProvisioningProfile: Data("nope".utf8)), [])
    }

    func testOwnGroupIsTriedFirst() {
        XCTAssertEqual(
            AppGroup.preferred(["group.other", "group.io.github.carsharing.fridler.TEAM"]),
            ["group.io.github.carsharing.fridler.TEAM", "group.other"]
        )
    }
}

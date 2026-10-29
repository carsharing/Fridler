import SwiftUI
import UIKit
import XCTest

/// Renders views to PNG and compares them with the reference pictures in
/// `Snapshots/Reference`. Every render is also written to `Snapshots/Output`
/// so CI can publish it for review.
///
/// A view without a reference is only recorded. Once a picture is approved it
/// is copied into `Reference`, and from then on any visible change to it
/// fails the tests: that's the guard against regressions between versions.
enum Snapshot {
    static let folder = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Snapshots")

    /// Share of pixels allowed to differ (antialiasing, font rendering).
    static let tolerance = 0.005

    @MainActor
    static func check<V: View>(
        _ view: V,
        size: CGSize,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard let image = renderer.uiImage, let png = image.pngData() else {
            XCTFail("Could not render \(name)", file: file, line: line)
            return
        }

        let output = folder.appendingPathComponent("Output")
        try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try? png.write(to: output.appendingPathComponent("\(name).png"))

        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Snapshot \(name)") { $0.add(attachment) }

        let referenceURL = folder.appendingPathComponent("Reference/\(name).png")
        guard let data = try? Data(contentsOf: referenceURL), let reference = UIImage(data: data) else {
            print("📸 Recorded new snapshot \(name) (no reference yet)")
            return
        }
        let difference = Self.difference(image, reference)
        XCTAssertLessThanOrEqual(
            difference, tolerance,
            "\(name) changed: \(String(format: "%.2f", difference * 100))% of pixels differ from Snapshots/Reference",
            file: file, line: line
        )
    }

    /// Share of pixels whose color differs noticeably; 1 if the sizes differ.
    static func difference(_ a: UIImage, _ b: UIImage) -> Double {
        guard let pa = pixels(a), let pb = pixels(b), pa.width == pb.width, pa.height == pb.height else { return 1 }
        var changed = 0
        for i in stride(from: 0, to: pa.bytes.count, by: 4) {
            var delta = 0
            for channel in 0..<4 {
                delta = max(delta, abs(Int(pa.bytes[i + channel]) - Int(pb.bytes[i + channel])))
            }
            if delta > 24 { changed += 1 }
        }
        return Double(changed) / Double(pa.width * pa.height)
    }

    private static func pixels(_ image: UIImage) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let cg = image.cgImage else { return nil }
        let width = cg.width
        let height = cg.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? (bytes, width, height) : nil
    }
}

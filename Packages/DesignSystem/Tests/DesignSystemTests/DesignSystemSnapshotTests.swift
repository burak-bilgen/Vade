import Testing
import SwiftUI
import XCTest
@testable import DesignSystem

@Suite("Design System Snapshots")
struct DesignSystemSnapshotTests {

    @Test("Snapshot ActionPill active and inactive states")
    @MainActor
    func testActionPillSnapshots() throws {
        let accentPill = ActionPill(
            icon: "star.fill",
            title: "Aktif Hap",
            color: ColorTokens.accent,
            action: {}
        )
        
        let neutralPill = ActionPill(
            icon: "star",
            title: "Pasif Hap",
            color: ColorTokens.textSecondary,
            action: {}
        )
        
        // Assert active state
        try ViewSnapshotter.assertSnapshot(
            of: accentPill,
            named: "action_pill_active",
            size: CGSize(width: 140, height: 44)
        )
        
        // Assert inactive state
        try ViewSnapshotter.assertSnapshot(
            of: neutralPill,
            named: "action_pill_inactive",
            size: CGSize(width: 140, height: 44)
        )
    }

    @Test("Snapshot StatCard component")
    @MainActor
    func testStatCardSnapshot() throws {
        let card = StatCard(
            value: "42",
            label: "Test İstatistiği",
            icon: "bolt.fill",
            color: ColorTokens.positive
        )
        
        try ViewSnapshotter.assertSnapshot(
            of: card,
            named: "stat_card",
            size: CGSize(width: 120, height: 90)
        )
    }

    @Test("Snapshot GlassCard with sample contents")
    @MainActor
    func testGlassCardSnapshot() throws {
        let card = GlassCard(
            title: "Cam Kart Başlığı",
            subtitle: "Hafif alt yazı açıklaması",
            icon: "lock.fill",
            accentColor: ColorTokens.accent
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kart İçeriği Satır 1")
                    .font(.caption)
                    .foregroundColor(ColorTokens.textPrimary)
                Text("Kart İçeriği Satır 2")
                    .font(.caption)
                    .foregroundColor(ColorTokens.textSecondary)
            }
            .padding(.vertical, 8)
        }
        
        try ViewSnapshotter.assertSnapshot(
            of: card,
            named: "glass_card",
            size: CGSize(width: 350, height: 180)
        )
    }
}

// MARK: - Native View Snapshotter Utility

public struct ViewSnapshotter {
    /// Renders a SwiftUI view to a PNG image of a specified size and compares it with a reference image.
    @MainActor
    public static func assertSnapshot<V: View>(
        of view: V,
        named name: String,
        size: CGSize,
        recording: Bool = false,
        sourceFilePath: String = #filePath
    ) throws {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2.0 // render at @2x for pixel precision
        
        guard let image = renderer.uiImage else {
            throw SnapshotError.renderingFailed
        }
        
        guard let pngData = image.pngData() else {
            throw SnapshotError.pngConversionFailed
        }
        
        let testFileURL = URL(fileURLWithPath: sourceFilePath)
        let referenceDirURL = testFileURL
            .deletingLastPathComponent()
            .appendingPathComponent("ReferenceImages", isDirectory: true)
        
        // Ensure reference directory exists
        try FileManager.default.createDirectory(at: referenceDirURL, withIntermediateDirectories: true)
        
        let referenceImageURL = referenceDirURL.appendingPathComponent("\(name).png")
        
        // If reference doesn't exist, record it automatically
        if recording || !FileManager.default.fileExists(atPath: referenceImageURL.path) {
            try pngData.write(to: referenceImageURL)
            print("📸 Snapshot reference recorded: \(referenceImageURL.path)")
            return
        }
        
        // Load reference image
        let referenceData = try Data(contentsOf: referenceImageURL)
        
        // Compare pixel/data hashes
        if pngData != referenceData {
            let failureDirURL = referenceDirURL
                .deletingLastPathComponent()
                .appendingPathComponent("SnapshotFailures", isDirectory: true)
            try FileManager.default.createDirectory(at: failureDirURL, withIntermediateDirectories: true)
            
            let failureImageURL = failureDirURL.appendingPathComponent("\(name)_failed.png")
            try pngData.write(to: failureImageURL)
            
            let referenceCopyURL = failureDirURL.appendingPathComponent("\(name)_reference.png")
            try referenceData.write(to: referenceCopyURL)
            
            throw SnapshotError.mismatch(referenceURL: referenceImageURL, failureURL: failureImageURL)
        }
    }
}

public enum SnapshotError: Error, CustomStringConvertible {
    case renderingFailed
    case pngConversionFailed
    case mismatch(referenceURL: URL, failureURL: URL)
    
    public var description: String {
        switch self {
        case .renderingFailed:
            return "Failed to render the SwiftUI view using ImageRenderer."
        case .pngConversionFailed:
            return "Failed to extract PNG data from the rendered image."
        case .mismatch(let ref, let fail):
            return "Snapshot mismatch. Reference: \(ref.path). Failure copy saved at: \(fail.path)"
        }
    }
}

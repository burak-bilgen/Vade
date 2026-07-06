import SwiftUI

/// Typography system using Apple's SF Pro with semantic roles.
/// SF Pro provides full Turkish glyph support and all weights from ultralight to black.
/// Monospaced digits (.monospaced) used for amounts to ensure tabular alignment.
public enum Typography {
    public enum FontRole {
        case display       // Large hero amounts
        case title1         // Screen titles
        case title2         // Section headers
        case headline       // Row titles, primary text
        case body           // Body text
        case amount         // Monetary amounts (monospaced digits)
        case caption        // Secondary/label text
        case label          // Tiny labels
    }

    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            Font.system(size: 36, weight: .light, design: .default)
        case .title1:
            Font.system(size: 28, weight: .bold, design: .default)
        case .title2:
            Font.system(size: 20, weight: .semibold, design: .default)
        case .headline:
            Font.system(size: 17, weight: .semibold, design: .default)
        case .body:
            Font.system(size: 16, weight: .regular, design: .default)
        case .amount:
            Font.system(size: 16, weight: .medium, design: .monospaced)
        case .caption:
            Font.system(size: 13, weight: .regular, design: .default)
        case .label:
            Font.system(size: 11, weight: .medium, design: .default)
        }
    }
}

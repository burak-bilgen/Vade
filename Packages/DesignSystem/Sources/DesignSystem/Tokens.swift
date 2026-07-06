import SwiftUI

// MARK: - Spacing Tokens

public enum Spacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

// MARK: - Radius Tokens

public enum Radius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
    public static let pill: CGFloat = 999
}

// MARK: - Design System Colors

extension Color {
    // Ink (primary text / brand)
    public static let vdInk900 = Color(red: 27/255, green: 35/255, blue: 64/255)
    public static let vdInk700 = Color(red: 75/255, green: 81/255, blue: 112/255)
    public static let vdInk400 = Color(red: 138/255, green: 143/255, blue: 174/255)

    // Background / Surface
    public static let vdBackground = Color(red: 245/255, green: 246/255, blue: 248/255)
    public static let vdSurface = Color(white: 1.0)
    public static let vdHairline = Color(red: 227/255, green: 229/255, blue: 236/255)
    public static let vdLedgerLine = Color(red: 211/255, green: 214/255, blue: 224/255)

    // Brass (signature accent — gold tracking)
    public static let vdBrass500 = Color(red: 184/255, green: 134/255, blue: 58/255)
    public static let vdBrass300 = Color(red: 237/255, green: 217/255, blue: 175/255)
    public static let vdBrass700 = Color(red: 143/255, green: 101/255, blue: 38/255)

    // Positive (receivable)
    public static let vdPositive600 = Color(red: 31/255, green: 122/255, blue: 92/255)
    public static let vdPositive100 = Color(red: 220/255, green: 240/255, blue: 231/255)

    // Negative (payable)
    public static let vdNegative600 = Color(red: 193/255, green: 72/255, blue: 59/255)
    public static let vdNegative100 = Color(red: 248/255, green: 225/255, blue: 222/255)

    // Dark mode variants
    public static let vdDarkBackground = Color(red: 16/255, green: 18/255, blue: 28/255)
    public static let vdDarkSurface = Color(red: 26/255, green: 29/255, blue: 44/255)
    public static let vdDarkHairline = Color(red: 43/255, green: 47/255, blue: 69/255)
    public static let vdDarkTextPrimary = Color(red: 242/255, green: 241/255, blue: 237/255)
    public static let vdDarkTextSecondary = Color(red: 172/255, green: 175/255, blue: 199/255)
    public static let vdDarkBrass500 = Color(red: 209/255, green: 163/255, blue: 86/255)
    public static let vdDarkPositive600 = Color(red: 63/255, green: 169/255, blue: 128/255)
    public static let vdDarkNegative600 = Color(red: 226/255, green: 105/255, blue: 90/255)
}

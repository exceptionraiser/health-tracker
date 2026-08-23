import SwiftUI

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    static let paper = Color(hex: 0xEAE3D1)
    static let card = Color(hex: 0xF3EEE0)
    static let line = Color(hex: 0xCFC5AA)
    static let ink = Color(hex: 0x232F4B)
    static let sub = Color(hex: 0x6E6752)
    static let red = Color(hex: 0xBE3D2A)
    static let green = Color(hex: 0x3E5C41)
    static let greenSoft = Color(hex: 0xDDE4D4)
}

extension Font {
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Condensed, bold, uppercase display text.
struct DisplayText: View {
    let text: String
    let size: CGFloat
    var color: Color = Theme.ink

    init(_ text: String, size: CGFloat, color: Color = Theme.ink) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .bold))
            .fontWidth(.condensed)
            .foregroundColor(color)
    }
}

extension View {
    /// Card background with a 1.5pt ink border and a hard 3pt offset shadow.
    func cardStyle(background: Color = Theme.card) -> some View {
        self
            .background(background)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
            .background(alignment: .center) {
                Rectangle()
                    .fill(Theme.ink)
                    .offset(x: 3, y: 3)
            }
            .padding(.trailing, 3)
            .padding(.bottom, 3)
    }
}

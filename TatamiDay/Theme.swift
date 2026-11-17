import SwiftUI
import UIKit

enum Theme {
    static let background = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.054, green: 0.070, blue: 0.062, alpha: 1)
            : UIColor(red: 0.965, green: 0.957, blue: 0.933, alpha: 1)
    })

    static let surface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.098, green: 0.118, blue: 0.106, alpha: 1)
            : UIColor(red: 1, green: 0.998, blue: 0.992, alpha: 1)
    })

    static let elevated = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.145, green: 0.173, blue: 0.157, alpha: 1)
            : UIColor(red: 0.925, green: 0.914, blue: 0.878, alpha: 1)
    })

    static let ink = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.957, green: 0.945, blue: 0.918, alpha: 1)
            : UIColor(red: 0.078, green: 0.122, blue: 0.098, alpha: 1)
    })

    static let secondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.655, green: 0.694, blue: 0.655, alpha: 1)
            : UIColor(red: 0.325, green: 0.384, blue: 0.345, alpha: 1)
    })

    static let line = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.10)
            : UIColor(white: 0, alpha: 0.08)
    })

    static let tatami = Color(red: 0.184, green: 0.561, blue: 0.384)
    static let gold = Color(red: 0.886, green: 0.694, blue: 0.353)
    static let ember = Color(red: 0.882, green: 0.353, blue: 0.227)
}

extension Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else {
            self = Theme.tatami
            return
        }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    func hexRGB() -> String {
        let ui = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if ui.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return String(
                format: "%02X%02X%02X",
                Int((red * 255).rounded()),
                Int((green * 255).rounded()),
                Int((blue * 255).rounded())
            )
        }
        var white: CGFloat = 0
        if ui.getWhite(&white, alpha: &alpha) {
            let value = Int((white * 255).rounded())
            return String(format: "%02X%02X%02X", value, value, value)
        }
        return "2F8F62"
    }
}

enum Contrast {
    static func ink(on hex: String) -> Color {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else { return .white }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.64 ? Color(red: 0.08, green: 0.11, blue: 0.09) : .white
    }
}

enum TimeText {
    static func range(start: Date, end: Date) -> String {
        let opens = start.formatted(date: .omitted, time: .shortened)
        let closes = end.formatted(date: .omitted, time: .shortened)
        return "\(opens)–\(closes)"
    }

    static func minutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 && remainder > 0 { return "\(hours)h \(remainder)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(remainder)m"
    }
}

struct SymbolIcon: View {
    var name: String

    var body: some View {
        Image(systemName: UIImage(systemName: name) == nil ? "circle.fill" : name)
    }
}

struct TatamiMark: View {
    var size: CGFloat = 88

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(Color(red: 0.071, green: 0.220, blue: 0.165))
            .overlay {
                VStack(spacing: size * 0.07) {
                    bar(Color(red: 0.957, green: 0.945, blue: 0.918))
                    bar(Theme.gold)
                    bar(Color(red: 0.180, green: 0.620, blue: 0.420))
                }
                .padding(.horizontal, size * 0.18)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private func bar(_ color: Color) -> some View {
        Capsule().fill(color).frame(height: size * 0.11)
    }
}

struct Weave: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y: CGFloat = 0
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += 14
            }
            context.stroke(path, with: .color(.white.opacity(0.06)), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum Swatches {
    static let all = [
        "C23B2E", "E15A3A", "E07A2F", "F08A5D", "E2B15A", "F2C14E",
        "6BAA45", "2F8F62", "3AAFA9", "3E6FD8", "6C8EBF", "7A6FF0",
        "5C6B8A", "D4537E", "8C2F39", "F4F1EA"
    ]
}

enum SymbolChoices {
    static let all = [
        "figure.wrestling", "figure.martial.arts", "figure.run", "figure.walk",
        "dumbbell.fill", "flame.fill", "bolt.fill", "figure.flexibility",
        "figure.cooldown", "heart.fill", "leaf.fill", "sun.max.fill",
        "moon.stars.fill", "fork.knife", "trophy.fill", "target",
        "sportscourt.fill", "brain.head.profile", "hand.raised.fill",
        "cross.case.fill", "timer", "flag.fill", "bicycle", "figure.hiking",
        "drop.fill", "pause.circle.fill"
    ]
}

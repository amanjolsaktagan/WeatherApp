import UIKit

/// Maps WMO weather codes (plus day/night) to colour palettes for cards and full-screen gradients.
enum WeatherTheme {

    struct Palette {
        let top: UIColor
        let bottom: UIColor
        var cgColors: [CGColor] { [top.cgColor, bottom.cgColor] }
    }

    static func palette(for code: Int?, isNight: Bool = false) -> Palette {
        isNight ? nightPalette(for: code) : dayPalette(for: code)
    }

    // MARK: Day

    private static func dayPalette(for code: Int?) -> Palette {
        switch code ?? -1 {
        case 0, 1:
            return Palette(
                top:    UIColor(red: 0.16, green: 0.46, blue: 0.85, alpha: 1),
                bottom: UIColor(red: 0.42, green: 0.73, blue: 0.98, alpha: 1)
            )
        case 2:
            return Palette(
                top:    UIColor(red: 0.30, green: 0.55, blue: 0.83, alpha: 1),
                bottom: UIColor(red: 0.62, green: 0.76, blue: 0.89, alpha: 1)
            )
        case 3:
            return Palette(
                top:    UIColor(red: 0.40, green: 0.50, blue: 0.62, alpha: 1),
                bottom: UIColor(red: 0.68, green: 0.75, blue: 0.83, alpha: 1)
            )
        case 45, 48:
            return Palette(
                top:    UIColor(red: 0.50, green: 0.55, blue: 0.60, alpha: 1),
                bottom: UIColor(red: 0.78, green: 0.82, blue: 0.85, alpha: 1)
            )
        case 51...67, 80...82:
            return Palette(
                top:    UIColor(red: 0.20, green: 0.30, blue: 0.46, alpha: 1),
                bottom: UIColor(red: 0.42, green: 0.55, blue: 0.72, alpha: 1)
            )
        case 71...77, 85, 86:
            return Palette(
                top:    UIColor(red: 0.55, green: 0.70, blue: 0.84, alpha: 1),
                bottom: UIColor(red: 0.88, green: 0.93, blue: 0.98, alpha: 1)
            )
        case 95...99:
            return Palette(
                top:    UIColor(red: 0.12, green: 0.10, blue: 0.22, alpha: 1),
                bottom: UIColor(red: 0.36, green: 0.28, blue: 0.52, alpha: 1)
            )
        default:
            return Palette(
                top:    UIColor(red: 0.32, green: 0.45, blue: 0.70, alpha: 1),
                bottom: UIColor(red: 0.55, green: 0.68, blue: 0.84, alpha: 1)
            )
        }
    }

    // MARK: Night

    private static func nightPalette(for code: Int?) -> Palette {
        switch code ?? -1 {
        case 0, 1:
            // Clear night: deep navy → indigo
            return Palette(
                top:    UIColor(red: 0.04, green: 0.07, blue: 0.20, alpha: 1),
                bottom: UIColor(red: 0.12, green: 0.16, blue: 0.36, alpha: 1)
            )
        case 2:
            // Partly cloudy night
            return Palette(
                top:    UIColor(red: 0.10, green: 0.14, blue: 0.25, alpha: 1),
                bottom: UIColor(red: 0.24, green: 0.29, blue: 0.43, alpha: 1)
            )
        case 3:
            // Overcast night
            return Palette(
                top:    UIColor(red: 0.16, green: 0.18, blue: 0.25, alpha: 1),
                bottom: UIColor(red: 0.30, green: 0.32, blue: 0.40, alpha: 1)
            )
        case 45, 48:
            // Fog at night
            return Palette(
                top:    UIColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1),
                bottom: UIColor(red: 0.32, green: 0.34, blue: 0.38, alpha: 1)
            )
        case 51...67, 80...82:
            // Rain at night
            return Palette(
                top:    UIColor(red: 0.05, green: 0.09, blue: 0.16, alpha: 1),
                bottom: UIColor(red: 0.16, green: 0.22, blue: 0.34, alpha: 1)
            )
        case 71...77, 85, 86:
            // Snow at night — moonlit
            return Palette(
                top:    UIColor(red: 0.09, green: 0.16, blue: 0.25, alpha: 1),
                bottom: UIColor(red: 0.32, green: 0.42, blue: 0.55, alpha: 1)
            )
        case 95...99:
            // Thunderstorm at night
            return Palette(
                top:    UIColor(red: 0.04, green: 0.03, blue: 0.09, alpha: 1),
                bottom: UIColor(red: 0.20, green: 0.13, blue: 0.30, alpha: 1)
            )
        default:
            return Palette(
                top:    UIColor(red: 0.08, green: 0.13, blue: 0.24, alpha: 1),
                bottom: UIColor(red: 0.20, green: 0.26, blue: 0.42, alpha: 1)
            )
        }
    }
}

/// A view backed by `CAGradientLayer` so resizes are free — no `layoutSubviews` plumbing required.
final class GradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    init(start: CGPoint = CGPoint(x: 0, y: 0), end: CGPoint = CGPoint(x: 1, y: 1)) {
        super.init(frame: .zero)
        gradientLayer.startPoint = start
        gradientLayer.endPoint = end
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(_ palette: WeatherTheme.Palette) {
        gradientLayer.colors = palette.cgColors
    }
}

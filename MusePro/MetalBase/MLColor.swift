import Foundation
import simd
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct MLColor: Codable {
    var red: Float
    var green: Float
    var blue: Float
    var alpha: Float
    
    static var black = UIColor.black.toMLColor()
    static var white = UIColor.white.toMLColor()
    static var clear = UIColor.clear.toMLColor()
    static var red = UIColor.red.toMLColor()

    func toFloat4() -> vector_float4 {
        return vector_float4(red, green, blue, alpha)
    }
    
    init(red: Float, green: Float, blue: Float, alpha: Float) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    func toUIColor() -> UIColor {
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    // MARK: - Single value codable for MLColor
    
    // hex string must be saved as format of: ffffffff
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)
        var int = UInt64()
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        (alpha, red, green, blue) = (Float(a) / 255.0, Float(r) / 255.0, Float(g) / 255.0, Float(b) / 255.0)
    }
    
    // hex string must be saved as format of: AARRGGBB
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let aInt = Int(alpha * 255) << 24
        let rInt = Int(red * 255) << 16
        let gInt = Int(green * 255) << 8
        let bInt = Int(blue * 255)
        let argb = aInt | rInt | gInt | bInt
        let hex = String(format:"%08x", argb)
        try container.encode(hex)
    }
}

extension UIColor {
    
    var sRGB: CGColor {
        return cgColor.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: CGColorRenderingIntent.defaultIntent,
            options: nil
        ) ?? cgColor
    }
    
    func toMLColor(opacity: CGFloat = 1) -> MLColor {
        let sRGB = self.sRGB
        return MLColor(
            red: Float(sRGB.red),
            green: Float(sRGB.green),
            blue: Float(sRGB.blue),
            alpha: Float(sRGB.alpha * opacity)
        )
    }
    
    func toClearColor() -> MTLClearColor {
        let sRGB = self.sRGB
        return MTLClearColorMake(
            Double(sRGB.red),
            Double(sRGB.green),
            Double(sRGB.blue),
            Double(sRGB.alpha)
        )
    }
    
    static func random() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
}

extension CGColor {
    var red: CGFloat {
        guard let components = components, components.count == 4 else {
            return 0
        }
        return components[0]
    }
    
    var green: CGFloat {
        guard let components = components, components.count == 4 else {
            return 0
        }
        return components[1]
    }
    
    var blue: CGFloat {
        guard let components = components, components.count == 4 else {
            return 0
        }
        return components[2]
    }
    
    var alpha: CGFloat {
        guard let components = components, components.count == 4 else {
            return 0
        }
        return components[3]
    }
}

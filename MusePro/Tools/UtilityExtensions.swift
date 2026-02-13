//
//  UtilityExtensions.swift
//  MusePro
//
//  Created by Omer Karisman on 28.12.23.
//

import SwiftUI

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        guard self.size.width > size.width || self.size.height > size.height else {
            return self
        }
        
        let aspectWidth = size.width / self.size.width
        let aspectHeight = size.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let newSize = CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension UIImage {
    var base64: String? {
        self.jpegData(compressionQuality: 1)?.base64EncodedString()
    }
}



extension UIColor {
    func isLight() -> Bool {
        // algorithm from: http://www.w3.org/WAI/ER/WD-AERT/#color-contrast
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let brightness = ((r * 299) + (g * 587) + (b * 114)) / 1_000
        return brightness >= 0.3
    }
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        //        print("Save finished!")
    }
}


extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isVision: Bool {
        if #available(iOS 17.0, *) {
            return UIDevice.current.userInterfaceIdiom == .vision
        } else {
            return false
        }
    }
}

extension Image {
    init?(data: Data) {
        if let uiImage = UIImage(data: data) {
            self.init(uiImage: uiImage)
        } else {
            return nil
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func animatableGradient(fromGradient: Gradient, toGradient: Gradient, progress: CGFloat) -> some View {
        self.modifier(AnimatableGradientModifier(fromGradient: fromGradient, toGradient: toGradient, progress: progress))
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap {
                $0.windows
            }
            .first {
                $0.isKeyWindow
            }
    }
}


struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets.swiftUiInsets ?? EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension UIEdgeInsets {
    var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension UIColor {
    func adjustedLuminance(_ newLuminance: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Adjust brightness and saturation to achieve the new luminance
        let adjustedBrightness = max(min(newLuminance, 1.0), 0.0)
        let adjustedSaturation = saturation * (1.0 - newLuminance)
        
        return UIColor(hue: hue, saturation: adjustedSaturation, brightness: adjustedBrightness, alpha: alpha)
    }
}

extension FileManager {
    func listFilesRecursive(path: String) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls = [URL]()
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }
            let relativeURL = URL(fileURLWithPath: s, relativeTo: baseurl)
            let url = relativeURL.absoluteURL
            urls.append(url)
        })
        return urls
    }
    
    func listFiles(path: String) -> [URL] {
        let baseurl = URL(fileURLWithPath: path)
        var urls = [URL]()
        
        do {
            let fileURLs = try contentsOfDirectory(at: baseurl, includingPropertiesForKeys: nil)
            urls.append(contentsOf: fileURLs)
        } catch {
            print("Error while enumerating files \(baseurl.path): \(error.localizedDescription)")
        }
        
        return urls
    }
}


extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

extension UIView {
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.shouldRasterize = true
        
        #if os(visionOS)
        layer.rasterizationScale = 1
        #elseif os(iOS)
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
        #endif
    }
}

@propertyWrapper
struct CodableIgnored<T>: Codable {
    var wrappedValue: T?
        
    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        self.wrappedValue = nil
    }
    
    func encode(to encoder: Encoder) throws {
        // Do nothing
    }
}

extension KeyedDecodingContainer {
    func decode<T>(
        _ type: CodableIgnored<T>.Type,
        forKey key: Self.Key) throws -> CodableIgnored<T>
    {
        return CodableIgnored(wrappedValue: nil)
    }
}

extension KeyedEncodingContainer {
    mutating func encode<T>(
        _ value: CodableIgnored<T>,
        forKey key: KeyedEncodingContainer<K>.Key) throws
    {
        // Do nothing
    }
}

extension View {
  @inlinable
  public func reverseMask<Mask: View>(
    alignment: Alignment = .center,
    @ViewBuilder _ mask: () -> Mask
  ) -> some View {
    self.mask {
      Rectangle()
        .overlay(alignment: alignment) {
          mask()
            .blendMode(.destinationOut)
        }
    }
  }
}

extension URL {
    static func generateEmailUrl(email: String, subject: String = "", body: String = "") -> URL {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        let newBody = body + "\n\nApp Version: \(appVersion)\nBuild Number: \(buildNumber)\nId: \(UserManager.shared.uid)"
        if let encodedParams = "subject=\(subject)&body=\(newBody)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: "mailto:\(email)?\(encodedParams)")!
        }
        
        return  URL(string: "mailto:\(email)")!
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}


extension Color {
    func withBrightness(_ adjustment: CGFloat) -> Color {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let adjustedColor = UIColor(
            red: min(red * adjustment, 1.0),
            green: min(green * adjustment, 1.0),
            blue: min(blue * adjustment, 1.0),
            alpha: alpha
        )
        
        return Color(adjustedColor)
    }
    
    func withSaturation(_ adjustment: CGFloat) -> Color {
        let uiColor = UIColor(self)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let adjustedColor = UIColor(
            hue: hue,
            saturation: adjustment,
            brightness: adjustment,
            alpha: alpha
        )
        
        return Color(adjustedColor)
    }
    
    func hue() -> CGFloat {
        let uiColor = UIColor(self)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return hue
    }
    
    func saturation() -> CGFloat {
        let uiColor = UIColor(self)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return saturation
    }
    
    func brightness() -> CGFloat {
        let uiColor = UIColor(self)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return brightness
    }
    
    func withRed(_ adjustment: CGFloat) -> Color {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let adjustedColor = UIColor(
            red: adjustment, green: green, blue: blue, alpha: alpha
        )
        
        return Color(adjustedColor)
    }
    
    func withGreen(_ adjustment: CGFloat) -> Color {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let adjustedColor = UIColor(
            red: red, green: adjustment, blue: blue, alpha: alpha
        )
        
        return Color(adjustedColor)
    }
    
    func withBlue(_ adjustment: CGFloat) -> Color {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let adjustedColor = UIColor(
            red: red, green: green, blue: adjustment, alpha: alpha
        )
        
        return Color(adjustedColor)
    }
    
    func red() -> CGFloat {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return red
    }
    
    func green() -> CGFloat {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return green
    }
    
    func blue() -> CGFloat {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return blue
    }
}


extension UserDefaults {
    /// Convenience method to wrap the built-in .integer(forKey:) method in an optional returning nil if the key doesn't exist.
    func integerOptional(forKey: String) -> Int? {
        return self.object(forKey: forKey) as? Int
    }
    /// Convenience method to wrap the built-in .double(forKey:) method in an optional returning nil if the key doesn't exist.
    func doubleOptional(forKey: String) -> Double? {
        return self.object(forKey: forKey) as? Double
    }
    /// Convenience method to wrap the built-in .float(forKey:) method in an optional returning nil if the key doesn't exist.
    func floatOptional(forKey: String) -> Float? {
        return self.object(forKey: forKey) as? Float
    }
    /// Convenience method to wrap the built-in .bool(forKey:) method in an optional returning nil if the key doesn't exist.
    func boolOptional(forKey: String) -> Bool? {
        return self.object(forKey: forKey) as? Bool
    }
}

extension UIFont {
  class func preferredFont(from font: Font) -> UIFont {
      let style: UIFont.TextStyle =
      switch font {
        case .largeTitle:   .largeTitle
        case .title:        .title1
        case .title2:       .title2
        case .title3:       .title3
        case .headline:     .headline
        case .subheadline:  .subheadline
        case .callout:      .callout
        case .caption:      .caption1
        case .caption2:     .caption2
        case .footnote:     .footnote
        default: /*.body */ .body
      }
      return  UIFont.preferredFont(forTextStyle: style)
    }
 }

public enum RoundingPrecision {
    case ones
    case tenths
    case hundredths
    case thousands
}

extension Double {
    // Round to the specific decimal place
    func customRound(_ rule: FloatingPointRoundingRule, precision: RoundingPrecision = .ones) -> Double {
        switch precision {
        case .ones: return (self * Double(1)).rounded(rule) / 1
        case .tenths: return (self * Double(10)).rounded(rule) / 10
        case .hundredths: return (self * Double(100)).rounded(rule) / 100
        case .thousands: return (self * Double(1000)).rounded(rule) / 1000
        }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

extension View {
    func readHeight() -> some View {
        self
            .modifier(ReadHeightModifier())
    }
}

extension UIImage {
    func upOrientationImage() -> UIImage {
        switch imageOrientation {
        case .up:
            return self
        default:
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(in: CGRect(origin: .zero, size: size))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result ?? self
        }
    }
}

#if os(visionOS)
extension UIDevice {
    var orientation: UIDeviceOrientation {
        return UIDeviceOrientation(rawValue: 3)!
    }
}
extension UIDeviceOrientation {
    var isPortrait: Bool  {
        return false
    }

    var isLandscape: Bool {
        return true
    }
}

#elseif os(iOS)

#endif

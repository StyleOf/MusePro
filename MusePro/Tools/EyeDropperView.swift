//
//  EyeDropperView.swift
//  Muse Pro
//
//  Created by Omer Karisman on 13.07.24.
//
import SwiftUI

struct EyeDropperView: View {
    let snapshot: UIImage
    @State private var pickedColor: UIColor = .orange
    @State private var position: CGPoint = .zero
    @State private var isDragging = false
    let zoomScale: CGFloat = UIScreen.main.scale * 10
    var onColorPicked: ((UIColor?) -> Void)
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: snapshot)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaledToFill()
                    .ignoresSafeArea(.all)
                //                Color.clear
                //                    .contentShape(Rectangle())
                //                    .onTapGesture {
                //                        dismiss()
                //                        onColorPicked(nil)
                //                    }
                ZStack {
                    Circle()
                        .fill(Color(uiColor: pickedColor))
                        .frame(width: 160, height: 160)
                        .shadow(radius: 20)
                    Circle()
                        .fill(pickedColor == UIColor(red: 1, green: 1, blue: 1, alpha: 1) ? .gray : .white)
                        .frame(width: 130, height: 130)
                    Image(uiImage: snapshot)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(zoomScale)
                        .offset(
                            x: (geometry.size.width / 2 - position.x) * zoomScale,
                            y: (geometry.size.height / 2 - position.y) * zoomScale
                        )
                        .mask(Circle().frame(width: 120, height: 120))
                    
                    GridOverlay(color: pickedColor == UIColor(red: 1, green: 1, blue: 1, alpha: 1) ? .gray : .white)
                        .frame(width: 160, height: 160)
                        .mask(Circle().frame(width: 120, height: 120))
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(pickedColor == UIColor(red: 1, green: 1, blue: 1, alpha: 1) ? .gray : .white, lineWidth: 4)
                        .frame(width: 14, height: 14)
                }
                .position(position)
                .onTapGesture {
                    dismiss()
                    onColorPicked(nil)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.position = value.location
                            self.isDragging = true
                            updatePickedColor(at: value.location, in: geometry)
                        }
                        .onEnded { _ in
                            self.isDragging = false
                            onColorPicked(pickedColor)
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                self.position = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                updatePickedColor(at: self.position, in: geometry)
            }
        }
        .padding(0)
    }
    
    private func updatePickedColor(at position: CGPoint, in geometry: GeometryProxy) {
        guard let cgImage = snapshot.cgImage else { return }

        self.pickedColor = snapshot[CGPoint(x: position.x, y: position.y)] ?? UIColor.white
        
    }
}

struct GridOverlay: View {
    let color: UIColor
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let stepX = geometry.size.width / 11
                let stepY = geometry.size.height / 11
                
                // Vertical lines
                for i in 1..<11 {
                    let x = stepX * CGFloat(i)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                for i in 1..<11 {
                    let y = stepY * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color(uiColor: color), lineWidth: 1)
        }
    }
}


import UIKit

public extension CGBitmapInfo {
    // https://stackoverflow.com/a/60247693/2585092
    enum ComponentLayout {
        case bgra
        case abgr
        case argb
        case rgba
        case bgr
        case rgb
        
        var count: Int {
            switch self {
            case .bgr, .rgb: return 3
            default: return 4
            }
        }
    }
    
    var componentLayout: ComponentLayout? {
        guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
        let isLittleEndian = contains(.byteOrder32Little)
        
        if alphaInfo == .none {
            return isLittleEndian ? .bgr : .rgb
        }
        let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst
        
        if isLittleEndian {
            return alphaIsFirst ? .bgra : .abgr
        } else {
            return alphaIsFirst ? .argb : .rgba
        }
    }
    
    var chromaIsPremultipliedByAlpha: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

extension UIImage {
    subscript(_ point: CGPoint) -> UIColor? {
        guard
            let cgImage = cgImage,
            let space = cgImage.colorSpace,
            let pixelData = cgImage.dataProvider?.data,
            let layout = cgImage.bitmapInfo.componentLayout
        else {
            return nil
        }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let comp = CGFloat(layout.count)
        let isHDR = CGColorSpaceUsesITUR_2100TF(space)
        let length = CFDataGetLength(pixelData)
        let hdr = CGFloat(isHDR ? 2 : 1)
        
        
        let bytesPerRow = cgImage.bytesPerRow
        let scaledPoint = CGPoint(x: point.x * scale, y: point.y * scale)
        let y = Int(scaledPoint.y)
        
        let pixelInfo = y * bytesPerRow + Int(scaledPoint.x) * Int(comp)
        
        
        guard pixelInfo + Int(comp) - 1 < length else {
            print("Pixel info out of bounds")
            return nil
        }
        
        let i = Array(0..<Int(comp)).map {
            CGFloat(data[pixelInfo + $0]) / 255.0
        }
        
        var color: UIColor
        switch layout {
        case .bgra:
            color = UIColor(red: i[2], green: i[1], blue: i[0], alpha: i[3])
        case .abgr:
            color = UIColor(red: i[3], green: i[2], blue: i[1], alpha: i[0])
        case .argb:
            color = UIColor(red: i[1], green: i[2], blue: i[3], alpha: i[0])
        case .rgba:
            color = UIColor(red: i[0], green: i[1], blue: i[2], alpha: i[3])
        case .bgr:
            color = UIColor(red: i[2], green: i[1], blue: i[0], alpha: 1)
        case .rgb:
            color = UIColor(red: i[0], green: i[1], blue: i[2], alpha: 1)
        }
        
        return color
    }
}

#Preview {
    EyeDropperView(snapshot: UIImage(named: "launch")!) { color in
        if let color = color {
            print("Color picked: \(color)")
        } else {
            print("Dismissed without picking a color")
        }
    }
}

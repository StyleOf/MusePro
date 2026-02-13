//
//  TextEditor.swift
//  Muse Pro
//
//  Created by Omer Karisman on 22.02.24.
//

import SwiftUI
import DSFStepperView
import CoreImage.CIFilterBuiltins

struct TextOptions {
    
}

struct TextEditor: View {
    @ObservedObject var canvasManager: CanvasManager
    @Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(\.colorScheme) var colorScheme

    @State var text: String = "New Text"
    @State var alignment: TextAlignment = .center
    @State var bold: Bool = false
    @State var italic: Bool = false
    @State var underline: Bool = false
    @State var strikethrough: Bool = false
    @State var font: Font = .system(size: 64)
    @State var fontName: String = "" {
        didSet {
            if fontName.isEmpty {
                font = .system(size: fontSize)
            } else {
                font = .custom(fontName, size: fontSize)
            }
        }
    }

    @State var fontSize: CGFloat = 64.0 {
        didSet {
            if fontName.isEmpty {
                font = .system(size: fontSize)
            } else {
                font = .custom(fontName, size: fontSize)
            }
        }
    }
    
    @State var fontColor: Color = .black
    @State var showingFontPicker: Bool = false
    
    internal var userFontNames: [String]?
    internal var additionalFontNames: [String] = []
    internal var excludedFontNames = [
            "Bodoni Ornaments",
            "Damascus",
            "Hiragino"
        ]
    
    private func fontNamesToDisplay() -> [String] {
        
        if let userFontNames = userFontNames {
            return userFontNames
        }
        
        var allFontNames: [String] = []
        
        UIFont.familyNames.forEach({ familyName in
            let fontNamesForFamily = UIFont.fontNames(forFamilyName: familyName)
            allFontNames.append(contentsOf: fontNamesForFamily.filter { !excludedFontNames.contains(where: $0.contains) })
        })
        
        let uniqueFontNames = Set(allFontNames) // Removes any duplicates
        let sortedAndCombinedFontNames = (Array(uniqueFontNames) + additionalFontNames).sorted()
        
        return sortedAndCombinedFontNames
    }
    
    let context = CIContext()
    
    
    func createAttributedString(text: String, font: String, size: CGFloat, color: Color, alignment: TextAlignment, bold: Bool, italic: Bool, underline: Bool, strikethrough: Bool) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        switch alignment {
        case .leading:
            paragraphStyle.alignment = .left
        case .center:
            paragraphStyle.alignment = .center
        case .trailing:
            paragraphStyle.alignment = .right
        }
        
        if let uiFont = UIFont(name: font, size: size) {
            
            //        if bold {
            //            fontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) ?? fontDescriptor
            //        }
            //
            //        if italic {
            //            fontDescriptor = fontDescriptor.withSymbolicTraits(.traitItalic) ?? fontDescriptor
            //        }
            //
            //        let uiFont = UIFont(descriptor: fontDescriptor, size: size)
            
            var attributes: [NSAttributedString.Key: Any] = [
                .font: uiFont,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor(color),
                .shadow: NSShadow(),
                .strokeWidth: 0
            ]
            
            if underline {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            
            if strikethrough {
                attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
            
            return NSAttributedString(string: text, attributes: attributes)
        }
        
        return NSAttributedString(string: text)
    }
    
    @State var image: UIImage? = nil
    
    func createImage() {
        let attributedString = createAttributedString(text: text, font: fontName, size: fontSize, color: fontColor, alignment: alignment, bold: bold, italic: italic, underline: underline, strikethrough: strikethrough)
  
        let filter = CIFilter.attributedTextImageGenerator()
        filter.text = attributedString
        #if os(visionOS)
            filter.scaleFactor = 1.0
        #elseif os(iOS)
            filter.scaleFactor = Float(UIScreen.main.scale)
        #endif
        filter.padding = 0
        
        if let textImage = filter.outputImage,
//           let newTexture = canvasManager.canvas?.makeEmptyTexture(with: CGSize(width: textImage.extent.width, height: textImage.extent.height)),
//           let commandBuffer = canvasManager.canvas?.renderer?.commandQueue.makeCommandBuffer() {
            
            let cgimg = context.createCGImage(textImage, from: textImage.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            image = processedImage
            canvasManager.addImage(processedImage)
            
            
//            canvasManager.canvas?.renderer?.context.render(textImage, to: newTexture.texture, commandBuffer: commandBuffer, bounds: textImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
////
//            commandBuffer.commit()
//            commandBuffer.waitUntilCompleted()
//            
//            canvasManager.addTexture(texture: newTexture)
        }
        
    }
    
    var onCancel: () -> Void
    var onSelect: () -> Void

    var body: some View {
//        ZStack {
//            Rectangle()
//                .fill(.controlForeground.opacity(0.5))
//                .edgesIgnoringSafeArea(.all)
            VStack {
//                if let image {
//                    Image(uiImage: image)
//                }
                HStack {
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(.plain)
//                    .buttonBorderShape(.capsule)
                    Spacer()
                    Button {
                        createImage()
                        onSelect()
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(.borderless)
//                    .buttonBorderShape(.capsule)

                }
                editor
                toolbar
                    .padding()
                

            }
            .padding()
            .background {
                ShinyRect()
            }
            .padding()
            .frame(maxWidth: 480)
            .padding(.bottom, safeAreaInsets.bottom)
//            .background(Color.primary.opacity(0.15))
                        
//        }
    }
    
    @FocusState var focused: Bool
    var editor: some View {
        TextField(text: $text) {
            
        }
        .foregroundStyle(fontColor)
        .font(font)
        .multilineTextAlignment(alignment)
        .bold(bold)
        .italic(italic)
        .underline(underline)
        .strikethrough(strikethrough)
        .frame(maxWidth: .infinity)
        .focused($focused)
        .onAppear {
//            focused = true
        }
        
    }
    
    let configuration = DSFStepperView.SwiftUI.DisplaySettings(range: ClosedRange(uncheckedBounds: (1,100)), increment: 1)
    let style = DSFStepperView.SwiftUI.Style(
      font: DSFFont.systemFont(ofSize: 16, weight: .regular),
      indicatorColor: DSFColor.clear)
    @State var stepperFontSize: CGFloat? = 64
    
    var toolbar: some View {
        HStack (spacing: 16) {
            ColorPicker("Font Color", selection: $fontColor)
                .labelsHidden()
        
            Button {
                focused = false
                showingFontPicker = true
            } label: {
                HStack {
                    Image(systemName: "textformat")
                        .font(.system(size: 20, weight: .light))

                    Text(fontName)
                        .font(.custom(fontName, size: 16))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20, weight: .light))

                        .foregroundStyle(Color.promptForeground)
                }
                .padding(8)
                .background(Color.promptBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            DSFStepperView.SwiftUI(
                 configuration: configuration,
                 style: style,
                 floatValue: $stepperFontSize,
                 onValueChange: { value in
                    fontSize = value!
                 }
              )
            .frame(width: 150, height: 32)

        }
        .sheet(isPresented: $showingFontPicker, content: {
            VStack {
                Text("Font")
                    .font(Font.headline.weight(.semibold))
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .lineLimit(1)
                    List {
                        ForEach(fontNamesToDisplay(), id: \.self) { listFontName in
                            
                            HStack {
                                Text(listFontName)
                                    .font(.custom(listFontName, size: 24))
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                fontName = listFontName
                                showingFontPicker = false
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
        )
    }
}

//#Preview {
//    TextEditor {
//        
//    } onSelect: {
//        
//    }
//
//}

struct ShinyRect: View {
    @Environment(\.colorScheme) var colorScheme

    var cornerRadius: CGFloat = 24
    
    var body: some View {
        let gradient = LinearGradient(
           gradient: Gradient(stops: [
               .init(color: Color.white.opacity(0.2), location: 0),
               .init(color: Color.white.opacity(0.02), location: 1)
           ]),
           startPoint: UnitPoint(x: 0, y: 0),
           endPoint: UnitPoint(x: 0, y: 1)
       )
       
        RoundedRectangle(cornerRadius: cornerRadius)
           .strokeBorder(gradient, lineWidth: 1)
           .background {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
           }
    }
}

struct ShinyCapsule: View {
    @Environment(\.colorScheme) var colorScheme

    
    var body: some View {
        let gradient = LinearGradient(
           gradient: Gradient(stops: [
               .init(color: Color.white.opacity(0.2), location: 0),
               .init(color: Color.white.opacity(0.02), location: 1)
           ]),
           startPoint: UnitPoint(x: 0, y: 0),
           endPoint: UnitPoint(x: 0, y: 1)
       )
       
        Capsule()
           .strokeBorder(gradient, lineWidth: 1)
           .background {
               Capsule()
                   .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
           }
    }
}

struct MatteRect: View {
    @Environment(\.colorScheme) var colorScheme

    var cornerRadius: CGFloat = 24
    
    var body: some View {
  
       RoundedRectangle(cornerRadius: cornerRadius)
           .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
    }
}

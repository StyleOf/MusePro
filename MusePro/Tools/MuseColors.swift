//
//  MuseColors.swift
//  MuseColors
//
//  Created by Omer Karisman on 25.03.24.
//

import SwiftUI

struct MuseColors: View {
    @Environment(\.colorScheme) var colorScheme
    
    var onColorChanged: (Color) -> Void
    var onEyedropperSelected: () -> Void
    var onClose: () -> Void

    @State var primaryColor: Color = .blue
//    @State var secondaryColor: Color = .black
    
    @State var red: Double = 1.0
    @State var green: Double = 1.0
    @State var blue: Double = 1.0
    
    @State var hue: Double = 1.0
    @State var saturation: Double = 1.0
    @State var brightness: Double = 1.0
    
    @State var brightnessColor: Color = .white
    @State var saturationColor: Color = Color(hue: 1.0, saturation: 1.0, brightness: 1.0)
    @State var hueColor: Color = Color(hue: 1.0, saturation: 1.0, brightness: 1.0)
    
    let rainbow: Gradient = {
        Gradient(colors:
                    Array(0...255).map {
            Color(hue:Double($0)/255 , saturation: 1.0, brightness: 1.0)
        }
        )
    }()
    
    @State var hueSliderGradient: LinearGradient = LinearGradient(colors: Array(0...255).map {
        Color(hue:Double($0)/255 , saturation: 1.0, brightness: 1.0)
    }, startPoint: .leading, endPoint: .trailing)
    @State var saturationSliderGradient: LinearGradient = LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)
    @State var brightnessSliderGradient: LinearGradient = LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)
    @State var redSliderGradient: LinearGradient = LinearGradient(colors: [.black, .red], startPoint: .leading, endPoint: .trailing)
    @State var greenSliderGradient: LinearGradient = LinearGradient(colors: [.black, .green], startPoint: .leading, endPoint: .trailing)
    @State var blueSliderGradient: LinearGradient = LinearGradient(colors: [.black, .blue], startPoint: .leading, endPoint: .trailing)
    
    @State var tab: Int = 1
    var body: some View {
        VStack {
           
            Group {
                switch tab {
                case 1:
                    VStack {
                        Header()
                        Swatch()
                    }
//                    .tag(1)
//                    .tabItem {
//                        Label("Swatch", systemImage: "square.grid.3x3")
//                    }
                case 2:
                    VStack {
                        Header()
                        Classic()
                    }
//                    .tag(2)
//                    .tabItem {
//                        Label("Classic", systemImage: "square")
//                    }
                case 3:
                    VStack {
                        Header()
                        Values()
                    }
                    .tag(3)
//                    .tabItem {
//                        Label("Values", systemImage: "slider.horizontal.3")
//                    }
                default:
                    VStack {
                        Header()
                        Swatch()
                    }
//                    .tag(1)
//                    .tabItem {
//                        Label("Swatch", systemImage: "square.grid.3x3")
//                    }
                }
                
            }
            .onAppear {
                calculateColorsFromPrimaryColor()
            }
            .onChange(of: hue) { _ in
                calculateColorsFromHSB()
            }
            .onChange(of: saturation) { _ in
                calculateColorsFromHSB()
            }
            .onChange(of: brightness) { _ in
                calculateColorsFromHSB()
            }
            .onChange(of: red) { _ in
                calculateColorsFromRGB()
            }
            .onChange(of: green) { _ in
                calculateColorsFromRGB()
            }
            .onChange(of: blue) { _ in
                calculateColorsFromRGB()
            }
            .onChange(of: primaryColor) { _ in
                calculateColorsFromPrimaryColor()
            }
            Spacer()
        }

    }
    
    func calculateColorsFromHSB() {
        if hue == 1.0 {
            hue = 359.0 / 360.0
            return
        }
        primaryColor = Color(hue: hue, saturation: saturation, brightness: brightness)

        hueColor = Color(hue: hue, saturation: 1.0, brightness: 1.0)
        saturationColor = Color(hue: hue, saturation: saturation, brightness: saturation / 2 + 0.5)
        brightnessColor = .white.withBrightness(brightness)
    }
    
    func calculateColorsFromRGB() {
        primaryColor = Color(uiColor: UIColor(red: red, green: green, blue: blue, alpha: 1))

        hueColor = Color(hue: hue, saturation: 1.0, brightness: 1.0)
        saturationColor = Color(hue: hue, saturation: saturation, brightness: saturation / 2 + 0.5)
        brightnessColor = .white.withBrightness(brightness)
    }
    
    func calculateColorsFromPrimaryColor() {
     
        onColorChanged(primaryColor)
        
        hue = primaryColor.hue()
        saturation = primaryColor.saturation()
        brightness = primaryColor.brightness()
        
        red = primaryColor.red()
        green = primaryColor.green()
        blue = primaryColor.blue()
        
        setGradients()
    }
    
    func setGradients() {

        hueSliderGradient = LinearGradient(gradient: rainbow, startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/)
        saturationSliderGradient = LinearGradient(colors: [.gray, saturationColor], startPoint: .leading, endPoint: .trailing)
        brightnessSliderGradient = LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)
        redSliderGradient = LinearGradient(colors: [primaryColor.withRed(0), primaryColor.withRed(1)], startPoint: .leading, endPoint: .trailing)
        greenSliderGradient = LinearGradient(colors: [primaryColor.withGreen(0), primaryColor.withGreen(1)], startPoint: .leading, endPoint: .trailing)
        blueSliderGradient = LinearGradient(colors: [primaryColor.withBlue(0), primaryColor.withBlue(1)], startPoint: .leading, endPoint: .trailing)
        
    }
    
    @ViewBuilder
    func Header() -> some View {
        VStack {
           
            HStack {
                Text("Colors")
                    .font(.largeTitle.bold())
                Button("", systemImage: "eyedropper") {
                    onEyedropperSelected()
                }
                .labelsHidden()
                RoundedRectangle(cornerRadius: 8)
                    .fill(primaryColor)
                    .frame(width: 48, height: 24)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.foreground.opacity(0.3))
                    }
                Spacer()
                Button {
                    onClose()
                } label: {
                    Text("Done")
                }
                .buttonStyle(BorderedProminentButtonStyle())
                //            RoundedRectangle(cornerRadius: 8)
                //                .fill(secondaryColor)
                //                .frame(width: 48, height: 24)
                //                .overlay {
                //                    RoundedRectangle(cornerRadius: 8)
                //                        .stroke(.foreground.opacity(0.3))
                //                }
                
            }
            Picker(selection: $tab, label: Text("")) {
               Text("Grid").tag(1)
               Text("Spectrum").tag(2)
               Text("Sliders").tag(3)
               
           }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
    
    let colorSwatch = [
            [
                Color(hue: 0.000000, saturation: 0.000000, brightness: 1.000000),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.921569),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.839216),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.760784),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.678431),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.600000),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.521569),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.439216),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.360784),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.278431),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.200000),
                Color(hue: 0.000000, saturation: 0.000000, brightness: 0.000000),
            ],
            [
                Color(hue: 0.542793, saturation: 1.000000, brightness: 0.290196),
                Color(hue: 0.612403, saturation: 0.988506, brightness: 0.341176),
                Color(hue: 0.703704, saturation: 0.915255, brightness: 0.231373),
                Color(hue: 0.787878, saturation: 0.901640, brightness: 0.239216),
                Color(hue: 0.937107, saturation: 0.883333, brightness: 0.235294),
                Color(hue: 0.010989, saturation: 0.989130, brightness: 0.360784),
                Color(hue: 0.051852, saturation: 1.000000, brightness: 0.352941),
                Color(hue: 0.096591, saturation: 1.000000, brightness: 0.345098),
                Color(hue: 0.118217, saturation: 1.000000, brightness: 0.337255),
                Color(hue: 0.158497, saturation: 1.000000, brightness: 0.400000),
                Color(hue: 0.179012, saturation: 0.952941, brightness: 0.333333),
                Color(hue: 0.251773, saturation: 0.758064, brightness: 0.243137),
            ],
            [
                Color(hue: 0.539604, saturation: 1.000000, brightness: 0.396078),
                Color(hue: 0.603825, saturation: 0.991870, brightness: 0.482353),
                Color(hue: 0.703704, saturation: 0.878049, brightness: 0.321569),
                Color(hue: 0.789473, saturation: 0.853933, brightness: 0.349020),
                Color(hue: 0.939614, saturation: 0.811765, brightness: 0.333333),
                Color(hue: 0.021629, saturation: 1.000000, brightness: 0.513725),
                Color(hue: 0.055555, saturation: 1.000000, brightness: 0.482353),
                Color(hue: 0.101093, saturation: 1.000000, brightness: 0.478431),
                Color(hue: 0.122222, saturation: 1.000000, brightness: 0.470588),
                Color(hue: 0.158273, saturation: 0.985816, brightness: 0.552941),
                Color(hue: 0.177469, saturation: 0.915254, brightness: 0.462745),
                Color(hue: 0.251366, saturation: 0.701148, brightness: 0.341176),
            ],
            [
                Color(hue: 0.538732, saturation: 0.993007, brightness: 0.560784),
                Color(hue: 0.601578, saturation: 1.000000, brightness: 0.662745),
                Color(hue: 0.719697, saturation: 0.924370, brightness: 0.466667),
                Color(hue: 0.788333, saturation: 0.806452, brightness: 0.486275),
                Color(hue: 0.938596, saturation: 0.785124, brightness: 0.474510),
                Color(hue: 0.023941, saturation: 1.000000, brightness: 0.709804),
                Color(hue: 0.059730, saturation: 1.000000, brightness: 0.678431),
                Color(hue: 0.102564, saturation: 1.000000, brightness: 0.662745),
                Color(hue: 0.123232, saturation: 0.993976, brightness: 0.650980),
                Color(hue: 0.159864, saturation: 1.000000, brightness: 0.768627),
                Color(hue: 0.177704, saturation: 0.915151, brightness: 0.647059),
                Color(hue: 0.255020, saturation: 0.680328, brightness: 0.478431),
            ],
            [
                Color(hue: 0.537037, saturation: 1.000000, brightness: 0.705882),
                Color(hue: 0.599688, saturation: 1.000000, brightness: 0.839216),
                Color(hue: 0.706284, saturation: 0.824324, brightness: 0.580392),
                Color(hue: 0.785333, saturation: 0.791139, brightness: 0.619608),
                Color(hue: 0.938746, saturation: 0.764707, brightness: 0.600000),
                Color(hue: 0.026549, saturation: 1.000000, brightness: 0.886275),
                Color(hue: 0.061927, saturation: 1.000000, brightness: 0.854902),
                Color(hue: 0.103175, saturation: 0.995261, brightness: 0.827451),
                Color(hue: 0.125000, saturation: 0.995215, brightness: 0.819608),
                Color(hue: 0.160544, saturation: 1.000000, brightness: 0.960784),
                Color(hue: 0.179211, saturation: 0.889952, brightness: 0.819608),
                Color(hue: 0.253968, saturation: 0.668789, brightness: 0.615686),
            ],
            [
                Color(hue: 0.542438, saturation: 1.000000, brightness: 0.847059),
                Color(hue: 0.603018, saturation: 1.000000, brightness: 0.996078),
                Color(hue: 0.716435, saturation: 0.808989, brightness: 0.698039),
                Color(hue: 0.792237, saturation: 0.776596, brightness: 0.737255),
                Color(hue: 0.942857, saturation: 0.756756, brightness: 0.725490),
                Color(hue: 0.030627, saturation: 0.917647, brightness: 1.000000),
                Color(hue: 0.069281, saturation: 1.000000, brightness: 1.000000),
                Color(hue: 0.111549, saturation: 0.996078, brightness: 1.000000),
                Color(hue: 0.131093, saturation: 1.000000, brightness: 0.992157),
                Color(hue: 0.164021, saturation: 0.744094, brightness: 0.996078),
                Color(hue: 0.184162, saturation: 0.766949, brightness: 0.925490),
                Color(hue: 0.260163, saturation: 0.657754, brightness: 0.733333),
            ],
            [
                Color(hue: 0.535193, saturation: 0.996032, brightness: 0.988235),
                Color(hue: 0.601190, saturation: 0.771653, brightness: 0.996078),
                Color(hue: 0.707665, saturation: 0.795745, brightness: 0.921569),
                Color(hue: 0.786096, saturation: 0.769547, brightness: 0.952941),
                Color(hue: 0.938597, saturation: 0.743478, brightness: 0.901961),
                Color(hue: 0.017143, saturation: 0.686275, brightness: 1.000000),
                Color(hue: 0.056466, saturation: 0.717647, brightness: 1.000000),
                Color(hue: 0.102094, saturation: 0.751968, brightness: 0.996078),
                Color(hue: 0.122396, saturation: 0.755906, brightness: 0.996078),
                Color(hue: 0.157658, saturation: 0.580392, brightness: 1.000000),
                Color(hue: 0.179952, saturation: 0.577406, brightness: 0.937255),
                Color(hue: 0.254310, saturation: 0.549763, brightness: 0.827451),
            ],
            [
                Color(hue: 0.537255, saturation: 0.674603, brightness: 0.988235),
                Color(hue: 0.605516, saturation: 0.545098, brightness: 1.000000),
                Color(hue: 0.719048, saturation: 0.688976, brightness: 0.996078),
                Color(hue: 0.790419, saturation: 0.657481, brightness: 0.996078),
                Color(hue: 0.940000, saturation: 0.525210, brightness: 0.933333),
                Color(hue: 0.013333, saturation: 0.490196, brightness: 1.000000),
                Color(hue: 0.051282, saturation: 0.509804, brightness: 1.000000),
                Color(hue: 0.098039, saturation: 0.533333, brightness: 1.000000),
                Color(hue: 0.120098, saturation: 0.533333, brightness: 1.000000),
                Color(hue: 0.157321, saturation: 0.419608, brightness: 1.000000),
                Color(hue: 0.180135, saturation: 0.409091, brightness: 0.949020),
                Color(hue: 0.256097, saturation: 0.371041, brightness: 0.866667),
            ],
            [
                Color(hue: 0.540881, saturation: 0.418972, brightness: 0.992157),
                Color(hue: 0.607954, saturation: 0.345098, brightness: 1.000000),
                Color(hue: 0.720760, saturation: 0.448818, brightness: 0.996078),
                Color(hue: 0.790124, saturation: 0.425197, brightness: 0.996078),
                Color(hue: 0.941667, saturation: 0.327869, brightness: 0.956863),
                Color(hue: 0.012500, saturation: 0.313725, brightness: 1.000000),
                Color(hue: 0.051587, saturation: 0.329412, brightness: 1.000000),
                Color(hue: 0.093869, saturation: 0.341176, brightness: 1.000000),
                Color(hue: 0.116279, saturation: 0.338582, brightness: 0.996078),
                Color(hue: 0.157143, saturation: 0.274510, brightness: 1.000000),
                Color(hue: 0.179687, saturation: 0.259109, brightness: 0.968627),
                Color(hue: 0.254902, saturation: 0.219828, brightness: 0.909804),
            ],
            [
                Color(hue: 0.548077, saturation: 0.203922, brightness: 1.000000),
                Color(hue: 0.609848, saturation: 0.172549, brightness: 1.000000),
                Color(hue: 0.716981, saturation: 0.208661, brightness: 0.996078),
                Color(hue: 0.783019, saturation: 0.207843, brightness: 1.000000),
                Color(hue: 0.942983, saturation: 0.152611, brightness: 0.976471),
                Color(hue: 0.012821, saturation: 0.152941, brightness: 1.000000),
                Color(hue: 0.048781, saturation: 0.160784, brightness: 1.000000),
                Color(hue: 0.093023, saturation: 0.168627, brightness: 1.000000),
                Color(hue: 0.115080, saturation: 0.164706, brightness: 1.000000),
                Color(hue: 0.156566, saturation: 0.129921, brightness: 0.996078),
                Color(hue: 0.182796, saturation: 0.123999, brightness: 0.980392),
                Color(hue: 0.262820, saturation: 0.109243, brightness: 0.933333),
            ]
        ]
    
    @State var size: CGSize = CGSize(width: 0, height: 0)
    @State var savedColors: [Color] = [Color]()
    
    @ViewBuilder
    func Swatch() -> some View {
        VStack {
            ZStack {
                Grid (horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(colorSwatch, id: \.self) { row in
                        GridRow {
                            ForEach(row, id: \.self) { color in
                                Rectangle()
                                    .fill(color)
                                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                                
                            }
                        }
                    }
                }
                .background(
                    GeometryReader { proxy in
                        let proxySize = proxy.size
                        Color.red
                            .task(id: proxy.size) {
                                $size.wrappedValue = proxySize
                            }
                    }
                )
                
                Grid (horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(colorSwatch, id: \.self) { row in
                        GridRow {
                            ForEach(row, id: \.self) { color in
                                Rectangle()
                                    .fill(.white.opacity(0.001))
                                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                                    .overlay {
                                        if UIColor(color) == UIColor(primaryColor) {
                                            Rectangle()
                                                .stroke(Color.foreground, lineWidth: 2)
                                        }
                                    }
                                    .onTapGesture {
                                        primaryColor = color
                                    }
                                
                            }
                        }
                    }
                }
                
                .coordinateSpace(name: "grid")
                .gesture(
                    DragGesture(coordinateSpace: .named("grid"))
                        .onChanged({ dragValue in
                            let x = Int(dragValue.location.x / size.width * CGFloat(colorSwatch[0].count))
                            let y = Int(dragValue.location.y / size.height * CGFloat(colorSwatch.count))
                            if x >= 0, y >= 0, colorSwatch.count > y, colorSwatch[y].count > x {
                                primaryColor = colorSwatch[y][x]
                            }
                        })
                    
                )
                
            }
            .padding()
//            .layoutPriority(1)
            Divider()
            ScrollView(.vertical, showsIndicators: false) {
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 36, maximum: 48), spacing: 8, alignment: .top)], spacing: 8) {
                    
                    ForEach(savedColors, id: \.self) { color in
                        Button {
                            primaryColor = color
                        } label: {
                            if color == primaryColor {
                                ZStack {
                                    Circle()
                                        .stroke(color, lineWidth: 4)
                                    Circle()
                                        .fill(color)
                                        .padding(4)
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                }
                            }
                            
                        }
                    }
                    
                    //                MultiTapButton(singleTapAction: {
                    //                    savedColors.append(primaryColor)
                    //                }, doubleTapAction: {
                    //
                    //                }, longPressAction: {
                    //
                    //                }, duration: 0.5) {
                    //                    ZStack {
                    //                        Circle()
                    //                            .fill(Color.foreground.opacity(0.3))
                    //                        Image(systemName: "plus")
                    //                            .foregroundStyle(.background)
                    //                    }
                    //                }
                    
                    Button {
                        if (savedColors.first(where: { c in
                            c == primaryColor
                        }) == nil){
                            savedColors.append(primaryColor)
                        }
                    } label : {
                        ZStack {
                            Circle()
                                .fill(Color.foreground.opacity(0.3))
                            Image(systemName: "plus")
                                .foregroundStyle(.background)
                        }
                    }
                    
                }
                .padding()
                //            .layoutPriority(0)
            }
            .frame(height: 110)
            .onAppear {
                if savedColors.count == 0 {
                    savedColors = [
                        colorSwatch[8][0],
                        colorSwatch[8][2],
                        colorSwatch[8][4],
                        colorSwatch[8][6],
                        colorSwatch[8][8],
                        colorSwatch[8][10]]
                }
            }
        }
    }
    
    @State var discHueKnobPosition: CGPoint = CGPoint(x: 0, y: 0)
    @State var discHueKnobIsDragging: Bool = false
    @State var discHueKnobSize: CGFloat = 44

    @ViewBuilder
    func Disc() -> some View {
        VStack {}
        //        let gradient:Gradient = {
        //            Gradient(colors:
        //                        Array(0...255).map {
        //                Color(hue:Double($0)/255 , saturation: 1.0, brightness: 1.0)
        //            }
        //            )
        //        }()
        //
        //        let margin: CGFloat = 128
        //        let discWidth: CGFloat = 50
        //        GeometryReader { geo in
        //            ZStack {
        //                Circle()
        //                    .strokeBorder(
        //                        AngularGradient(gradient: gradient, center: .center, startAngle: .zero, endAngle: .degrees(360)),
        //                        lineWidth: discWidth
        //                    )
        //
        //                Circle()
        //                    .fill(primaryColor)
        //                    .frame(width: discHueKnobSize, height: discHueKnobSize)
        //                    .overlay {
        ////                        if discHueKnobIsDragging {
        ////                            Circle()
        ////                                .trim(from: 0.25, to: 0.75)
        ////                                .fill(.black)
        ////                        }
        //                        Circle()
        //                            .stroke(.white, lineWidth: 2)
        //                    }
        //                    .shadow(color: .black.opacity(0.1), radius: 4)
        //                    .position(discHueKnobPosition)
        //
        //                Circle()
        //                    .strokeBorder(
        //                        .red.opacity(0.001),
        //                        lineWidth: discWidth
        //                    )
        //                    .onAppear {
        //
        //                        let hueDegrees: CGFloat = (1 - hue) * 360
        //                        let hueRadians = hueDegrees * (.pi / 180)
        //
        //                        let maxRadius: CGFloat = min(geo.size.width, geo.size.height) / 2 - (discWidth / 2)
        //                        let minRadius: CGFloat = min(geo.size.width, geo.size.height) / 2 - (discWidth / 2)
        //
        //                        let dx = cos(hueRadians) * maxRadius
        //                        let dy = sin(hueRadians) * maxRadius
        //
        //                        let initialPosition = CGPoint(x: geo.size.width / 2 + dx, y: geo.size.height / 2 - dy)
        //
        //                        discHueKnobPosition = initialPosition
        //
        //                    }
        //                    .gesture(
        //                        DragGesture()
        //                            .onChanged({ dragValue in
        //                                if !discHueKnobIsDragging {
        //                                    discHueKnobIsDragging = true
        ////                                    withAnimation {
        ////                                        discHueKnobSize = 120
        ////                                    }
        //                                }
        //
        //                                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        //
        //                               var newPosition = dragValue.location
        //                               let dx = newPosition.x - center.x
        //                               let dy = newPosition.y - center.y
        //
        //                               let distance = sqrt(dx*dx + dy*dy)
        //
        //                               let maxRadius: CGFloat = min(geo.size.width, geo.size.height) / 2 - (discWidth / 2)
        //                               let minRadius: CGFloat = min(geo.size.width, geo.size.height) / 2 - (discWidth / 2)
        //
        //
        //                               if distance > maxRadius {
        //                                   let adjustmentFactor = maxRadius / distance
        //                                   newPosition.x = center.x + dx * adjustmentFactor
        //                                   newPosition.y = center.y + dy * adjustmentFactor
        //                               } else if distance < minRadius && distance != 0 {
        //                                   let adjustmentFactor = minRadius / distance
        //                                   newPosition.x = center.x + dx * adjustmentFactor
        //                                   newPosition.y = center.y + dy * adjustmentFactor
        //                               }
        //
        //                               let adjustedDx = newPosition.x - center.x
        //                               let adjustedDy = newPosition.y - center.y
        //
        //                               let angle = atan2(dy, dx)
        //
        //                               var hue = angle * (180 / .pi)
        //                               if hue < 0 { hue += 360 }
        //
        //                               self.hue = hue / 360.0
        //
        //                                calculateColorsFromHSB()
        //
        //                                discHueKnobPosition = newPosition
        //                            })
        //                            .onEnded({ _ in
        //                                discHueKnobIsDragging = false
        //                                withAnimation {
        //                                    discHueKnobSize = 44
        //                                }
        //                            })
        //                        )
        //
        //                let size = min(geo.size.width, geo.size.height) - margin
        //
        //                Circle()
        //                    .fill(
        //                        AngularGradient(
        //                            gradient: Gradient(colors: [
        //                                Color(hue: hue, saturation: 1, brightness: 1),
        //                                Color(hue: hue, saturation: 0, brightness: 1)
        //                            ]),
        //                            center: .center,
        //                            startAngle: .degrees(0),
        //                            endAngle: .degrees(360)
        //                        )
        //                    )
        //                    .overlay(
        //                        Circle()
        //                            .fill(
        //                                RadialGradient(
        //                                    gradient: Gradient(colors: [Color.clear, Color.black]),
        //                                    center: .center,
        //                                    startRadius: 0,
        //                                    endRadius: size / 2
        //                                )
        //                            )
        //                    )
        //                    .frame(width: size, height: size)
        //            }
        //            .frame(maxWidth: .infinity, maxHeight: .infinity)
        //        }
        //        .padding()    }
    }
    
    @State var classicKnobPosition: CGPoint = CGPoint(x: 0, y: 0)
    @State var classicIsDragging: Bool = false
    @State var classicKnobSize: CGFloat = 44
    
    @ViewBuilder
    func Classic() -> some View {
        VStack {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hueColor)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .leading, endPoint: .trailing))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .bottom, endPoint: .top))
                    Circle()
                        .fill(primaryColor)
                        .frame(width: classicKnobSize, height: classicKnobSize)
                        .overlay {
                            if classicIsDragging {
                                Circle()
                                    .trim(from: 0.25, to: 0.75)
                                    .fill(.black)
                            }
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 4)
                        .position(classicKnobPosition)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.background.opacity(0.001))
                        .onAppear {
                            classicKnobPosition = CGPoint(x: saturation * geo.size.width, y: ( 1 - brightness ) * geo.size.height)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged({ dragValue in
                                    if !classicIsDragging {
                                        classicIsDragging = true
                                        withAnimation {
                                            classicKnobSize = 120
                                        }
                                    }
                                    var newPosition = dragValue.location
                                    if newPosition.x < 0 {
                                        newPosition.x = 0
                                    }
                                    
                                    if newPosition.x > geo.size.width {
                                        newPosition.x = geo.size.width
                                    }
                                    
                                    if newPosition.y < 0 {
                                        newPosition.y = 0
                                    }
                                    
                                    if newPosition.y > geo.size.height {
                                        newPosition.y = geo.size.height
                                    }
                                    
                                    saturation = newPosition.x /  geo.size.width
                                    brightness = 1 - (newPosition.y /  geo.size.height)
                                    calculateColorsFromHSB()
                                    
                                    classicKnobPosition = newPosition
                                })
                                .onEnded({ _ in
                                    classicIsDragging = false
                                    withAnimation {
                                        classicKnobSize = 44
                                    }
                                })
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: saturation) { _ in
                    classicKnobPosition.x = saturation * geo.size.width
                }
                .onChange(of: brightness) { _ in
                    classicKnobPosition.y = (1 - brightness) * geo.size.height
                }
            }
            .padding(8)
            
            HueSlider()
                .padding(.horizontal)
            Spacer()
        }
    }
    
    @ViewBuilder
    func Values() -> some View {
        VStack {
                    
            VStack {
                HStack(spacing: 0) {
                    Text("H")
                    HueSlider()
                        .padding(.horizontal, 8)
                    Text("\(Int(hue * 360))°")
                        .frame(width: 48)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                        }
                }
                .padding(.horizontal, 8)

                HStack(spacing: 0) {
                    Text("S")
                    SaturationSlider()
                        .padding(.horizontal, 8)
                    Text("\(Int(saturation * 100))%")
                        .frame(width: 48)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                        }
                }
                .padding(.horizontal, 8)
                
                HStack(spacing: 0) {
                    Text("B")
                    BrightnessSlider()
                        .padding(.horizontal, 8)
                    Text("\(Int(brightness * 100))%")
                        .frame(width: 48)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                        }
                }
                .padding(.horizontal, 8)
            }
//            .background {
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(.foreground.opacity(0.1))
//            }
            .padding(8)
            
            Divider()
            
            VStack {
                HStack(spacing: 0) {
                    Text("R")
                    RedSlider()
                        .padding(.horizontal, 8)
                    Text("\(Int(red * 255))")
                        .frame(width: 48)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                        }
                }
                .padding(.horizontal, 8)

                HStack(spacing: 0) {
                    Text("G")
                    GreenSlider()
                        .padding(.horizontal, 8)
                    Text("\(Int(green * 255))")
                        .frame(width: 48)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                        }
                }
                .padding(.horizontal, 8)
                
                HStack(spacing: 0) {
                    Text("B")
                    BlueSlider()
                        .padding(.horizontal, 8)
                    Text("\(Int(blue * 255))")
                        .frame(width: 48)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                        }
                }
                .padding(.horizontal, 8)
            }
//            .background {
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(.foreground.opacity(0.1))
//            }
            .padding(8)

        }
    }
    
    @ViewBuilder
    func Harmony() -> some View {
        let gradient:Gradient = {
            Gradient(colors:
                        Array(0...255).map {
                Color(hue:Double($0)/255 , saturation: saturation, brightness: brightness)
            }
            )
        }()
        
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AngularGradient(  gradient:gradient, center: .center))
                
                Circle()
                    .fill(RadialGradient(colors: [.white.withBrightness(brightness), .white.withBrightness(brightness).opacity(0)], center: .center, startRadius: 0, endRadius: geo.size.width / 2))
                    .overlay(
                        Circle()
                            .strokeBorder(.foreground.opacity(0.3), lineWidth: 2)
                        
                    )
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
 

    @ViewBuilder
    func HueSlider() -> some View {
        ScrubbingSlider(value: $hue, color: $hueColor, fillColor: $hueSliderGradient)
    }
    
    @ViewBuilder
    func SaturationSlider() -> some View {
        ScrubbingSlider(value: $saturation, color: $saturationColor, fillColor: $saturationSliderGradient)
    }
    
    @ViewBuilder
    func BrightnessSlider() -> some View {
        ScrubbingSlider(value: $brightness, color: $brightnessColor, fillColor: $brightnessSliderGradient)
    }
    
    @ViewBuilder
    func RedSlider() -> some View {
        ScrubbingSlider(value: $red, color: $primaryColor, fillColor: $redSliderGradient)
    }
    
    @ViewBuilder
    func GreenSlider() -> some View {
        ScrubbingSlider(value: $green, color: $primaryColor, fillColor: $greenSliderGradient)
    }
    
    @ViewBuilder
    func BlueSlider() -> some View {
        ScrubbingSlider(value: $blue, color: $primaryColor, fillColor: $blueSliderGradient)
    }
}


struct ScrubbingSpeed: Hashable {
    let speed: Float
    let verticalDistance: CGFloat
}

extension ScrubbingSpeed {
    static let defaultSpeeds = [
        ScrubbingSpeed(speed: 0.1, verticalDistance: 150),
        ScrubbingSpeed(speed: 0.25, verticalDistance: 100),
        ScrubbingSpeed(speed: 0.5, verticalDistance: 50),
        ScrubbingSpeed(speed: 1, verticalDistance: 0)
    ]
}

struct ScrubbingSlider: View {
    @Binding var value: Double
    @Binding var color: Color
    @Binding var fillColor: LinearGradient
    
    var scrubbingSpeeds = ScrubbingSpeed.defaultSpeeds
    var knobRadius: CGFloat = 44
    var height: CGFloat = 4.0
    
//    var minValue: CGFloat = 0.0
//    var maxValue: CGFloat = 1.0
    
    @GestureState var dragOffset = CGSize.zero
    @State private var lastDragValue: Double = 0
    @State private var isDragging: Bool = false
    @State private var actualKnobRadius: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: height/2)
                    .fill(fillColor)
                    .frame(height: height)
                Circle()
                    .fill(.white.opacity(0.001))
                    .frame(width: knobRadius, height: knobRadius)
                Circle()
                    .stroke(.foreground.opacity(0.3))
                    .frame(width: actualKnobRadius, height: actualKnobRadius)
                    .background {
                        Circle()
                            .fill(color)
                            .frame(width: actualKnobRadius, height: actualKnobRadius)
                        
                    }
                    .offset(CGSize(width: value * geometry.size.width - geometry.size.width / 2, height: 0))
                    
                    .animation(.default, value: isDragging)
                Rectangle()
                    .fill(.white.opacity(0.001))
                    .frame(height: knobRadius)
                    .gesture(
                        DragGesture()
                            .onChanged({ dragValue in
                                if !isDragging {
                                    isDragging = true
                                    value = dragValue.location.x / geometry.size.width
                                    withAnimation {
                                        actualKnobRadius = knobRadius
                                    }
                                }
                                let dragAmount = dragValue.translation.width - lastDragValue
                                let relativeDrag = Double(dragAmount / geometry.size.width)
                                value += relativeDrag * calculateScrubbingSpeed(for: dragValue.translation.height)
                                value = min(max(value, 0), 1)
                                lastDragValue = dragValue.translation.width
                            })
                            .onEnded({ _ in
                                // Reset lastDragValue at the end of the drag
                                lastDragValue = 0
                                isDragging = false
                                withAnimation {
                                    actualKnobRadius = 10
                                }
                            })
                    )
                    
            }
        }
        .frame(maxHeight: knobRadius)
    }
    
    private func calculateScrubbingSpeed(for verticalDistance: CGFloat) -> Double {
        for speed in scrubbingSpeeds {
            if abs(verticalDistance) >= Double(speed.verticalDistance) {
                return Double(speed.speed)
            }
        }
        return 1.0
    }
}

struct ScrubbingSliderView: View {
    @State var value: Double = 0.5
    @State var color: Color = .black
    @State var gradient: LinearGradient = LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)

    var body: some View {
        ScrubbingSlider(value: $value, color: $color, fillColor: $gradient)
            .padding()
            
    }
}




#Preview {
    MuseColors { color in
        
    } onEyedropperSelected: {
        
    } onClose: {
        
    }

}

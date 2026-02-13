//
//  VSlider.swift
//  MusePro
//
//  Created by Omer Karisman on 10.02.24.
//

import Foundation
import SwiftUI

struct VSlider<V: BinaryFloatingPoint>: View {
    var value: Binding<V>
    var range: ClosedRange<V> = 0...1
    var step: V.Stride? = nil
    var onEditingChanged: (Bool) -> Void = { _ in }
    
    let drawRadius: CGFloat = 14
    let dragRadius: CGFloat = 16
    let lineWidth: CGFloat = 2
    
    @State var validDrag = false
    
    init(value: Binding<V>, in range: ClosedRange<V> = 0...1, step: V.Stride? = nil, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.value = value
        
        if let step = step {
            self.step = step
            var newUpperbound = range.lowerBound
            while newUpperbound.advanced(by: step) <= range.upperBound{
                newUpperbound = newUpperbound.advanced(by: step)
            }
            self.range = ClosedRange(uncheckedBounds: (range.lowerBound, newUpperbound))
        } else {
            self.range = range
        }
        
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Handle
               
                
                // Catches drag gesture
                Rectangle()
                    .frame(minWidth: CGFloat(self.dragRadius))
                    .foregroundColor(Color.red.opacity(0.001))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded({ _ in
                                self.validDrag = false
                                self.onEditingChanged(false)
                            })
                            .onChanged(self.handleDragged(in: geometry))
                    )
                Circle()
                    .frame(width: 2 * self.drawRadius, height: 2 * self.drawRadius)
                    .position(self.getPoint(in: geometry))
                    .foregroundColor(Color.sliderForeground)
                    .shadow(radius: 2, y: 2)
                    .hoverEffect()
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded({ _ in
                                self.validDrag = false
                                self.onEditingChanged(false)
                            })
                            .onChanged(self.handleDragged(in: geometry))
                    )
            }
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: self.drawRadius + 4)
                    .stroke(Color.sliderStroke)
                    .frame(width: self.drawRadius * 2 + 8)
            }
        }
    }
}

extension VSlider {
    func getPoint(in geometry: GeometryProxy) -> CGPoint {
        let x = geometry.size.width / 2
        let location = value.wrappedValue - range.lowerBound
        let scale = V(2 * drawRadius - (geometry.size.height - 8)) / (range.upperBound - range.lowerBound)
        let y = CGFloat(location * scale) + (geometry.size.height - 8) - drawRadius
        return CGPoint(x: x, y: y)
    }
    
    func handleDragged(in geometry: GeometryProxy) -> (DragGesture.Value) -> Void {
        return { drag in
//            if drag.startLocation.distance(to: self.getPoint(in: geometry)) < self.dragRadius && !self.validDrag {
                self.validDrag = true
                self.onEditingChanged(true)
//            }
            
            if self.validDrag {
                let location = drag.location.y - geometry.size.height + self.drawRadius
                let scale = CGFloat(self.range.upperBound - self.range.lowerBound) / (2 * self.drawRadius - (geometry.size.height - 8))
                let newValue = V(location * scale) + self.range.lowerBound
                let clampedValue = max(min(newValue, self.range.upperBound), self.range.lowerBound)
                
                if self.step != nil {
                    let step = V.zero.advanced(by: self.step!)
                    let newValue = round((clampedValue - self.range.lowerBound) / step) * step + self.range.lowerBound
                    if self.value.wrappedValue != newValue {
                        if newValue == self.range.upperBound || newValue == self.range.lowerBound {
                            Haptic.impact(.rigid).generate()
                        } 
//                        else {
//                            Haptic.impact(.light).generate()
//                        }
                    }
                } else {
                    if self.value.wrappedValue != clampedValue {
                        if clampedValue == self.range.upperBound || clampedValue == self.range.lowerBound {
                            Haptic.impact(.rigid).generate()
                        }
                        self.value.wrappedValue = clampedValue
                    }
                }
            }
        }
    }
}


struct HSlider<V: BinaryFloatingPoint>: View {
    var value: Binding<V>
    var range: ClosedRange<V> = 0...1
    var step: V.Stride? = nil
    var onEditingChanged: (Bool) -> Void = { _ in }
    let drawRadius: CGFloat = 18
    let dragRadius: CGFloat = 20
    let lineWidth: CGFloat = 2
    @State var validDrag = false

    init(value: Binding<V>, in range: ClosedRange<V> = 0...1, step: V.Stride? = nil, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.value = value
        if let step = step {
            self.step = step
            var newUpperbound = range.lowerBound
            while newUpperbound.advanced(by: step) <= range.upperBound {
                newUpperbound = newUpperbound.advanced(by: step)
            }
            self.range = ClosedRange(uncheckedBounds: (range.lowerBound, newUpperbound))
        } else {
            self.range = range
        }
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Handle
               

                // Catches drag gesture
                Rectangle()
                    .frame(minHeight: CGFloat(self.dragRadius))
                    .foregroundColor(Color.red.opacity(0.001))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded({ _ in
                                self.validDrag = false
                                self.onEditingChanged(false)
                            })
                            .onChanged(self.handleDragged(in: geometry))
                    )
                Circle()
                    .frame(width: 2 * self.drawRadius, height: 2 * self.drawRadius)
                    .position(self.getPoint(in: geometry))
                    .foregroundColor(Color.sliderForeground)
                    .shadow(radius: 2, x: 2)
                    .hoverEffect()
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded({ _ in
                                self.validDrag = false
                                self.onEditingChanged(false)
                            })
                            .onChanged(self.handleDragged(in: geometry))
                    )
            }
            .padding(.horizontal, 4)
//            .background {
//                RoundedRectangle(cornerRadius: self.drawRadius + 4)
//                    .stroke(Color.sliderStroke)
//                    .frame(height: self.drawRadius * 2 + 8)
//            }
        }
    }
}
extension HSlider {
    func getPoint(in geometry: GeometryProxy) -> CGPoint {
        let y = geometry.size.height / 2
        let location = value.wrappedValue - range.lowerBound
        let scale = V(geometry.size.width - 2 * drawRadius) / (range.upperBound - range.lowerBound)
        let x = CGFloat(location * scale) + drawRadius
        return CGPoint(x: x, y: y)
    }

    func handleDragged(in geometry: GeometryProxy) -> (DragGesture.Value) -> Void {
        return { drag in
//            if drag.startLocation.distance(to: self.getPoint(in: geometry)) < self.dragRadius && !self.validDrag {
                self.validDrag = true
                self.onEditingChanged(true)
//            }
            if self.validDrag {
                let location = drag.location.x - self.drawRadius
                let scale = CGFloat(self.range.upperBound - self.range.lowerBound) / (geometry.size.width - 2 * self.drawRadius)
                let newValue = V(location * scale) + self.range.lowerBound
                let clampedValue = max(min(newValue, self.range.upperBound), self.range.lowerBound)
                if self.step != nil {
                    let step = V.zero.advanced(by: self.step!)
                    let newValue = round((clampedValue - self.range.lowerBound) / step) * step + self.range.lowerBound
                    if self.value.wrappedValue != newValue {
                        if newValue == self.range.upperBound || newValue == self.range.lowerBound {
                            Haptic.impact(.rigid).generate()
                        } 
//                        else {
//                            Haptic.impact(.light).generate()
//                        }
                    }
                   
                    self.value.wrappedValue = newValue
                } else {
                    if self.value.wrappedValue != clampedValue {
                        if clampedValue == self.range.upperBound || clampedValue == self.range.lowerBound {
                            Haptic.impact(.rigid).generate()
                        }
                        self.value.wrappedValue = clampedValue
                    }
                }
            }
        }
    }
}

import Foundation
import CoreGraphics
import simd

struct Vertex {
    var position: vector_float4
    var textCoord: vector_float2
    
    init(position: CGPoint, textCoord: CGPoint) {
        self.position = position.toFloat4()
        self.textCoord = textCoord.toFloat2()
    }
}

struct Sizes {
    var brushSize: vector_float2
    var textureSize: vector_float2
    
    var textureScale: Float
    let textureOffset: vector_float2

    var _color: MLColor
    var color: vector_float4 {
        return _color.toFloat4()
    }
    
    init(brushSize: CGSize, textureSize: CGSize, textureScale: Float, textureOffset: CGSize, color: MLColor) {
        self.brushSize = vector_float2(Float(brushSize.width), Float(brushSize.height))
        self.textureSize = vector_float2(Float(textureSize.width), Float(textureSize.height))
        self.textureScale = textureScale
        self.textureOffset = vector_float2(Float(textureOffset.width), Float(textureOffset.height))
        self._color = color
    }
}

struct FragmentColor {
    var _color: MLColor
    var color: vector_float4 {
        return _color.toFloat4()
    }
    
    init(color: MLColor) {
        self._color = color
    }
}

struct Point {
    var position: vector_float4
    var _color: MLColor
    var color: vector_float4 {
        return _color.toFloat4()
    }
    var angle: Float
    var size: Float

    init(x: CGFloat, y: CGFloat, color: MLColor, size: CGFloat, angle: CGFloat = 0) {
        self.position = vector_float4(Float(x), Float(y), 0, 1)
        self.size = Float(size)
        self._color = color
        self.angle = Float(angle)
    }
}

struct ControlData {
    var useInverseMask: Int32
}

struct LayerRenderData {
    var opacity: Float
}

struct ScrollingTransform {
    var offset: vector_float2
    var scale: Float
    
    init(offset: CGPoint, scale: CGFloat) {
        self.offset = vector_float2(Float(offset.x), Float(offset.y))
        self.scale = Float(scale)
    }
}

struct Uniforms {
    var scaleMatrix: [Float]

    init(scale: Float = 1, drawableSize: CGSize) {
//        translationMatrix = Matrix.identity
//            scaleMatrix = Matrix.identity.scaling(x:  2 / Float(drawableSize.width),  y: -2 / Float(drawableSize.height), z: 1).m
        scaleMatrix = Matrix.identity.scaling(x:  0.5,  y: 0.5, z: 1).m
//        rotationMatrix = Matrix.identity.rotation(x: 0, y: 0, z: 0).m
//        translationMatrix = Matrix.identity.translation(x: -1, y: 1, z: 0).m
    }
}

struct ColorBuffer {
    var color: SIMD4<Float>
    
    init(r: Float, g: Float, b: Float, a: Float) {
        color = SIMD4(r,g,b,a)
    }
}

class Matrix {
    
     var m: [Float]
    
    static var identity = Matrix()
    
    init() {
        m = [1, 0, 0, 0,
             0, 1, 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1
        ]
    }
    
    @discardableResult
    func translation(x: Float, y: Float, z: Float) -> Matrix {
        m[12] = x
        m[13] = y
        m[14] = z
        return self
    }
    
    @discardableResult
    func scaling(x: Float, y: Float, z: Float)  -> Matrix  {
        m[0] = x
        m[5] = y
        m[10] = z
        return self
    }
}

// MARK: - Point Utils
extension CGPoint {
    
    static func middle(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5)
    }
    
    func distance(to other: CGPoint) -> CGFloat {
        let p = pow(x - other.x, 2) + pow(y - other.y, 2)
        return sqrt(p)
    }
    
    func angle(to other: CGPoint = .zero) -> CGFloat {
        let point = self - other        
        if y == 0 {
            return x >= 0 ? 0 : CGFloat.pi
        }
        if point.x == 0 {
              return point.y > 0 ? -CGFloat.pi / 2 : CGFloat.pi / 2
          }
        return -CGFloat(atan2f(Float(point.y), Float(point.x)))
    }
    
//    func angle(to other: CGPoint = .zero) -> CGFloat {
//       let point = self - other
//       
//       // Calculate angle and convert it to a range [0, 2π]
//       let angle = atan2(point.y, point.x)
//       return angle >= 0 ? angle : angle + 2 * .pi
//    }
    
    func toFloat4(z: CGFloat = 0, w: CGFloat = 1) -> vector_float4 {
        return [Float(x), Float(y), Float(z) ,Float(w)]
    }
    
    func toFloat2() -> vector_float2 {
        return [Float(x), Float(y)]
    }
    
    func offsetedBy(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        var point = self
        point.x += x
        point.y += y
        return point
    }
    
    func rotatedBy(_ angle: CGFloat, anchor: CGPoint) -> CGPoint {
        let point = self - anchor
        let a = Double(-angle)
        let x = Double(point.x)
        let y = Double(point.y)
        let x_ = x * cos(a) - y * sin(a);
        let y_ = x * sin(a) + y * cos(a);
        return CGPoint(x: CGFloat(x_), y: CGFloat(y_)) + anchor
    }
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func +=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs + rhs
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

func +(lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}

func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}

func +(lhs: CGPoint, rhs: CGSize) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
}

func -(lhs: CGPoint, rhs: CGSize) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
}

func *(lhs: CGPoint, rhs: CGSize) -> CGPoint {
    return CGPoint(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
}

func /(lhs: CGPoint, rhs: CGSize) -> CGPoint {
    return CGPoint(x: lhs.x / rhs.width, y: lhs.y / rhs.height)
}


extension Comparable {
    func valueBetween(min: Self, max: Self) -> Self {
        if self > max {
            return max
        } else if self < min {
            return min
        }
        return self
    }
}

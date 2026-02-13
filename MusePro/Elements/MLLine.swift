import Foundation
import CoreGraphics

struct MLLine: Codable, Equatable {
    static func == (lhs: MLLine, rhs: MLLine) -> Bool {
        return lhs.begin == rhs.begin && lhs.end == rhs.end
    }
    
    var begin: CGPoint
    var end: CGPoint
    
    var pointSize: CGFloat
    
    var color: MLColor?
    
    init(begin: CGPoint, end: CGPoint, pointSize: CGFloat, color: MLColor?, opacity: CGFloat, flow: CGFloat) {
        self.begin = begin
        self.end = end
        self.pointSize = pointSize
        self.color = color
        self.opacity = opacity
        self.flow = flow
    }
    
    var length: CGFloat {
        return begin.distance(to: end)
    }
    
    var angle: CGFloat {
        return end.angle(to: begin)
    }
    
    var opacity: CGFloat
    var flow: CGFloat

    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case begin
        case end
        case size
        case step
        case color
        case opacity
        case flow
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let beginInts = try container.decode([Int].self, forKey: .begin)
        let endInts = try container.decode([Int].self, forKey: .end)
        begin = CGPoint.make(from: beginInts)
        end = CGPoint.make(from: endInts)
        let intSize = try container.decode(Int.self, forKey: .size)
        pointSize = CGFloat(intSize)
        color = try? container.decode(MLColor.self, forKey: .color)
        opacity = try container.decode(CGFloat.self, forKey: .opacity)
        flow = try container.decode(CGFloat.self, forKey: .flow)

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(begin.encodeToInts(), forKey: .begin)
        try container.encode(end.encodeToInts(), forKey: .end)
        try container.encode(pointSize, forKey: .size)
        if let color = self.color {
            try container.encode(color, forKey: .color)
        }
    }
}

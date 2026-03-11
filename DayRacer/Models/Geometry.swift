import Foundation

struct LineSegment: Codable, Sendable {
    let start: CGPoint
    let end: CGPoint

    var boundingBox: CGRect {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

struct CubicBezier: Codable, Sendable {
    let p0: CGPoint
    let p1: CGPoint
    let p2: CGPoint
    let p3: CGPoint

    func point(at t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t
        let x = mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x
        let y = mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
        return CGPoint(x: x, y: y)
    }
}

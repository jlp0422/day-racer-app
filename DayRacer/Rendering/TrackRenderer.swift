import SwiftUI

/// Renders a GeneratedCorner onto a SwiftUI Canvas.
/// Draws 7 static layers (bottom to top): grass, gravel, barriers, asphalt, markings, kerbs, ideal line.
enum TrackRenderer {

    // MARK: - Main Render

    static func render(
        corner: GeneratedCorner,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        drawGrass(in: &context, size: size)
        drawGravel(corner: corner, in: &context)
        drawAsphalt(corner: corner, in: &context)
        drawBarriers(corner: corner, in: &context)
        drawMarkings(corner: corner, in: &context)
        drawKerbs(corner: corner, in: &context)
        drawIdealLine(corner: corner, in: &context)
    }

    // MARK: - Layer 1: Grass Background

    static func drawGrass(in context: inout GraphicsContext, size: CGSize) {
        let rect = Path(CGRect(origin: .zero, size: size))
        context.fill(rect, with: .color(Color(hex: 0x4A7C34)))
    }

    // MARK: - Layer 2: Gravel Run-off

    static func drawGravel(corner: GeneratedCorner, in context: inout GraphicsContext) {
        let gravelWidth = corner.corner.type.gravelWidth

        let outerGravelPoints = offsetPolyline(corner.outerBoundary.points, by: gravelWidth)
        let innerGravelPoints = offsetPolyline(corner.innerBoundary.points, by: -gravelWidth)

        // Outer gravel strip: between outer boundary and outer gravel edge
        let outerGravelPath = closedStripPath(
            forward: corner.outerBoundary.points,
            backward: outerGravelPoints
        )
        context.fill(outerGravelPath, with: .color(Color(hex: 0xC8B88A)))

        // Inner gravel strip: between inner boundary and inner gravel edge
        let innerGravelPath = closedStripPath(
            forward: corner.innerBoundary.points,
            backward: innerGravelPoints
        )
        context.fill(innerGravelPath, with: .color(Color(hex: 0xC8B88A)))
    }

    // MARK: - Layer 3: Asphalt

    static func drawAsphalt(corner: GeneratedCorner, in context: inout GraphicsContext) {
        let asphaltPath = closedStripPath(
            forward: corner.outerBoundary.points,
            backward: corner.innerBoundary.points
        )
        context.fill(asphaltPath, with: .color(Color(hex: 0x444444)))
    }

    // MARK: - Layer 4: Barriers

    static func drawBarriers(corner: GeneratedCorner, in context: inout GraphicsContext) {
        drawBarrier(boundary: corner.innerBoundary, in: &context)
        drawBarrier(boundary: corner.outerBoundary, in: &context)
    }

    private static func drawBarrier(boundary: TrackBoundary, in context: inout GraphicsContext) {
        switch boundary.barrierStyle {
        case .tireStack:
            drawTireStackBarrier(points: boundary.points, in: &context)
        case .concrete:
            drawConcreteBarrier(points: boundary.points, in: &context)
        case .armco:
            drawArmcoBarrier(points: boundary.points, in: &context)
        }
    }

    private static func drawTireStackBarrier(points: [CGPoint], in context: inout GraphicsContext) {
        let radius: CGFloat = 3.0
        let spacing: CGFloat = 8.0
        let colors: [Color] = [Color(hex: 0x333333), Color(hex: 0x888888)]

        var accumulated: CGFloat = 0
        var colorIndex = 0

        for i in 0..<(points.count - 1) {
            let dx = points[i + 1].x - points[i].x
            let dy = points[i + 1].y - points[i].y
            let segLen = hypot(dx, dy)
            var t: CGFloat = 0

            while accumulated + (segLen * (1 - t)) >= spacing {
                let remaining = spacing - accumulated
                t += remaining / segLen
                if t > 1 { break }
                let x = points[i].x + dx * t
                let y = points[i].y + dy * t
                let circle = Path(ellipseIn: CGRect(
                    x: x - radius, y: y - radius,
                    width: radius * 2, height: radius * 2
                ))
                context.fill(circle, with: .color(colors[colorIndex % colors.count]))
                colorIndex += 1
                accumulated = 0
            }
            accumulated += segLen * (1 - t)
        }
    }

    private static func drawConcreteBarrier(points: [CGPoint], in context: inout GraphicsContext) {
        guard points.count >= 2 else { return }

        // Shadow line (offset 1pt)
        var shadowPath = Path()
        shadowPath.move(to: CGPoint(x: points[0].x + 1, y: points[0].y + 1))
        for i in 1..<points.count {
            shadowPath.addLine(to: CGPoint(x: points[i].x + 1, y: points[i].y + 1))
        }
        context.stroke(shadowPath, with: .color(Color(hex: 0x222222).opacity(0.5)),
                       style: StrokeStyle(lineWidth: 5))

        // Main concrete line
        var mainPath = Path()
        mainPath.move(to: points[0])
        for i in 1..<points.count {
            mainPath.addLine(to: points[i])
        }
        context.stroke(mainPath, with: .color(Color(hex: 0x999999)),
                       style: StrokeStyle(lineWidth: 4))
    }

    private static func drawArmcoBarrier(points: [CGPoint], in context: inout GraphicsContext) {
        guard points.count >= 2 else { return }

        // Main metallic line
        var mainPath = Path()
        mainPath.move(to: points[0])
        for i in 1..<points.count {
            mainPath.addLine(to: points[i])
        }
        context.stroke(mainPath, with: .color(Color(hex: 0xC0C0C0)),
                       style: StrokeStyle(lineWidth: 2))

        // Post marks every 20pt
        let postSpacing: CGFloat = 20
        var accumulated: CGFloat = 0

        for i in 0..<(points.count - 1) {
            let dx = points[i + 1].x - points[i].x
            let dy = points[i + 1].y - points[i].y
            let segLen = hypot(dx, dy)
            guard segLen > 0 else { continue }
            let nx = -dy / segLen
            let ny = dx / segLen
            var t: CGFloat = 0

            while accumulated + (segLen * (1 - t)) >= postSpacing {
                let remaining = postSpacing - accumulated
                t += remaining / segLen
                if t > 1 { break }
                let x = points[i].x + dx * t
                let y = points[i].y + dy * t
                var postPath = Path()
                postPath.move(to: CGPoint(x: x - nx * 3, y: y - ny * 3))
                postPath.addLine(to: CGPoint(x: x + nx * 3, y: y + ny * 3))
                context.stroke(postPath, with: .color(Color(hex: 0x888888)),
                               style: StrokeStyle(lineWidth: 1.5))
                accumulated = 0
            }
            accumulated += segLen * (1 - t)
        }
    }

    // MARK: - Layer 5: Markings

    static func drawMarkings(corner: GeneratedCorner, in context: inout GraphicsContext) {
        let centerline = corner.centerline
        guard centerline.count >= 2 else { return }

        var centerPath = Path()
        centerPath.move(to: centerline[0])
        for i in 1..<centerline.count {
            centerPath.addLine(to: centerline[i])
        }
        context.stroke(
            centerPath,
            with: .color(.white.opacity(0.4)),
            style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
        )
    }

    // MARK: - Layer 6: Kerbs

    static func drawKerbs(corner: GeneratedCorner, in context: inout GraphicsContext) {
        let innerPoints = corner.innerBoundary.points
        guard innerPoints.count >= 2 else { return }
        let apexPoints = corner.idealLine.apexPoints
        guard !apexPoints.isEmpty else { return }

        let kerbWidth = GameConstants.Track.Kerb.width
        let kerbHeight = GameConstants.Track.Kerb.height
        let kerbZoneRadius: CGFloat = 40

        for apex in apexPoints {
            // Find inner boundary points near this apex
            for i in 0..<(innerPoints.count - 1) {
                let mid = CGPoint(
                    x: (innerPoints[i].x + innerPoints[i + 1].x) / 2,
                    y: (innerPoints[i].y + innerPoints[i + 1].y) / 2
                )
                let distToApex = hypot(mid.x - apex.x, mid.y - apex.y)
                guard distToApex < kerbZoneRadius else { continue }

                let dx = innerPoints[i + 1].x - innerPoints[i].x
                let dy = innerPoints[i + 1].y - innerPoints[i].y
                let segLen = hypot(dx, dy)
                guard segLen > 0 else { continue }

                let angle = atan2(dy, dx)
                let nx = -dy / segLen
                let ny = dx / segLen

                // Alternate red/white blocks along segment
                let blockCount = max(1, Int(segLen / kerbWidth))
                for b in 0..<blockCount {
                    let t = CGFloat(b) / CGFloat(max(1, blockCount))
                    let cx = innerPoints[i].x + dx * t
                    let cy = innerPoints[i].y + dy * t

                    let color: Color = b % 2 == 0 ? Color(hex: 0xE8003D) : .white
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: cx, y: cy)
                    transform = transform.rotated(by: angle)
                    transform = transform.translatedBy(
                        x: -kerbWidth / 2,
                        y: -kerbHeight / 2 + nx * 2
                    )

                    let rect = Path(CGRect(x: 0, y: 0, width: kerbWidth, height: kerbHeight))
                    var transformedContext = context
                    transformedContext.concatenate(CGAffineTransform(
                        translationX: cx, y: cy
                    ).rotated(by: angle))
                    transformedContext.fill(
                        Path(CGRect(
                            x: -kerbWidth / 2,
                            y: -kerbHeight / 2,
                            width: kerbWidth,
                            height: kerbHeight
                        )),
                        with: .color(color)
                    )
                }
            }
        }
    }

    // MARK: - Layer 7: Ideal Racing Line

    static func drawIdealLine(corner: GeneratedCorner, in context: inout GraphicsContext) {
        let idealPoints = corner.idealLine.points
        guard idealPoints.count >= 2 else { return }

        var idealPath = Path()
        idealPath.move(to: idealPoints[0])
        for i in 1..<idealPoints.count {
            idealPath.addLine(to: idealPoints[i])
        }
        context.stroke(
            idealPath,
            with: .color(Color(hex: 0xE8003D).opacity(GameConstants.Rendering.idealLineOpacity)),
            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
        )
    }

    // MARK: - Start/Finish Zones

    static func drawStartZone(at point: CGPoint, in context: inout GraphicsContext) {
        // Pulsing circle + START label
        let radius: CGFloat = 16
        let circle = Path(ellipseIn: CGRect(
            x: point.x - radius, y: point.y - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(circle, with: .color(.green.opacity(0.7)),
                       style: StrokeStyle(lineWidth: 2))
        context.draw(
            Text("START").font(.system(size: 8, weight: .bold)).foregroundColor(.green),
            at: CGPoint(x: point.x, y: point.y + radius + 8)
        )
    }

    static func drawFinishZone(at point: CGPoint, in context: inout GraphicsContext) {
        let radius: CGFloat = 16
        let circle = Path(ellipseIn: CGRect(
            x: point.x - radius, y: point.y - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(circle, with: .color(.white.opacity(0.7)),
                       style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
        context.draw(
            Text("FINISH").font(.system(size: 8, weight: .bold)).foregroundColor(.white),
            at: CGPoint(x: point.x, y: point.y + radius + 8)
        )
    }

    // MARK: - Geometry Helpers

    /// Creates a closed path from two polylines (forward along first, backward along second).
    static func closedStripPath(forward: [CGPoint], backward: [CGPoint]) -> Path {
        guard !forward.isEmpty, !backward.isEmpty else { return Path() }
        var path = Path()
        path.move(to: forward[0])
        for pt in forward.dropFirst() {
            path.addLine(to: pt)
        }
        for pt in backward.reversed() {
            path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }

    /// Offset a polyline by a perpendicular distance.
    static func offsetPolyline(_ points: [CGPoint], by distance: CGFloat) -> [CGPoint] {
        guard points.count >= 2 else { return points }
        var result: [CGPoint] = []

        for i in 0..<points.count {
            let normal = polylineNormal(at: i, in: points)
            result.append(CGPoint(
                x: points[i].x + normal.x * distance,
                y: points[i].y + normal.y * distance
            ))
        }
        return result
    }

    private static func polylineNormal(at index: Int, in points: [CGPoint]) -> CGPoint {
        let prev: CGPoint
        let next: CGPoint

        if index == 0 {
            prev = points[0]
            next = points[1]
        } else if index == points.count - 1 {
            prev = points[points.count - 2]
            next = points[points.count - 1]
        } else {
            prev = points[index - 1]
            next = points[index + 1]
        }

        let dx = next.x - prev.x
        let dy = next.y - prev.y
        let len = hypot(dx, dy)
        guard len > 0 else { return CGPoint(x: 1, y: 0) }

        return CGPoint(x: -dy / len, y: dx / len)
    }
}

import Testing
@testable import DayRacer
import Foundation

@Suite("TrackRenderer")
struct TrackRendererTests {

    // MARK: - Geometry Helpers

    @Suite("closedStripPath")
    struct ClosedStripPathTests {
        @Test("Produces non-empty path from valid polylines")
        func nonEmpty() {
            let forward = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0), CGPoint(x: 10, y: 10)]
            let backward = [CGPoint(x: 2, y: 2), CGPoint(x: 12, y: 2), CGPoint(x: 12, y: 12)]
            let path = TrackRenderer.closedStripPath(forward: forward, backward: backward)
            #expect(!path.isEmpty)
        }

        @Test("Returns empty path when forward is empty")
        func emptyForward() {
            let path = TrackRenderer.closedStripPath(forward: [], backward: [CGPoint(x: 0, y: 0)])
            #expect(path.isEmpty)
        }

        @Test("Returns empty path when backward is empty")
        func emptyBackward() {
            let path = TrackRenderer.closedStripPath(forward: [CGPoint(x: 0, y: 0)], backward: [])
            #expect(path.isEmpty)
        }

        @Test("Bounding box encompasses both polylines")
        func boundingBox() {
            let forward = [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)]
            let backward = [CGPoint(x: 0, y: 50), CGPoint(x: 100, y: 50)]
            let path = TrackRenderer.closedStripPath(forward: forward, backward: backward)
            let bb = path.boundingRect
            #expect(bb.minX <= 0)
            #expect(bb.maxX >= 100)
            #expect(bb.minY <= 0)
            #expect(bb.maxY >= 50)
        }
    }

    @Suite("offsetPolyline")
    struct OffsetPolylineTests {
        @Test("Offset preserves point count")
        func preservesCount() {
            let points = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0), CGPoint(x: 20, y: 0)]
            let offset = TrackRenderer.offsetPolyline(points, by: 5)
            #expect(offset.count == points.count)
        }

        @Test("Positive offset shifts perpendicular to direction")
        func positiveOffset() {
            // Horizontal line going right → positive offset shifts upward (negative y in screen coords)
            let points = [CGPoint(x: 0, y: 50), CGPoint(x: 100, y: 50)]
            let offset = TrackRenderer.offsetPolyline(points, by: 10)
            for pt in offset {
                #expect(abs(pt.y - 40) < 0.001)
            }
        }

        @Test("Negative offset shifts opposite direction")
        func negativeOffset() {
            let points = [CGPoint(x: 0, y: 50), CGPoint(x: 100, y: 50)]
            let offset = TrackRenderer.offsetPolyline(points, by: -10)
            for pt in offset {
                #expect(abs(pt.y - 60) < 0.001)
            }
        }

        @Test("Zero offset returns original points")
        func zeroOffset() {
            let points = [CGPoint(x: 5, y: 10), CGPoint(x: 15, y: 20)]
            let offset = TrackRenderer.offsetPolyline(points, by: 0)
            #expect(offset.count == 2)
            #expect(abs(offset[0].x - 5) < 0.001)
            #expect(abs(offset[0].y - 10) < 0.001)
        }

        @Test("Single point returns unchanged")
        func singlePoint() {
            let points = [CGPoint(x: 5, y: 5)]
            let offset = TrackRenderer.offsetPolyline(points, by: 10)
            #expect(offset.count == 1)
            #expect(offset[0] == points[0])
        }
    }

    // MARK: - Barrier Style per Corner Type

    @Suite("Barrier Styles")
    struct BarrierStyleTests {
        @Test("Barrier styles match arch doc", arguments: [
            (CornerType.hairpin, BarrierStyle.tireStack),
            (.doubleApex, .tireStack),
            (.tight90, .concrete),
            (.chicane, .armco),
            (.esses, .concrete),
            (.sweeper, .armco),
        ])
        func barrierStyles(type: CornerType, expected: BarrierStyle) {
            #expect(type.barrierStyle == expected)
        }
    }

    // MARK: - Track Width Ordering

    @Suite("Track Widths")
    struct TrackWidthTests {
        @Test("Hairpin is widest, sweeper is narrowest")
        func widthOrdering() {
            let widths: [(CornerType, CGFloat)] = CornerType.allCases.map { ($0, $0.trackWidth) }
            let sorted = widths.sorted { $0.1 > $1.1 }
            #expect(sorted.first?.0 == .hairpin)
            #expect(sorted.last?.0 == .sweeper)
        }

        @Test("All track widths are positive")
        func allPositive() {
            for type in CornerType.allCases {
                #expect(type.trackWidth > 0)
            }
        }
    }

    // MARK: - Gravel Width Ordering

    @Suite("Gravel Widths")
    struct GravelWidthTests {
        @Test("Gravel widths are positive and less than track widths")
        func gravelSmallerThanTrack() {
            for type in CornerType.allCases {
                #expect(type.gravelWidth > 0)
                #expect(type.gravelWidth < type.trackWidth)
            }
        }
    }

    // MARK: - Generated Corner Rendering Integration

    @Suite("Corner Rendering")
    struct CornerRenderingTests {
        let generator = TrackGenerator()

        private func makeCorner(type: CornerType) -> GeneratedCorner {
            let screenSize = CGSize(width: 393, height: 852)
            return generator.generateCorner(
                type: type,
                index: 0,
                seed: 42,
                screenSize: screenSize
            )
        }

        @Test("All corner types produce valid geometry", arguments: CornerType.allCases)
        func validGeometry(type: CornerType) {
            let corner = makeCorner(type: type)
            #expect(corner.centerline.count >= 2)
            #expect(corner.innerBoundary.points.count >= 2)
            #expect(corner.outerBoundary.points.count >= 2)
            #expect(corner.idealLine.points.count >= 2)
        }

        @Test("Boundaries are on correct sides", arguments: CornerType.allCases)
        func boundarySides(type: CornerType) {
            let corner = makeCorner(type: type)
            #expect(corner.innerBoundary.side == .inner)
            #expect(corner.outerBoundary.side == .outer)
        }

        @Test("Ideal line stays within boundaries", arguments: CornerType.allCases)
        func idealLineWithinBounds(type: CornerType) {
            let corner = makeCorner(type: type)
            let outerBB = boundingBox(of: corner.outerBoundary.points)
            let innerBB = boundingBox(of: corner.innerBoundary.points)
            let combinedBB = outerBB.union(innerBB)

            // Ideal line points should all be within the combined bounding box (with margin)
            let margin: CGFloat = 5
            let expanded = combinedBB.insetBy(dx: -margin, dy: -margin)
            for pt in corner.idealLine.points {
                #expect(expanded.contains(pt),
                        "Ideal line point \(pt) outside track bounds \(expanded)")
            }
        }

        @Test("Entry and exit points exist on screen", arguments: CornerType.allCases)
        func entryExitOnScreen(type: CornerType) {
            let corner = makeCorner(type: type)
            let screenRect = CGRect(x: -10, y: -10, width: 413, height: 872)
            #expect(screenRect.contains(corner.entryPoint))
            #expect(screenRect.contains(corner.exitPoint))
        }

        @Test("Asphalt strip path is non-empty", arguments: CornerType.allCases)
        func asphaltStripNonEmpty(type: CornerType) {
            let corner = makeCorner(type: type)
            let path = TrackRenderer.closedStripPath(
                forward: corner.outerBoundary.points,
                backward: corner.innerBoundary.points
            )
            #expect(!path.isEmpty)
        }

        @Test("Gravel offset produces wider boundary", arguments: CornerType.allCases)
        func gravelOffsetWider(type: CornerType) {
            let corner = makeCorner(type: type)
            let gravelWidth = corner.corner.type.gravelWidth
            let outerGravel = TrackRenderer.offsetPolyline(
                corner.outerBoundary.points, by: gravelWidth
            )
            let outerGravelBB = boundingBox(of: outerGravel)
            let outerBB = boundingBox(of: corner.outerBoundary.points)
            // Gravel boundary should be at least as wide as the track boundary
            #expect(outerGravelBB.width >= outerBB.width - 1 ||
                    outerGravelBB.height >= outerBB.height - 1)
        }

        private func boundingBox(of points: [CGPoint]) -> CGRect {
            guard let first = points.first else { return .zero }
            var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
            for pt in points.dropFirst() {
                minX = min(minX, pt.x)
                maxX = max(maxX, pt.x)
                minY = min(minY, pt.y)
                maxY = max(maxY, pt.y)
            }
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
}

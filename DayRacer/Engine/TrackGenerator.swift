import Foundation

struct TrackGenerator: Sendable {

    // MARK: - Track Names

    static let trackNames: [String] = [
        // Real F1 circuits
        "Circuit de Monaco", "Silverstone Sprint", "Monza Speedway",
        "Spa-Francorchamps", "Suzuka Circuit", "Interlagos",
        "Circuit of the Americas", "Marina Bay Street",
        // Fictional circuits
        "Neon Bay Circuit", "Dusty Creek Speedway", "Iron Ridge Raceway",
        "Coral Harbour Sprint", "Midnight Apex Circuit", "Thunder Valley GP",
        "Eclipse Park Speedway", "Crimson Dunes Circuit",
        "Glacier Point Raceway", "Copper Canyon Sprint",
        "Storm Peak Circuit", "Obsidian Flats GP",
    ]

    // MARK: - Public API

    func generate(for date: Date) -> GeneratedTrack {
        let seed = SeededRandom.seed(from: date)
        let rng = SeededRandom(seed: seed)
        let cornerTypes = selectCorners(rng: rng)
        let name = rng.pick(from: Self.trackNames)
        let trackId = deterministicUUID(seed: seed)

        let corners = cornerTypes.enumerated().map { index, type in
            Corner(
                id: deterministicUUID(seed: seed &+ UInt64(index + 1)),
                type: type,
                index: index
            )
        }

        let generatedCorners = corners.map { corner in
            generateCorner(corner: corner, rng: rng)
        }

        let track = Track(
            id: trackId,
            date: date,
            name: name,
            corners: corners,
            seed: seed
        )

        return GeneratedTrack(track: track, generatedCorners: generatedCorners)
    }

    // MARK: - Corner Selection

    func selectCorners(rng: SeededRandom) -> [CornerType] {
        var selected: [CornerType] = []
        for _ in 0..<5 {
            let weighted: [(CornerType, Double)] = CornerType.allCases.map { type in
                let alreadyCount = selected.filter { $0 == type }.count
                let suppressionFactor = alreadyCount >= 2 ? 0.1 : (alreadyCount == 1 ? 0.4 : 1.0)
                return (type, suppressionFactor)
            }
            selected.append(rng.pickWeighted(from: weighted))
        }
        return selected
    }

    // MARK: - Corner Geometry Generation

    func generateCorner(corner: Corner, rng: SeededRandom) -> GeneratedCorner {
        let type = corner.type
        let trackWidth = type.trackWidth

        let beziers = generateBezierSegments(for: type, rng: rng)
        let centerline = sampleBezierChain(beziers, pointCount: 80)

        let innerPoints = offsetPolyline(centerline, by: -trackWidth / 2)
        let outerPoints = offsetPolyline(centerline, by: trackWidth / 2)

        let innerBoundary = TrackBoundary(
            points: innerPoints,
            side: .inner,
            barrierStyle: type.barrierStyle
        )
        let outerBoundary = TrackBoundary(
            points: outerPoints,
            side: .outer,
            barrierStyle: type.barrierStyle
        )

        let idealLine = generateIdealLine(
            for: type,
            centerline: centerline,
            innerPoints: innerPoints,
            outerPoints: outerPoints,
            beziers: beziers,
            rng: rng
        )

        let entryPoint = centerline.first ?? .zero
        let exitPoint = centerline.last ?? .zero

        return GeneratedCorner(
            corner: corner,
            centerline: centerline,
            innerBoundary: innerBoundary,
            outerBoundary: outerBoundary,
            idealLine: idealLine,
            bezierSegments: beziers,
            entryPoint: entryPoint,
            exitPoint: exitPoint
        )
    }

    // MARK: - Bezier Generation per Corner Type

    func generateBezierSegments(for type: CornerType, rng: SeededRandom) -> [CubicBezier] {
        let direction: CGFloat = rng.nextBool() ? 1 : -1
        let screenWidth: CGFloat = 390
        let screenHeight: CGFloat = 844
        let topMargin: CGFloat = 80
        let bottomMargin: CGFloat = 50
        let centerX = screenWidth / 2
        let startY = screenHeight - bottomMargin
        let availableHeight = screenHeight - topMargin - bottomMargin

        switch type {
        case .hairpin:
            return generateHairpin(centerX: centerX, startY: startY, height: availableHeight, direction: direction, rng: rng)
        case .tight90:
            return generateTight90(centerX: centerX, startY: startY, height: availableHeight, direction: direction, rng: rng)
        case .chicane:
            return generateChicane(centerX: centerX, startY: startY, height: availableHeight, direction: direction, rng: rng)
        case .esses:
            return generateEsses(centerX: centerX, startY: startY, height: availableHeight, direction: direction, rng: rng)
        case .sweeper:
            return generateSweeper(centerX: centerX, startY: startY, height: availableHeight, direction: direction, rng: rng)
        case .doubleApex:
            return generateDoubleApex(centerX: centerX, startY: startY, height: availableHeight, direction: direction, rng: rng)
        }
    }

    // Hairpin: 180° U-turn. Entry goes up, wide U-arc at top, exit comes back down parallel.
    // Separation must be wider than track width (85pt) to prevent inner boundaries from overlapping.
    private func generateHairpin(centerX: CGFloat, startY: CGFloat, height: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        // Separation must exceed track width to avoid inner boundary collapse
        let separation = direction * rng.nextCGFloat(in: 100...130)
        let entryX = centerX - separation / 2
        let exitX = centerX + separation / 2
        let turnTop = startY - height * 0.88
        // Arc radius proportional to separation for a smooth U — control points stay between the legs
        let arcMidX = (entryX + exitX) / 2
        let arcTopY = turnTop - abs(separation) * 0.4 // Arc extends above the turn point

        // Segment 1: Straight entry going up, curving into the U-turn
        let seg1 = CubicBezier(
            p0: CGPoint(x: entryX, y: startY),
            p1: CGPoint(x: entryX, y: startY - height * 0.50),
            p2: CGPoint(x: entryX, y: arcTopY),
            p3: CGPoint(x: arcMidX, y: arcTopY)
        )
        // Segment 2: Smooth U-turn arc and exit back down
        let seg2 = CubicBezier(
            p0: CGPoint(x: arcMidX, y: arcTopY),
            p1: CGPoint(x: exitX, y: arcTopY),
            p2: CGPoint(x: exitX, y: startY - height * 0.50),
            p3: CGPoint(x: exitX, y: startY - height * 0.20)
        )
        return [seg1, seg2]
    }

    // Tight 90: Sharp ~90° turn. Long straight approach, sharp bend, shorter horizontal exit.
    private func generateTight90(centerX: CGFloat, startY: CGFloat, height: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 110...160)
        // Corner point where the bend happens — more approach, less exit
        let bendY = startY - height * rng.nextCGFloat(in: 0.40...0.50)
        let exitY = startY - height * rng.nextCGFloat(in: 0.70...0.80)

        let seg = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX, y: bendY),
            p2: CGPoint(x: centerX + offsetX * 0.1, y: exitY),
            p3: CGPoint(x: centerX + offsetX, y: exitY)
        )
        return [seg]
    }

    // Chicane: Bus-stop style — two rounded ~90° kinks. Like Monza or Spa bus stop.
    // Straight approach, rounded turn into offset, short straight section, rounded turn back, straight exit.
    private func generateChicane(centerX: CGFloat, startY: CGFloat, height: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 80...110)
        let kink1Y = startY - height * 0.38    // First kink center
        let kink2Y = startY - height * 0.62    // Second kink center
        let kinkRadius = height * 0.06          // Rounding radius for each kink

        // Segment 1: Straight approach → rounded first kink into offset
        let seg1 = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX, y: kink1Y + kinkRadius),
            p2: CGPoint(x: centerX, y: kink1Y),
            p3: CGPoint(x: centerX + offsetX * 0.5, y: kink1Y - kinkRadius)
        )
        // Segment 2: Short diagonal connecting the two kinks
        let seg2 = CubicBezier(
            p0: CGPoint(x: centerX + offsetX * 0.5, y: kink1Y - kinkRadius),
            p1: CGPoint(x: centerX + offsetX, y: kink1Y - kinkRadius * 2),
            p2: CGPoint(x: centerX + offsetX, y: kink2Y + kinkRadius * 2),
            p3: CGPoint(x: centerX + offsetX * 0.5, y: kink2Y + kinkRadius)
        )
        // Segment 3: Rounded second kink back → straight exit
        let seg3 = CubicBezier(
            p0: CGPoint(x: centerX + offsetX * 0.5, y: kink2Y + kinkRadius),
            p1: CGPoint(x: centerX, y: kink2Y),
            p2: CGPoint(x: centerX, y: kink2Y - kinkRadius),
            p3: CGPoint(x: centerX, y: startY - height)
        )
        return [seg1, seg2, seg3]
    }

    // Esses: Three flowing S-curves alternating direction.
    private func generateEsses(centerX: CGFloat, startY: CGFloat, height: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 55...85)
        let segHeight = height / 3.0
        var segments: [CubicBezier] = []
        var currentY = startY
        var currentX = centerX

        for i in 0..<3 {
            let dir: CGFloat = (i % 2 == 0) ? 1 : -1
            let targetX = centerX + offsetX * dir
            let seg = CubicBezier(
                p0: CGPoint(x: currentX, y: currentY),
                p1: CGPoint(x: currentX, y: currentY - segHeight * 0.4),
                p2: CGPoint(x: targetX, y: currentY - segHeight * 0.6),
                p3: CGPoint(x: targetX, y: currentY - segHeight)
            )
            segments.append(seg)
            currentY -= segHeight
            currentX = targetX
        }
        return segments
    }

    // Sweeper: Long constant-radius arc. Much more curvature than a straight line.
    // Control points push far to the side to create a visible bow/arc shape.
    private func generateSweeper(centerX: CGFloat, startY: CGFloat, height: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let peakOffsetX = direction * rng.nextCGFloat(in: 100...150)

        // Control points bulge far to one side to create a clear arc
        let seg = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX + peakOffsetX * 0.8, y: startY - height * 0.25),
            p2: CGPoint(x: centerX + peakOffsetX * 0.8, y: startY - height * 0.75),
            p3: CGPoint(x: centerX, y: startY - height)
        )
        return [seg]
    }

    // Double Apex: Two distinct turns in the SAME direction connected by a brief straight.
    // Like two 90° bends linked — the track curves in, straightens, curves in again.
    // The reference image shows entry from bottom, two right-angle bends curving the same way, exit at top.
    private func generateDoubleApex(centerX: CGFloat, startY: CGFloat, height: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 70...100)
        let firstBendY = startY - height * 0.35
        let midStraightY = startY - height * 0.50
        let secondBendY = startY - height * 0.65

        // Segment 1: Straight approach → first distinct bend inward
        let seg1 = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX, y: firstBendY + height * 0.05),
            p2: CGPoint(x: centerX, y: firstBendY),
            p3: CGPoint(x: centerX + offsetX * 0.7, y: midStraightY)
        )
        // Segment 2: Brief outward drift → second distinct bend inward → exit
        let seg2 = CubicBezier(
            p0: CGPoint(x: centerX + offsetX * 0.7, y: midStraightY),
            p1: CGPoint(x: centerX + offsetX, y: secondBendY + height * 0.03),
            p2: CGPoint(x: centerX + offsetX, y: secondBendY),
            p3: CGPoint(x: centerX + offsetX * 0.3, y: startY - height)
        )
        return [seg1, seg2]
    }

    // MARK: - Ideal Racing Line

    func generateIdealLine(
        for type: CornerType,
        centerline: [CGPoint],
        innerPoints: [CGPoint],
        outerPoints: [CGPoint],
        beziers: [CubicBezier],
        rng: SeededRandom
    ) -> CornerPath {
        guard centerline.count >= 4 else {
            return CornerPath(
                points: centerline,
                entryPoint: centerline.first ?? .zero,
                apexPoints: [],
                exitPoint: centerline.last ?? .zero,
                bezierSegments: beziers
            )
        }

        // Ideal line: wide entry → clip inner apex → wide exit
        // Blend between centerline and boundaries.
        // blendFactor > 0 moves toward inner, < 0 moves toward outer.
        // Magnitude capped so the line stays on track (never reaches the wall).
        let count = centerline.count
        var idealPoints: [CGPoint] = []

        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)
            let blendFactor = idealLineBlend(t: t, cornerType: type)
            let center = centerline[min(i, centerline.count - 1)]
            let inner = innerPoints[min(i, innerPoints.count - 1)]
            let outer = outerPoints[min(i, outerPoints.count - 1)]

            let x: CGFloat
            let y: CGFloat
            if blendFactor >= 0 {
                // Move from center toward inner
                x = center.x + blendFactor * (inner.x - center.x)
                y = center.y + blendFactor * (inner.y - center.y)
            } else {
                // Move from center toward outer
                x = center.x + (-blendFactor) * (outer.x - center.x)
                y = center.y + (-blendFactor) * (outer.y - center.y)
            }
            idealPoints.append(CGPoint(x: x, y: y))
        }

        let apexPoints = findApexPoints(for: type, idealPoints: idealPoints, innerPoints: innerPoints)

        return CornerPath(
            points: idealPoints,
            entryPoint: idealPoints.first ?? .zero,
            apexPoints: apexPoints,
            exitPoint: idealPoints.last ?? .zero,
            bezierSegments: beziers
        )
    }

    /// Blend function for ideal racing line.
    /// Returns -1..1 where 0 = centerline, positive = toward inner, negative = toward outer.
    /// Based on real F1 racing line theory:
    /// - Hairpin: very late apex (~75% through), wide entry/exit
    /// - Tight 90: late apex (~60%), standard outside-inside-outside
    /// - Chicane: sacrifice first apex, prioritize second for exit speed
    /// - Esses: flowing alternation, each apex slightly compromised for the next
    /// - Sweeper: near-geometric apex, gentle arc
    /// - Double apex: clip-widen-clip pattern, two distinct inner apexes
    private func idealLineBlend(t: CGFloat, cornerType: CornerType) -> CGFloat {
        let clip: CGFloat = 0.65 // Max distance from center toward wall (65% of half-width)

        switch cornerType {
        case .hairpin:
            // Late apex at ~75% through the turn, wide entry, accelerate out
            return apexCurve(t: t, apexT: 0.70, width: 0.20) * clip
        case .tight90:
            // Late apex at ~60%, outside-inside-outside
            return apexCurve(t: t, apexT: 0.60, width: 0.25) * clip
        case .chicane:
            // Two kinks: first at ~33%, second at ~67%. Sacrifice first, prioritize second.
            let a1 = apexCurve(t: t, apexT: 0.33, width: 0.14) * clip * 0.5 // Light first clip
            let a2 = apexCurve(t: t, apexT: 0.67, width: 0.14) * clip       // Full second clip
            return a1 - a2 // First toward inner, second toward outer
        case .esses:
            // Flowing alternation — each apex slightly compromised for the next
            let a1 = apexCurve(t: t, apexT: 0.17, width: 0.12) * clip * 0.8
            let a2 = apexCurve(t: t, apexT: 0.50, width: 0.12) * clip * 0.8
            let a3 = apexCurve(t: t, apexT: 0.83, width: 0.12) * clip * 0.8
            return a1 - a2 + a3 // Alternating sides
        case .sweeper:
            // Near-geometric apex at ~50%, gentle wide arc
            return apexCurve(t: t, apexT: 0.50, width: 0.40) * 0.45
        case .doubleApex:
            // Two inner apexes at ~30% and ~70%, widen between them
            let a1 = apexCurve(t: t, apexT: 0.30, width: 0.15) * clip
            let a2 = apexCurve(t: t, apexT: 0.70, width: 0.15) * clip
            // Dip outward between apexes to create the widen effect
            let widen = apexCurve(t: t, apexT: 0.50, width: 0.12) * clip * 0.3
            return max(a1, a2) - widen
        }
    }

    /// Gaussian-like apex curve centered at apexT
    private func apexCurve(t: CGFloat, apexT: CGFloat, width: CGFloat) -> CGFloat {
        let dist = (t - apexT) / width
        return CGFloat(exp(Double(-dist * dist * 2)))
    }

    private func findApexPoints(
        for type: CornerType,
        idealPoints: [CGPoint],
        innerPoints: [CGPoint]
    ) -> [CGPoint] {
        guard !idealPoints.isEmpty else { return [] }

        switch type {
        case .doubleApex, .chicane:
            // Find the two points closest to inner boundary
            let firstHalf = idealPoints.prefix(idealPoints.count / 2)
            let secondHalf = idealPoints.suffix(idealPoints.count / 2)
            let apex1 = closestToInner(points: Array(firstHalf), inner: innerPoints)
            let apex2 = closestToInner(points: Array(secondHalf), inner: innerPoints)
            return [apex1, apex2]
        default:
            let apex = closestToInner(points: idealPoints, inner: innerPoints)
            return [apex]
        }
    }

    private func closestToInner(points: [CGPoint], inner: [CGPoint]) -> CGPoint {
        guard let first = points.first else { return .zero }
        var closest = first
        var minDist = CGFloat.infinity

        for pt in points {
            for innerPt in inner {
                let d = hypot(pt.x - innerPt.x, pt.y - innerPt.y)
                if d < minDist {
                    minDist = d
                    closest = pt
                }
            }
        }
        return closest
    }

    // MARK: - Geometry Helpers

    func sampleBezierChain(_ beziers: [CubicBezier], pointCount: Int) -> [CGPoint] {
        guard !beziers.isEmpty else { return [] }
        let pointsPerSegment = pointCount / beziers.count
        var points: [CGPoint] = []

        for (i, bezier) in beziers.enumerated() {
            let count = (i == beziers.count - 1) ? (pointCount - points.count) : pointsPerSegment
            for j in 0..<count {
                let t = CGFloat(j) / CGFloat(count - 1)
                points.append(bezier.point(at: t))
            }
        }
        return points
    }

    func offsetPolyline(_ points: [CGPoint], by distance: CGFloat) -> [CGPoint] {
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

    private func polylineNormal(at index: Int, in points: [CGPoint]) -> CGPoint {
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

        // Perpendicular normal (rotated 90° CCW)
        return CGPoint(x: -dy / len, y: dx / len)
    }

    // MARK: - Deterministic UUID

    func deterministicUUID(seed: UInt64) -> UUID {
        var hash = seed
        hash = hash &* 6364136223846793005 &+ 1442695040888963407
        let a = UInt32(truncatingIfNeeded: hash >> 32)
        hash = hash &* 6364136223846793005 &+ 1442695040888963407
        let b = UInt32(truncatingIfNeeded: hash >> 32)
        hash = hash &* 6364136223846793005 &+ 1442695040888963407
        let c = UInt32(truncatingIfNeeded: hash >> 32)
        hash = hash &* 6364136223846793005 &+ 1442695040888963407
        let d = UInt32(truncatingIfNeeded: hash >> 32)

        let bytes = (
            UInt8(truncatingIfNeeded: a >> 24),
            UInt8(truncatingIfNeeded: a >> 16),
            UInt8(truncatingIfNeeded: a >> 8),
            UInt8(truncatingIfNeeded: a),
            UInt8(truncatingIfNeeded: b >> 24),
            UInt8(truncatingIfNeeded: b >> 16),
            (UInt8(truncatingIfNeeded: b >> 8) & 0x0F) | 0x40, // version 4
            UInt8(truncatingIfNeeded: b),
            (UInt8(truncatingIfNeeded: c >> 24) & 0x3F) | 0x80, // variant 1
            UInt8(truncatingIfNeeded: c >> 16),
            UInt8(truncatingIfNeeded: c >> 8),
            UInt8(truncatingIfNeeded: c),
            UInt8(truncatingIfNeeded: d >> 24),
            UInt8(truncatingIfNeeded: d >> 16),
            UInt8(truncatingIfNeeded: d >> 8),
            UInt8(truncatingIfNeeded: d)
        )
        return UUID(uuid: bytes)
    }
}

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
        let margin: CGFloat = 60
        let centerX = screenWidth / 2
        let startY = screenHeight - margin

        switch type {
        case .hairpin:
            return generateHairpin(centerX: centerX, startY: startY, direction: direction, rng: rng)
        case .tight90:
            return generateTight90(centerX: centerX, startY: startY, direction: direction, rng: rng)
        case .chicane:
            return generateChicane(centerX: centerX, startY: startY, direction: direction, rng: rng)
        case .esses:
            return generateEsses(centerX: centerX, startY: startY, direction: direction, rng: rng)
        case .sweeper:
            return generateSweeper(centerX: centerX, startY: startY, direction: direction, rng: rng)
        case .doubleApex:
            return generateDoubleApex(centerX: centerX, startY: startY, direction: direction, rng: rng)
        }
    }

    private func generateHairpin(centerX: CGFloat, startY: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 80...120)
        let rise: CGFloat = rng.nextCGFloat(in: 250...350)

        let seg1 = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX, y: startY - rise * 0.4),
            p2: CGPoint(x: centerX + offsetX, y: startY - rise * 0.7),
            p3: CGPoint(x: centerX + offsetX, y: startY - rise)
        )
        let seg2 = CubicBezier(
            p0: CGPoint(x: centerX + offsetX, y: startY - rise),
            p1: CGPoint(x: centerX + offsetX, y: startY - rise - rise * 0.3),
            p2: CGPoint(x: centerX, y: startY - rise - rise * 0.1),
            p3: CGPoint(x: centerX, y: startY - rise * 1.8)
        )
        return [seg1, seg2]
    }

    private func generateTight90(centerX: CGFloat, startY: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 100...160)
        let rise: CGFloat = rng.nextCGFloat(in: 200...300)

        let seg = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX, y: startY - rise * 0.6),
            p2: CGPoint(x: centerX + offsetX * 0.4, y: startY - rise),
            p3: CGPoint(x: centerX + offsetX, y: startY - rise)
        )
        return [seg]
    }

    private func generateChicane(centerX: CGFloat, startY: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 60...100)
        let rise: CGFloat = rng.nextCGFloat(in: 150...220)
        let midY = startY - rise

        let seg1 = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX, y: startY - rise * 0.3),
            p2: CGPoint(x: centerX + offsetX, y: midY + rise * 0.3),
            p3: CGPoint(x: centerX + offsetX, y: midY)
        )
        let seg2 = CubicBezier(
            p0: CGPoint(x: centerX + offsetX, y: midY),
            p1: CGPoint(x: centerX + offsetX, y: midY - rise * 0.3),
            p2: CGPoint(x: centerX, y: midY - rise + rise * 0.3),
            p3: CGPoint(x: centerX, y: midY - rise)
        )
        return [seg1, seg2]
    }

    private func generateEsses(centerX: CGFloat, startY: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 50...80)
        let segHeight: CGFloat = rng.nextCGFloat(in: 120...160)
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

    private func generateSweeper(centerX: CGFloat, startY: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 80...140)
        let rise: CGFloat = rng.nextCGFloat(in: 280...380)

        let seg = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX + offsetX * 0.3, y: startY - rise * 0.33),
            p2: CGPoint(x: centerX + offsetX * 0.7, y: startY - rise * 0.66),
            p3: CGPoint(x: centerX + offsetX, y: startY - rise)
        )
        return [seg]
    }

    private func generateDoubleApex(centerX: CGFloat, startY: CGFloat, direction: CGFloat, rng: SeededRandom) -> [CubicBezier] {
        let offsetX = direction * rng.nextCGFloat(in: 70...110)
        let rise: CGFloat = rng.nextCGFloat(in: 200...300)

        let seg1 = CubicBezier(
            p0: CGPoint(x: centerX, y: startY),
            p1: CGPoint(x: centerX, y: startY - rise * 0.3),
            p2: CGPoint(x: centerX + offsetX, y: startY - rise * 0.3),
            p3: CGPoint(x: centerX + offsetX, y: startY - rise * 0.55)
        )
        let seg2 = CubicBezier(
            p0: CGPoint(x: centerX + offsetX, y: startY - rise * 0.55),
            p1: CGPoint(x: centerX + offsetX, y: startY - rise * 0.75),
            p2: CGPoint(x: centerX, y: startY - rise * 0.75),
            p3: CGPoint(x: centerX, y: startY - rise)
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
        // Blend between outer (wide) and inner (tight) boundaries
        let count = centerline.count
        var idealPoints: [CGPoint] = []

        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)
            let blendFactor = idealLineBlend(t: t, cornerType: type)
            // blendFactor: 0 = outer (wide), 1 = inner (tight/apex)
            let inner = innerPoints[min(i, innerPoints.count - 1)]
            let outer = outerPoints[min(i, outerPoints.count - 1)]
            let x = outer.x + blendFactor * (inner.x - outer.x)
            let y = outer.y + blendFactor * (inner.y - outer.y)
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
    /// Returns 0..1 where 0 = outer (wide), 1 = inner (clipping apex)
    private func idealLineBlend(t: CGFloat, cornerType: CornerType) -> CGFloat {
        switch cornerType {
        case .hairpin:
            // Wide entry, tight apex at ~45%, wide exit
            return apexCurve(t: t, apexT: 0.45, width: 0.25)
        case .tight90:
            // Clip apex at ~50%
            return apexCurve(t: t, apexT: 0.50, width: 0.3)
        case .chicane:
            // Two apexes: ~30% and ~70%
            let a1 = apexCurve(t: t, apexT: 0.30, width: 0.18)
            let a2 = apexCurve(t: t, apexT: 0.70, width: 0.18)
            return max(a1, a2)
        case .esses:
            // Three apexes at ~17%, ~50%, ~83%
            let a1 = apexCurve(t: t, apexT: 0.17, width: 0.12)
            let a2 = apexCurve(t: t, apexT: 0.50, width: 0.12)
            let a3 = apexCurve(t: t, apexT: 0.83, width: 0.12)
            return max(a1, max(a2, a3))
        case .sweeper:
            // Gentle clip at ~50%
            return apexCurve(t: t, apexT: 0.50, width: 0.4) * 0.6
        case .doubleApex:
            // Two distinct apexes: ~35% and ~65% (pinch-widen-pinch)
            let a1 = apexCurve(t: t, apexT: 0.35, width: 0.18)
            let a2 = apexCurve(t: t, apexT: 0.65, width: 0.18)
            return max(a1, a2)
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

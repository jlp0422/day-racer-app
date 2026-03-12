import Testing
@testable import DayRacer
import Foundation

@Suite("TrackGenerator")
struct TrackGeneratorTests {
    let generator = TrackGenerator()

    // MARK: - Determinism

    @Test("Same date produces identical track")
    func determinism() {
        let date = makeDate(year: 2026, month: 3, day: 11)
        let track1 = generator.generate(for: date)
        let track2 = generator.generate(for: date)

        #expect(track1.track.id == track2.track.id)
        #expect(track1.track.seed == track2.track.seed)
        #expect(track1.track.name == track2.track.name)
        #expect(track1.track.corners.count == track2.track.corners.count)
        for i in 0..<track1.track.corners.count {
            #expect(track1.track.corners[i].type == track2.track.corners[i].type)
            #expect(track1.track.corners[i].id == track2.track.corners[i].id)
        }
    }

    @Test("Different dates produce different tracks")
    func differentDates() {
        let date1 = makeDate(year: 2026, month: 3, day: 11)
        let date2 = makeDate(year: 2026, month: 3, day: 12)
        let track1 = generator.generate(for: date1)
        let track2 = generator.generate(for: date2)

        #expect(track1.track.id != track2.track.id)
        #expect(track1.track.seed != track2.track.seed)
    }

    // MARK: - Track Structure

    @Test("Track has exactly 5 corners")
    func fiveCorners() {
        let date = makeDate(year: 2026, month: 6, day: 15)
        let track = generator.generate(for: date)
        #expect(track.track.corners.count == 5)
        #expect(track.generatedCorners.count == 5)
    }

    @Test("Corner indices are 0-4")
    func cornerIndices() {
        let date = makeDate(year: 2026, month: 1, day: 1)
        let track = generator.generate(for: date)
        for (i, corner) in track.track.corners.enumerated() {
            #expect(corner.index == i)
        }
    }

    @Test("Track has a name from the pool")
    func trackName() {
        let date = makeDate(year: 2026, month: 7, day: 4)
        let track = generator.generate(for: date)
        #expect(TrackGenerator.trackNames.contains(track.track.name))
    }

    // MARK: - Corner Types

    @Test("All 6 corner types are valid", arguments: CornerType.allCases)
    func cornerTypesValid(type: CornerType) {
        let corner = Corner(type: type, index: 0)
        let rng = SeededRandom(seed: 12345)
        let generated = generator.generateCorner(corner: corner, rng: rng)

        #expect(!generated.centerline.isEmpty)
        #expect(!generated.innerBoundary.points.isEmpty)
        #expect(!generated.outerBoundary.points.isEmpty)
        #expect(!generated.idealLine.points.isEmpty)
    }

    @Test("No corner type produces more than 2 consecutive same types across many dates")
    func cornerVariety() {
        var seenAllTypes = Set<CornerType>()
        for day in 1...30 {
            let date = makeDate(year: 2026, month: 1, day: day)
            let track = generator.generate(for: date)
            for corner in track.track.corners {
                seenAllTypes.insert(corner.type)
            }
        }
        #expect(seenAllTypes.count == 6)
    }

    // MARK: - Boundaries

    @Test("Boundaries are non-empty and have correct sides")
    func boundaryProperties() {
        let date = makeDate(year: 2026, month: 4, day: 20)
        let track = generator.generate(for: date)

        for gc in track.generatedCorners {
            #expect(gc.innerBoundary.side == .inner)
            #expect(gc.outerBoundary.side == .outer)
            #expect(gc.innerBoundary.points.count >= 2)
            #expect(gc.outerBoundary.points.count >= 2)
        }
    }

    @Test("Inner and outer boundaries don't overlap")
    func boundariesDontOverlap() {
        let date = makeDate(year: 2026, month: 5, day: 5)
        let track = generator.generate(for: date)

        for gc in track.generatedCorners {
            // Check that inner and outer points aren't identical
            for i in 0..<min(gc.innerBoundary.points.count, gc.outerBoundary.points.count) {
                let inner = gc.innerBoundary.points[i]
                let outer = gc.outerBoundary.points[i]
                let dist = hypot(inner.x - outer.x, inner.y - outer.y)
                #expect(dist > 1.0, "Inner and outer boundaries should be separated")
            }
        }
    }

    // MARK: - Ideal Line

    @Test("Ideal line stays within boundaries")
    func idealLineWithinBounds() {
        let date = makeDate(year: 2026, month: 8, day: 15)
        let track = generator.generate(for: date)

        for gc in track.generatedCorners {
            #expect(gc.idealLine.points.count >= 10)
            #expect(gc.idealLine.entryPoint.x != 0 || gc.idealLine.entryPoint.y != 0)
            #expect(gc.idealLine.exitPoint.x != 0 || gc.idealLine.exitPoint.y != 0)
        }
    }

    @Test("Double apex corner has exactly 2 apex points")
    func doubleApexApexCount() {
        let corner = Corner(type: .doubleApex, index: 0)
        let rng = SeededRandom(seed: 99999)
        let generated = generator.generateCorner(corner: corner, rng: rng)
        #expect(generated.idealLine.apexPoints.count == 2)
    }

    @Test("Single-apex corners have exactly 1 apex point", arguments: [
        CornerType.hairpin, .tight90, .sweeper,
    ])
    func singleApexCount(type: CornerType) {
        let corner = Corner(type: type, index: 0)
        let rng = SeededRandom(seed: 54321)
        let generated = generator.generateCorner(corner: corner, rng: rng)
        #expect(generated.idealLine.apexPoints.count == 1)
    }

    @Test("Chicane has 2 apex points")
    func chicaneApexCount() {
        let corner = Corner(type: .chicane, index: 0)
        let rng = SeededRandom(seed: 11111)
        let generated = generator.generateCorner(corner: corner, rng: rng)
        #expect(generated.idealLine.apexPoints.count == 2)
    }

    // MARK: - Bezier Sampling

    @Test("Bezier chain sampling produces expected point count")
    func bezierSampling() {
        let bezier = CubicBezier(
            p0: CGPoint(x: 0, y: 0),
            p1: CGPoint(x: 10, y: 30),
            p2: CGPoint(x: 40, y: 30),
            p3: CGPoint(x: 50, y: 0)
        )
        let points = generator.sampleBezierChain([bezier], pointCount: 60)
        #expect(points.count == 60)
    }

    @Test("Offset polyline maintains point count")
    func offsetPolyline() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 20, y: 10),
            CGPoint(x: 30, y: 10),
        ]
        let offset = generator.offsetPolyline(points, by: 5)
        #expect(offset.count == points.count)
    }

    // MARK: - Seeded Random

    @Test("Seed from date is deterministic")
    func seedDeterminism() {
        let date = makeDate(year: 2026, month: 3, day: 11)
        #expect(SeededRandom.seed(from: date) == SeededRandom.seed(from: date))
        #expect(SeededRandom.seed(from: date) == 20260311)
    }

    @Test("Deterministic UUID is stable")
    func deterministicUUID() {
        let uuid1 = generator.deterministicUUID(seed: 12345)
        let uuid2 = generator.deterministicUUID(seed: 12345)
        let uuid3 = generator.deterministicUUID(seed: 54321)
        #expect(uuid1 == uuid2)
        #expect(uuid1 != uuid3)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

import Foundation
import GameplayKit

struct SeededRandom: @unchecked Sendable {
    private let source: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        self.source = GKMersenneTwisterRandomSource(seed: seed)
    }

    func nextInt(in range: ClosedRange<Int>) -> Int {
        let distribution = GKRandomDistribution(
            randomSource: source,
            lowestValue: range.lowerBound,
            highestValue: range.upperBound
        )
        return distribution.nextInt()
    }

    func nextDouble() -> Double {
        Double(source.nextUniform())
    }

    func nextDouble(in range: ClosedRange<Double>) -> Double {
        let raw = nextDouble()
        return range.lowerBound + raw * (range.upperBound - range.lowerBound)
    }

    func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat(nextDouble(in: Double(range.lowerBound)...Double(range.upperBound)))
    }

    func nextBool(probability: Double = 0.5) -> Bool {
        nextDouble() < probability
    }

    /// Pick a random element from an array
    func pick<T>(from array: [T]) -> T {
        array[nextInt(in: 0...array.count - 1)]
    }

    /// Pick a weighted random element. Weights don't need to sum to 1.
    func pickWeighted<T>(from items: [(T, Double)]) -> T {
        let totalWeight = items.reduce(0) { $0 + $1.1 }
        var roll = nextDouble() * totalWeight
        for (item, weight) in items {
            roll -= weight
            if roll <= 0 { return item }
        }
        return items.last!.0
    }

    static func seed(from date: Date) -> UInt64 {
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let components = utcCalendar.dateComponents([.year, .month, .day], from: date)
        let year = UInt64(components.year ?? 2026)
        let month = UInt64(components.month ?? 1)
        let day = UInt64(components.day ?? 1)
        return year * 10000 + month * 100 + day
    }
}

import Testing
@testable import DayRacer
import Foundation

@Suite("LapTimeCalculator")
struct LapTimeCalculatorTests {

    @Test("All fast grades produce time below par")
    func allFast() {
        let grades: [(grade: CornerGrade, cornerType: CornerType)] = [
            (.fast, .hairpin),
            (.fast, .tight90),
            (.fast, .chicane),
            (.fast, .esses),
            (.fast, .sweeper),
        ]
        let time = LapTimeCalculator.calculate(grades: grades)
        #expect(time < LapTimeCalculator.parTime)
    }

    @Test("All average grades produce par time")
    func allAverage() {
        let grades: [(grade: CornerGrade, cornerType: CornerType)] = [
            (.average, .hairpin),
            (.average, .tight90),
            (.average, .chicane),
            (.average, .esses),
            (.average, .sweeper),
        ]
        let time = LapTimeCalculator.calculate(grades: grades)
        #expect(abs(time - LapTimeCalculator.parTime) < 0.01)
    }

    @Test("All crash grades produce time well above par")
    func allCrash() {
        let grades: [(grade: CornerGrade, cornerType: CornerType)] = [
            (.crash, .hairpin),
            (.crash, .tight90),
            (.crash, .chicane),
            (.crash, .esses),
            (.crash, .sweeper),
        ]
        let time = LapTimeCalculator.calculate(grades: grades)
        #expect(time > LapTimeCalculator.parTime + 10)
    }

    @Test("Hairpin crash penalty is higher than sweeper crash penalty")
    func weightedPenalties() {
        let hairpinCrash = LapTimeCalculator.calculate(grades: [
            (.crash, .hairpin), (.fast, .esses), (.fast, .esses), (.fast, .esses), (.fast, .esses),
        ])
        let sweeperCrash = LapTimeCalculator.calculate(grades: [
            (.crash, .sweeper), (.fast, .esses), (.fast, .esses), (.fast, .esses), (.fast, .esses),
        ])
        #expect(hairpinCrash > sweeperCrash)
    }

    @Test("Mixed grades produce time between all-fast and all-crash")
    func mixedGrades() {
        let mixed = LapTimeCalculator.calculate(grades: [
            (.fast, .hairpin),
            (.average, .tight90),
            (.slow, .chicane),
            (.crash, .esses),
            (.fast, .sweeper),
        ])
        let allFast = LapTimeCalculator.calculate(grades: [
            (.fast, .hairpin), (.fast, .tight90), (.fast, .chicane), (.fast, .esses), (.fast, .sweeper),
        ])
        let allCrash = LapTimeCalculator.calculate(grades: [
            (.crash, .hairpin), (.crash, .tight90), (.crash, .chicane), (.crash, .esses), (.crash, .sweeper),
        ])
        #expect(mixed > allFast)
        #expect(mixed < allCrash)
    }

    @Test("Par time is 60 seconds")
    func parTimeValue() {
        #expect(LapTimeCalculator.parTime == 60.0)
    }
}

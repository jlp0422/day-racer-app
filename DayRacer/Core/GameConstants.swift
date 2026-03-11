import SwiftUI

enum GameConstants {

    // MARK: - Scoring

    enum Scoring {
        /// Grade thresholds in seconds
        static let fastThreshold: Double = 14.0
        static let averageThreshold: Double = 30.0
        // slow >= 30

        /// Penalty values in seconds
        static let fastPenalty: Double = 0.0
        static let averagePenalty: Double = 0.4
        static let slowPenalty: Double = 1.5
        static let crashPenalty: Double = 3.5

        /// Corner weights used in score calculation
        enum CornerWeight {
            static let hairpin: Double = 1.8
            static let doubleApex: Double = 1.5
            static let tight90: Double = 1.3
            static let chicane: Double = 1.2
            static let esses: Double = 1.0
            static let sweeper: Double = 0.8
        }
    }

    // MARK: - Track

    enum Track {
        /// Track widths (in points) per corner type
        enum Width {
            static let hairpin: CGFloat = 85
            static let doubleApex: CGFloat = 75
            static let tight90: CGFloat = 70
            static let chicane: CGFloat = 65
            static let esses: CGFloat = 60
            static let sweeper: CGFloat = 55
        }

        /// Gravel widths (in points) per corner type
        enum GravelWidth {
            static let hairpin: CGFloat = 30
            static let doubleApex: CGFloat = 26
            static let tight90: CGFloat = 24
            static let chicane: CGFloat = 22
            static let esses: CGFloat = 20
            static let sweeper: CGFloat = 18
        }

        /// Boundary offsets
        enum BoundaryOffset {
            static let inner: CGFloat = 2
            static let outer: CGFloat = 2
        }

        /// Kerb dimensions
        enum Kerb {
            static let width: CGFloat = 6
            static let height: CGFloat = 4
        }
    }

    // MARK: - Visual

    enum Visual {
        static let grassColor = Color(hex: 0x4A7C34)
        static let gravelColor = Color(hex: 0xC8B88A)
        static let asphaltColor = Color(hex: 0x444444)
        static let dayRacerRed = Color(hex: 0xE8003D)

        /// Animation durations in seconds
        enum Animation {
            static let standard: Double = 0.3
            static let slow: Double = 0.6
        }

        /// Crash visual effects
        enum CrashEffect {
            static let scatterRadius: CGFloat = 20
            static let particleCount: Int = 8
        }
    }

    // MARK: - Input

    enum Input {
        static let minDragDistance: CGFloat = 10
        static let deadzone: CGFloat = 40
        static let dpEpsilon: CGFloat = 2.0
        static let crAlpha: CGFloat = 0.5
        static let crAlphaHairpin: CGFloat = 0.3
        static let pointSampleThreshold: CGFloat = 3.0
    }

    // MARK: - Timing

    enum Timing {
        static let autoDriveSpeed: Double = 0.8
        static let gradeCardDuration: Double = 0.8
        static let crashHoldDuration: Double = 1.0
        static let crashFlashCount: Int = 3
        static let crashFlashDuration: Double = 0.3
    }

    // MARK: - Rendering

    enum Rendering {
        static let idealLineOpacity: Double = 0.25
        static let trailWidth: CGFloat = 3.5
        static let trailOpacity: Double = 0.7
        static let proximityWarning: CGFloat = 8.0
        static let proximityDanger: CGFloat = 4.0

        /// Car body dimensions in points
        enum CarBody {
            static let width: CGFloat = 12
            static let height: CGFloat = 22
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

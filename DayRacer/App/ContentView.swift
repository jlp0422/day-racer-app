import SwiftUI

struct ContentView: View {
    @State private var generatedTrack: GeneratedTrack?
    @State private var demoCorners: [GeneratedCorner] = []
    @State private var selectedCornerIndex: Int = 0
    @State private var showingTrack = false
    @State private var showingDemo = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 64))
                .foregroundStyle(GameConstants.Visual.dayRacerRed)

            Text("DayRacer")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let track = generatedTrack {
                Text(track.track.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(track.generatedCorners.count) corners")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Corner", selection: $selectedCornerIndex) {
                    ForEach(0..<track.generatedCorners.count, id: \.self) { i in
                        Text("\(i + 1): \(track.generatedCorners[i].corner.type.rawValue)")
                            .tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Button("Preview Today's Track") {
                    showingTrack = true
                }
                .buttonStyle(.borderedProminent)
                .tint(GameConstants.Visual.dayRacerRed)
            } else {
                Text("Today's track is waiting for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Preview All 6 Corner Types") {
                showingDemo = true
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .padding()
        .onAppear {
            let generator = TrackGenerator()
            generatedTrack = generator.generate(for: .now)
            // Generate one of each corner type for verification
            let rng = SeededRandom(seed: 42)
            demoCorners = CornerType.allCases.enumerated().map { i, type in
                let corner = Corner(type: type, index: i)
                return generator.generateCorner(corner: corner, rng: rng)
            }
        }
        .fullScreenCover(isPresented: $showingTrack) {
            if let track = generatedTrack {
                TrackPreviewScreen(
                    corners: track.generatedCorners,
                    cornerIndex: $selectedCornerIndex,
                    isPresented: $showingTrack
                )
            }
        }
        .fullScreenCover(isPresented: $showingDemo) {
            TrackPreviewScreen(
                corners: demoCorners,
                cornerIndex: .constant(0),
                isPresented: $showingDemo
            )
        }
    }
}

/// Full-screen track corner preview with navigation between corners.
private struct TrackPreviewScreen: View {
    let corners: [GeneratedCorner]
    @Binding var cornerIndex: Int
    @Binding var isPresented: Bool

    @State private var localIndex: Int = 0

    private var effectiveIndex: Int {
        min(localIndex, corners.count - 1)
    }

    private var corner: GeneratedCorner {
        corners[effectiveIndex]
    }

    var body: some View {
        ZStack {
            TrackCanvasView(generatedCorner: corner)

            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("\(corner.corner.type.rawValue.capitalized)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5), in: Capsule())
                    Spacer()
                    Text("\(effectiveIndex + 1)/\(corners.count)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()

                Spacer()

                HStack(spacing: 40) {
                    Button(action: {
                        if localIndex > 0 { localIndex -= 1 }
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(localIndex > 0 ? 0.8 : 0.3))
                    }
                    .disabled(localIndex == 0)

                    Button(action: {
                        if localIndex < corners.count - 1 { localIndex += 1 }
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(
                                localIndex < corners.count - 1 ? 0.8 : 0.3
                            ))
                    }
                    .disabled(localIndex >= corners.count - 1)
                }
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden()
        .onAppear { localIndex = cornerIndex }
    }
}

#Preview {
    ContentView()
}

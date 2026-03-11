import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 64))
                .foregroundStyle(GameConstants.Visual.dayRacerRed)

            Text("DayRacer")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Today's track is waiting for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

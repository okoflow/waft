import SwiftUI

struct LevelBars: View {
    let levels: [Float]

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(levels.indices, id: \.self) { index in
                Capsule()
                    .frame(width: 3, height: 3 + 11 * CGFloat(levels[index]))
            }
        }
        .frame(height: 14)
        .motion(Motion.meter, value: levels)
    }
}

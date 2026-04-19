import SwiftUI

struct StatTileView: View {
    let metric: OverviewMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: metric.systemImage)
                    .font(.headline)

                Text(metric.title)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .foregroundStyle(metric.tint)

            Text(metric.value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        .padding()
        .background(metric.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

import SwiftUI

public struct DeviceStorageCard: View {
    public let usedBytes: Int64
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let usedRatio: Double

    public init(usedBytes: Int64, totalBytes: Int64, freeBytes: Int64, usedRatio: Double) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.usedRatio = usedRatio
    }

    private var percentage: Int {
        min(100, max(0, Int(usedRatio * 100)))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Storage")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)

                    Text("\(ByteFormatter.format(usedBytes)) / \(ByteFormatter.format(totalBytes)) Used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 4.5)

                    Circle()
                        .trim(from: 0, to: min(1.0, max(0.0, usedRatio)))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.pink,
                                    Color.orange,
                                    Color.purple
                                ]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(percentage)%")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                }
                .frame(width: 58, height: 58)
            }

            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)

                        Text("Used")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(ByteFormatter.format(usedBytes))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.0, green: 0.85, blue: 0.70))
                            .frame(width: 8, height: 8)

                        Text("Free")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(ByteFormatter.format(freeBytes))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                }

                Spacer()
            }
        }
        .padding(AppTheme.Spacing.lg)
        .appCardStyle()
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Device Storage: \(ByteFormatter.format(usedBytes)) of \(ByteFormatter.format(totalBytes)) used, \(ByteFormatter.format(freeBytes)) free, \(percentage) percent capacity used")
    }
}

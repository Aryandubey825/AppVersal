//
//  DeviceStorageCard.swift
//  AppVersal
//

import SwiftUI
import Combine

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

    public var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Header Row
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("iPhone Storage")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(ByteFormatter.format(usedBytes)) of \(ByteFormatter.format(totalBytes)) used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Percentage Badge
                Text("\(Int(usedRatio * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }

            // Sleek Gradient Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(10, geo.size.width * min(1.0, max(0.0, usedRatio))), height: 10)
                }
            }
            .frame(height: 10)

            // Storage Details Footer
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 8, height: 8)
                    Text("Used: \(ByteFormatter.format(usedBytes))")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Free: \(ByteFormatter.format(freeBytes))")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .appCardStyle()
    }
}

//
//  SystemOverview.swift
//  KnotchKnotch
//

import SwiftUI

private let overviewCardCornerRadius: CGFloat = MusicPlayerImageSizes.cornerRadiusInset.opened

struct SystemOverview: View {
    let snapshot: SystemSnapshot?
    let cpuHistory: RingBuffer<CPUUsage>

    var body: some View {
        HStack(spacing: 8) {
            CPUCard(usage: snapshot?.cpu, history: cpuHistory.elements).equatable()
            MemoryCard(usage: snapshot?.memory).equatable()
            NetworkCard(rate: snapshot?.network).equatable()
            if snapshot?.battery != nil {
                BatteryCard(info: snapshot?.battery).equatable()
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

struct CPUCard: View, Equatable {
    let usage: CPUUsage?
    let history: [CPUUsage]

    static func == (lhs: CPUCard, rhs: CPUCard) -> Bool {
        lhs.usage == rhs.usage && lhs.history == rhs.history
    }

    var body: some View {
        OverviewCard {
            VStack(alignment: .leading, spacing: 5) {
                Text("CPU")
                    .secondaryMetricText()
                Text(usage.map { "\(Int($0.total.rounded()))%" } ?? "—")
                    .metricPrimaryText()
                Sparkline(values: history.map(\.total))
                    .frame(height: 22)
                Text(usage.map { "U \(Int($0.user.rounded())) · S \(Int($0.system.rounded()))" } ?? "Unavailable")
                    .secondaryMetricText()
                    .monospacedDigit()
            }
        }
    }
}

struct MemoryCard: View, Equatable {
    let usage: MemoryUsage?

    var body: some View {
        OverviewCard {
            VStack(alignment: .leading, spacing: 5) {
                Text("Memory")
                    .secondaryMetricText()
                Text(usage.map { "\(formatGB($0.usedBytes)) / \(formatGB($0.totalBytes))" } ?? "—")
                    .metricPrimaryText()
                    .minimumScaleFactor(0.7)
                if let usage {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(pressureColor(usage.pressureLevel))
                            .frame(width: 6, height: 6)
                        Text(pressureLabel(usage.pressureLevel))
                    }
                    .secondaryMetricText()
                    Text("Swap \(formatGB(usage.swapUsedBytes))")
                        .secondaryMetricText()
                        .monospacedDigit()
                } else {
                    Text("Unavailable")
                        .secondaryMetricText()
                }
            }
        }
    }
}

struct NetworkCard: View, Equatable {
    let rate: NetworkRate?

    var body: some View {
        OverviewCard {
            VStack(alignment: .leading, spacing: 5) {
                Text("Network")
                    .secondaryMetricText()
                if let rate {
                    Text("↓ \(formatRate(rate.receivedBytesPerSecond))")
                        .metricPrimaryText()
                        .minimumScaleFactor(0.7)
                    Text("↑ \(formatRate(rate.transmittedBytesPerSecond))")
                        .metricPrimaryText()
                        .minimumScaleFactor(0.7)
                } else {
                    Text("—")
                        .metricPrimaryText()
                    Text("Unavailable")
                        .secondaryMetricText()
                }
            }
        }
    }
}

struct BatteryCard: View, Equatable {
    let info: BatteryInfo?

    var body: some View {
        OverviewCard {
            VStack(alignment: .leading, spacing: 5) {
                Text("Battery")
                    .secondaryMetricText()
                if let info {
                    HStack(spacing: 5) {
                        Text("\(Int((Double(info.currentCapacity) / Double(max(info.maxCapacity, 1)) * 100).rounded()))%")
                            .metricPrimaryText()
                        Image(systemName: info.isCharging ? "bolt.fill" : "battery.100")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(batteryTime(info))
                        .secondaryMetricText()
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("Unavailable")
                        .secondaryMetricText()
                }
            }
        }
    }
}

private struct OverviewCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(10)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: overviewCardCornerRadius, style: .continuous))
    }
}

struct Sparkline: View, Equatable {
    let values: [Double]

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }
            let step = size.width / CGFloat(values.count - 1)
            var line = Path()
            for (index, value) in values.enumerated() {
                let x = CGFloat(index) * step
                let y = size.height - (min(max(value, 0), 100) / 100) * size.height
                if index == 0 {
                    line.move(to: CGPoint(x: x, y: y))
                } else {
                    line.addLine(to: CGPoint(x: x, y: y))
                }
            }

            var fill = line
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()
            context.fill(fill, with: .linearGradient(
                Gradient(colors: [.white.opacity(0.16), .white.opacity(0)]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: size.height)
            ))
            context.stroke(line, with: .color(.white.opacity(0.8)), lineWidth: 1.2)
        }
    }
}

private extension View {
    func metricPrimaryText() -> some View {
        font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
            .lineLimit(1)
    }

    func secondaryMetricText() -> some View {
        font(.system(size: 10, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

private func formatGB(_ bytes: UInt64) -> String {
    String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
}

private func formatRate(_ bytesPerSecond: UInt64) -> String {
    let value = Double(bytesPerSecond)
    switch value {
    case 1_000_000...:
        return String(format: "%.1f MB/s", value / 1_000_000)
    case 1_000...:
        return String(format: "%.1f KB/s", value / 1_000)
    default:
        return String(format: "%.0f B/s", value)
    }
}

private func pressureLabel(_ level: Int) -> String {
    switch level {
    case 4: return "Critical"
    case 2: return "Warning"
    default: return "Normal"
    }
}

private func pressureColor(_ level: Int) -> Color {
    switch level {
    case 4: return .red
    case 2: return .yellow
    default: return .green
    }
}

private func batteryTime(_ info: BatteryInfo) -> String {
    guard info.currentCapacity < info.maxCapacity else { return "Fully charged" }
    if info.isTimeRemainingCalculating { return "Calculating…" }
    guard let minutes = info.timeRemaining else { return "Unavailable" }
    return "\(minutes / 60)h \(minutes % 60)m"
}

#Preview("Normal") {
    SystemOverview(
        snapshot: SystemSnapshot(
            cpu: CPUUsage(total: 24, user: 12, system: 8),
            memory: MemoryUsage(usedBytes: 12_400_000_000, totalBytes: 16_000_000_000, swapUsedBytes: 2_100_000_000, swapTotalBytes: 8_000_000_000, pressureLevel: 1),
            network: NetworkRate(receivedBytesPerSecond: 4_200_000, transmittedBytesPerSecond: 800_000),
            battery: BatteryInfo(currentCapacity: 82, maxCapacity: 100, isCharging: false, isPluggedIn: false, timeRemaining: 271, isTimeRemainingCalculating: false)
        ),
        cpuHistory: RingBuffer(capacity: 60)
    )
    .frame(width: openNotchSize.width, height: openNotchSize.height)
    .preferredColorScheme(.dark)
}

#Preview("Critical pressure, no battery") {
    SystemOverview(
        snapshot: SystemSnapshot(
            cpu: CPUUsage(total: 100, user: 70, system: 30),
            memory: MemoryUsage(usedBytes: 128_000_000_000, totalBytes: 128_000_000_000, swapUsedBytes: 999_900_000_000, swapTotalBytes: 1_000_000_000_000, pressureLevel: 4),
            network: NetworkRate(receivedBytesPerSecond: 999_900_000, transmittedBytesPerSecond: 999_900_000),
            battery: nil
        ),
        cpuHistory: RingBuffer(capacity: 60)
    )
    .frame(width: openNotchSize.width, height: openNotchSize.height)
    .preferredColorScheme(.dark)
}

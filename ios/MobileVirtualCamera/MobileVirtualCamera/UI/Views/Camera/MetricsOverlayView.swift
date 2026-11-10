import SwiftUI

// MARK: - Metrics Overlay View
public struct MetricsOverlayView: View {
    let metrics: LiveStreamMetrics
    let thermalState: String
    let batteryLevel: Int
    let isCharging: Bool

    public init(metrics: LiveStreamMetrics, thermalState: String = "nominal", batteryLevel: Int = 100, isCharging: Bool = false) {
        self.metrics = metrics
        self.thermalState = thermalState
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
    }

    public var body: some View {
        HStack(spacing: 8) {
            // FPS Badge
            metricBadge(icon: "speedometer", value: "\(Int(metrics.fps)) FPS", color: metrics.fps > 24 ? AppTheme.liveGreen : AppTheme.warning)

            // Bitrate Badge
            metricBadge(icon: "arrow.up.right", value: formatBitrate(metrics.bitrateKbps), color: AppTheme.primaryLight)

            // Latency Badge
            metricBadge(icon: "bolt.fill", value: "\(Int(metrics.latencyMs)) ms", color: metrics.latencyMs < 50 ? AppTheme.liveGreen : AppTheme.warning)

            // Battery Badge
            HStack(spacing: 4) {
                Image(systemName: isCharging ? "battery.100.bolt" : "battery.75")
                    .font(.system(size: 10))
                Text("\(batteryLevel)%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundColor(batteryLevel <= 20 ? AppTheme.danger : AppTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
        }
    }

    private func metricBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }

    private func formatBitrate(_ kbps: Double) -> String {
        if kbps >= 1000 {
            return String(format: "%.1f Mbps", kbps / 1000.0)
        } else {
            return "\(Int(kbps)) Kbps"
        }
    }
}


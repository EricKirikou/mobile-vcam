import Foundation
import UIKit

// MARK: - Telemetry Collector
public final class TelemetryCollector: ObservableObject {
    public static let shared = TelemetryCollector()

    @Published public var currentTelemetry: DeviceTelemetry?

    private var telemetryTimer: Timer?
    private let signalingClient = SignalingClient.shared

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        startTelemetryLoop()
    }

    public func startTelemetryLoop() {
        stopTelemetryLoop()
        collectAndBroadcast()

        DispatchQueue.main.async {
            self.telemetryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                self?.collectAndBroadcast()
            }
        }
    }

    public func stopTelemetryLoop() {
        telemetryTimer?.invalidate()
        telemetryTimer = nil
    }

    public func collectAndBroadcast() {
        let batteryLevel = Int(max(0, UIDevice.current.batteryLevel * 100))
        let isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full

        let thermalStateString: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalStateString = "nominal"
        case .fair: thermalStateString = "fair"
        case .serious: thermalStateString = "serious"
        case .critical: thermalStateString = "critical"
        @unknown default: thermalStateString = "unknown"
        }

        let networkType = NetworkMonitor.shared.connectionType
        let freeDiskSpace = getFreeDiskSpace()

        let telemetry = DeviceTelemetry(
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            thermalState: thermalStateString,
            networkType: networkType,
            freeDiskSpaceMb: freeDiskSpace
        )

        DispatchQueue.main.async {
            self.currentTelemetry = telemetry
        }

        if signalingClient.isConnected {
            signalingClient.sendTelemetry(telemetry: telemetry)
        }
    }

    private func getFreeDiskSpace() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                return freeSpace / (1024 * 1024)
            }
        } catch {
            print("Failed to get free disk space: \(error)")
        }
        return 0
    }
}


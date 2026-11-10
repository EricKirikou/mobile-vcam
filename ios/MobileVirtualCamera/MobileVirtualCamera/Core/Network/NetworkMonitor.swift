import Foundation
import Network

// MARK: - Network Monitor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.mobilevirtualcamera.networkmonitor")

    @Published public var isConnected: Bool = true
    @Published public var isExpensive: Bool = false
    @Published public var connectionType: String = "wifi"

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = "wifi"
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = "cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = "ethernet"
                } else {
                    self?.connectionType = "unknown"
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}


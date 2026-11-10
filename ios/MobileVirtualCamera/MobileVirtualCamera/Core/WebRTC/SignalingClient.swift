import Foundation
import UIKit

// MARK: - Signaling Delegate
public protocol SignalingClientDelegate: AnyObject {
    func signalingClientDidConnect(_ client: SignalingClient)
    func signalingClientDidDisconnect(_ client: SignalingClient, error: Error?)
    func signalingClient(_ client: SignalingClient, didReceiveIncomingSession payload: IncomingSessionPayload)
    func signalingClient(_ client: SignalingClient, didReceiveSdpOffer sdp: String, sessionId: String)
    func signalingClient(_ client: SignalingClient, didReceiveIceCandidate candidate: String, sdpMid: String?, sdpMLineIndex: Int32?, sessionId: String)
    func signalingClient(_ client: SignalingClient, didReceiveSessionEnded sessionId: String)
    func signalingClient(_ client: SignalingClient, didReceiveCameraRpc command: CameraRpcCommand, completion: @escaping (CameraRpcResponse) -> Void)
    func signalingClient(_ client: SignalingClient, didReceiveClipboardText text: String)
}

// MARK: - Signaling Client
public final class SignalingClient: NSObject, ObservableObject {
    public static let shared = SignalingClient()

    @Published public var isConnected: Bool = false
    @Published public var isConnecting: Bool = false
    @Published public var activeSessionId: String? = nil

    public weak var delegate: SignalingClientDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var shouldReconnect: Bool = true

    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }

    // MARK: - Connection Management
    public func connect(baseURL: String? = nil) {
        guard !isConnected && !isConnecting else { return }

        DispatchQueue.main.async {
            self.isConnecting = true
        }

        shouldReconnect = true
        let hostUrl = baseURL ?? UserPreferences.shared.serverBaseUrl
        let wsUrlString: String

        if hostUrl.hasPrefix("https://") {
            wsUrlString = hostUrl.replacingOccurrences(of: "https://", with: "wss://") + "/socket.io/?EIO=4&transport=websocket"
        } else if hostUrl.hasPrefix("http://") {
            wsUrlString = hostUrl.replacingOccurrences(of: "http://", with: "ws://") + "/socket.io/?EIO=4&transport=websocket"
        } else {
            wsUrlString = "ws://" + hostUrl + "/socket.io/?EIO=4&transport=websocket"
        }

        guard let url = URL(string: wsUrlString) else {
            print("Invalid WebSocket URL: \(wsUrlString)")
            DispatchQueue.main.async { self.isConnecting = false }
            return
        }

        var request = URLRequest(url: url)
        if let token = KeychainHelper.shared.readString(key: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue(UserPreferences.shared.deviceId, forHTTPHeaderField: "X-Device-ID")

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        listenForMessages()
        startPingTimer()
    }

    public func disconnect() {
        shouldReconnect = false
        stopPingTimer()
        reconnectTimer?.invalidate()
        reconnectTimer = nil

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil

        DispatchQueue.main.async {
            self.isConnected = false
            self.isConnecting = false
            self.activeSessionId = nil
        }
    }

    // MARK: - Message Loop
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error.localizedDescription)")
                self.handleDisconnection(error: error)
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingText(text)
                case .data(let data):
                    if let str = String(data: data, encoding: .utf8) {
                        self.handleIncomingText(str)
                    }
                @unknown default:
                    break
                }
                self.listenForMessages()
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        // Socket.IO protocol packet handling:
        // "0" = open handshake, "2" = ping, "3" = pong, "40" = connected, "42" = event
        if text.hasPrefix("0") {
            // Engine.IO handshake received, send auth connect packet
            let deviceId = UserPreferences.shared.deviceId
            let token = KeychainHelper.shared.readString(key: "auth_token") ?? ""
            let authPacket = "40{\"token\":\"\(token)\",\"deviceId\":\"\(deviceId)\"}"
            sendRaw(authPacket)
        } else if text.hasPrefix("2") {
            // Ping from server, reply with pong "3"
            sendRaw("3")
        } else if text.hasPrefix("40") {
            // Socket.IO connected
            DispatchQueue.main.async {
                self.isConnected = true
                self.isConnecting = false
                self.delegate?.signalingClientDidConnect(self)
            }
        } else if text.hasPrefix("42") {
            // Socket.IO event packet: 42["eventName", payload]
            let jsonString = String(text.dropFirst(2))
            parseSocketIoEvent(jsonString: jsonString)
        }
    }

    private func parseSocketIoEvent(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let eventName = array.first as? String else {
            return
        }

        let payloadDict = array.count > 1 ? array[1] as? [String: Any] : nil

        DispatchQueue.main.async {
            switch eventName {
            case "signaling:incoming_session":
                if let dict = payloadDict,
                   let payloadData = try? JSONSerialization.data(withJSONObject: dict),
                   let session = try? JSONDecoder().decode(IncomingSessionPayload.self, from: payloadData) {
                    self.activeSessionId = session.sessionId
                    self.delegate?.signalingClient(self, didReceiveIncomingSession: session)
                }

            case "signaling:offer":
                if let dict = payloadDict,
                   let sessionId = dict["sessionId"] as? String,
                   let sdp = dict["sdp"] as? String {
                    self.activeSessionId = sessionId
                    self.delegate?.signalingClient(self, didReceiveSdpOffer: sdp, sessionId: sessionId)
                }

            case "signaling:ice_candidate":
                if let dict = payloadDict,
                   let sessionId = dict["sessionId"] as? String,
                   let candidate = dict["candidate"] as? String {
                    let sdpMid = dict["sdpMid"] as? String
                    let sdpMLineIndex = dict["sdpMLineIndex"] as? Int32
                    self.delegate?.signalingClient(self, didReceiveIceCandidate: candidate, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex, sessionId: sessionId)
                }

            case "signaling:session_ended":
                if let dict = payloadDict, let sessionId = dict["sessionId"] as? String {
                    self.activeSessionId = nil
                    self.delegate?.signalingClient(self, didReceiveSessionEnded: sessionId)
                }

            case "camera:rpc":
                if let dict = payloadDict,
                   let commandId = dict["commandId"] as? String,
                   let action = dict["action"] as? String {
                    let cmd = CameraRpcCommand(
                        commandId: commandId,
                        action: action,
                        payload: nil,
                        timestamp: dict["timestamp"] as? Int64 ?? 0
                    )
                    self.delegate?.signalingClient(self, didReceiveCameraRpc: cmd) { response in
                        self.sendRpcResponse(response)
                    }
                }

            case "clipboard:sync":
                if let dict = payloadDict, let text = dict["text"] as? String {
                    self.delegate?.signalingClient(self, didReceiveClipboardText: text)
                }

            default:
                break
            }
        }
    }

    // MARK: - Emitting Events
    public func sendEvent(name: String, data: Any) {
        guard isConnected else { return }
        do {
            let eventArray: [Any] = [name, data]
            let jsonData = try JSONSerialization.data(withJSONObject: eventArray)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let packet = "42" + jsonString
                sendRaw(packet)
            }
        } catch {
            print("Failed to serialize event [\(name)]: \(error)")
        }
    }

    public func sendAnswer(sessionId: String, sdp: String) {
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "sdp": sdp,
            "fromDeviceId": UserPreferences.shared.deviceId
        ]
        sendEvent(name: "signaling:answer", data: payload)
    }

    public func sendIceCandidate(sessionId: String, candidate: String, sdpMid: String?, sdpMLineIndex: Int32?) {
        var payload: [String: Any] = [
            "sessionId": sessionId,
            "candidate": candidate,
            "fromDeviceId": UserPreferences.shared.deviceId
        ]
        if let sdpMid = sdpMid { payload["sdpMid"] = sdpMid }
        if let sdpMLineIndex = sdpMLineIndex { payload["sdpMLineIndex"] = sdpMLineIndex }
        sendEvent(name: "signaling:ice_candidate", data: payload)
    }

    public func sendSessionReady(sessionId: String, connectionType: String = "p2p_direct") {
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "connectionType": connectionType
        ]
        sendEvent(name: "signaling:session_ready", data: payload)
    }

    public func sendEndSession(sessionId: String) {
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "deviceId": UserPreferences.shared.deviceId
        ]
        sendEvent(name: "signaling:end_session", data: payload)
        self.activeSessionId = nil
    }

    public func sendMetricsUpdate(sessionId: String, latencyMs: Double, fps: Double, bitrateKbps: Double, packetLossPct: Double, batteryLevel: Int) {
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "latencyMs": latencyMs,
            "fps": fps,
            "bitrateKbps": bitrateKbps,
            "packetLossPct": packetLossPct,
            "batteryLevel": batteryLevel
        ]
        sendEvent(name: "metrics:update", data: payload)
    }

    public func sendTelemetry(telemetry: DeviceTelemetry) {
        let payload: [String: Any] = [
            "batteryLevel": telemetry.batteryLevel,
            "isCharging": telemetry.isCharging,
            "thermalState": telemetry.thermalState,
            "networkType": telemetry.networkType,
            "freeDiskSpaceMb": telemetry.freeDiskSpaceMb
        ]
        sendEvent(name: "device:telemetry", data: payload)
    }

    public func sendRpcResponse(_ response: CameraRpcResponse) {
        let payload: [String: Any] = [
            "commandId": response.commandId,
            "success": response.success,
            "error": response.error as Any,
            "data": response.data != nil ? (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(response.data!))) as Any : NSNull()
        ]
        sendEvent(name: "camera:rpc_response", data: payload)
    }

    private func sendRaw(_ text: String) {
        webSocketTask?.send(.string(text)) { error in
            if let error = error {
                print("WebSocket send error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Heartbeat & Reconnection
    private func startPingTimer() {
        stopPingTimer()
        DispatchQueue.main.async {
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
                self?.sendRaw("2") // Socket.IO engine ping
                self?.sendEvent(name: "heartbeat", data: ["timestamp": Date().timeIntervalSince1970])
            }
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func handleDisconnection(error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.isConnecting = false
            self.stopPingTimer()
            self.delegate?.signalingClientDidDisconnect(self, error: error)

            if self.shouldReconnect {
                self.scheduleReconnect()
            }
        }
    }

    private func scheduleReconnect() {
        guard reconnectTimer == nil else { return }
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.reconnectTimer = nil
            self?.connect()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension SignalingClient: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // Awaiting handshake packet
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        handleDisconnection(error: nil)
    }
}


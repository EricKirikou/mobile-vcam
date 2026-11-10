import SwiftUI
import AVFoundation

// MARK: - QR Scanner UIKit View
public final class QRScannerUIView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    public var onCodeDetected: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScanner()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScanner()
    }

    private func setupScanner() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            let layer = AVCaptureVideoPreviewLayer(session: captureSession)
            layer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(layer)
            self.previewLayer = layer

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("Failed to initialize QR scanner: \(error)")
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        onCodeDetected?(stringValue)
    }

    public func stopScanning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

// MARK: - SwiftUI QR Scanner View
public struct QRScannerView: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    public init(onCodeScanned: @escaping (String) -> Void) {
        self.onCodeScanned = onCodeScanned
    }

    public func makeUIView(context: Context) -> QRScannerUIView {
        let view = QRScannerUIView()
        view.onCodeDetected = onCodeScanned
        return view
    }

    public func updateUIView(_ uiView: QRScannerUIView, context: Context) {}

    public static func dismantleUIView(_ uiView: QRScannerUIView, coordinator: ()) {
        uiView.stopScanning()
    }
}


import SwiftUI
import AVFoundation

// MARK: - Camera Preview UIKit View
public final class CameraPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    public var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    public var onFocusTap: ((CGPoint) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        previewLayer.videoGravity = .resizeAspectFill
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
        onFocusTap?(devicePoint)
        showFocusRing(at: location)
    }

    private func showFocusRing(at point: CGPoint) {
        let ring = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        ring.center = point
        ring.layer.borderColor = UIColor(red: 0x6C/255.0, green: 0x63/255.0, blue: 0xFF/255.0, alpha: 1.0).cgColor
        ring.layer.borderWidth = 2.0
        ring.layer.cornerRadius = 35.0
        ring.backgroundColor = .clear
        ring.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        addSubview(ring)

        UIView.animate(withDuration: 0.25, animations: {
            ring.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.35, delay: 0.6, options: .curveEaseOut, animations: {
                ring.alpha = 0.0
            }) { _ in
                ring.removeFromSuperview()
            }
        }
    }
}

// MARK: - SwiftUI Camera Preview Representable
public struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    public init(cameraManager: CameraManager = .shared) {
        self.cameraManager = cameraManager
    }

    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = cameraManager.session
        view.onFocusTap = { point in
            cameraManager.focusAndExpose(at: point)
        }
        return view
    }

    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.previewLayer.session != cameraManager.session {
            uiView.previewLayer.session = cameraManager.session
        }
    }
}


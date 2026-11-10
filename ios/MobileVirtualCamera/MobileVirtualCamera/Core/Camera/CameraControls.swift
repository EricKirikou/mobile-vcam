import Foundation

// MARK: - Camera Controls State
public struct CameraControlsState {
    public var currentLens: CameraLensType = .wide
    public var resolution: StreamResolution = .res4K
    public var fps: StreamFps = .fps60
    public var zoomFactor: CGFloat = 1.0
    public var minZoomFactor: CGFloat = 1.0
    public var maxZoomFactor: CGFloat = 10.0
    public var isTorchOn: Bool = false
    public var hasTorch: Bool = true
    public var isMuted: Bool = false
    public var isStabilizationEnabled: Bool = true
    public var exposureBias: Float = 0.0
    public var minExposureBias: Float = -2.0
    public var maxExposureBias: Float = 2.0
    public var focusPoint: CGPoint? = nil

    public init() {}
}


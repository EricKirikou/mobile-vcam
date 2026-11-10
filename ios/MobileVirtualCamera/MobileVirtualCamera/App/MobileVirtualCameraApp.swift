import SwiftUI

// MARK: - App Main Entry Point
@main
public struct MobileVirtualCameraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    public init() {}

    public var body: some Scene {
        WindowGroup {
            AppNavigation()
                .preferredColorScheme(.dark)
        }
    }
}


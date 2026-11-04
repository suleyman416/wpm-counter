import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from showing in the Dock
        NSApp.setActivationPolicy(.accessory)

        // Initialize HUD overlay window
        _ = OverlayWindow.shared

        // Initialize Menu Bar status item
        _ = StatusBarController.shared

        // Start listening for keystrokes
        KeyMonitor.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        KeyMonitor.shared.stop()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

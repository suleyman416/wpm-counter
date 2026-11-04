import AppKit
import SwiftUI

public final class OverlayWindow: NSPanel {
    public static let shared = OverlayWindow()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 110),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Make window completely transparent and click-through
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.ignoresMouseEvents = true

        // Stay on screen across virtual desktops/Spaces and fullscreen apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isReleasedWhenClosed = false

        // Host SwiftUI OverlayView
        let hostingView = NSHostingView(rootView: OverlayView())
        self.contentView = hostingView

        // Position at bottom-right
        updatePosition()

        // Re-align on screen/dock resize or multi-monitor change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        self.orderFrontRegardless()
    }

    @objc private func screenDidChange() {
        updatePosition()
    }

    public func updatePosition() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let windowWidth: CGFloat = 220
        let windowHeight: CGFloat = 110
        let paddingX: CGFloat = 16
        let paddingY: CGFloat = 16

        let x = visibleFrame.maxX - windowWidth - paddingX
        let y = visibleFrame.minY + paddingY

        self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
}

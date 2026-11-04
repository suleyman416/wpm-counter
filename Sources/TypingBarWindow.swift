import AppKit
import SwiftUI

public final class TypingBarWindow: NSPanel {
    public static let shared = TypingBarWindow()

    private let windowWidth: CGFloat = 620
    private let windowHeight: CGFloat = 170

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: TypingBarView())
        self.contentView = hostingView

        updatePosition()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return true
    }

    @objc private func screenDidChange() {
        updatePosition()
    }

    public func updatePosition() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let x = visible.midX - (windowWidth / 2.0)
        let y = visible.minY + 36.0

        self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }

    public func show() {
        updatePosition()
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)

        // Ensure text field inside hosting view gains immediate first responder focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self, let contentView = self.contentView else { return }
            if let field = self.findTextField(in: contentView) {
                self.makeFirstResponder(field)
            }
        }
    }

    public func hide() {
        self.orderOut(nil)
        NSApp.hide(nil)
    }

    public func toggle() {
        if self.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func findTextField(in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField {
            return field
        }
        for sub in view.subviews {
            if let found = findTextField(in: sub) {
                return found
            }
        }
        return nil
    }
}

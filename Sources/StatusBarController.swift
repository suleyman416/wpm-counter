import AppKit

public final class StatusBarController: NSObject, NSMenuDelegate {
    public static let shared = StatusBarController()

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var toggleItem: NSMenuItem!
    private var themeMenu: NSMenu!
    private var timeoutMenu: NSMenu!
    private var accessibilityItem: NSMenuItem!

    private override init() {
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "speedometer", accessibilityDescription: "WPM Counter") {
                image.isTemplate = true
                button.image = image
            } else if let fallback = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "WPM Counter") {
                fallback.isTemplate = true
                button.image = fallback
            } else {
                button.title = "WPM"
            }
        }

        buildMenu()
    }

    private func buildMenu() {
        menu = NSMenu()
        menu.delegate = self

        // Title
        let titleItem = NSMenuItem(title: "WPM Speed Counter", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Active Toggle
        toggleItem = NSMenuItem(
            title: WPMEngine.shared.isEnabled ? "✓ Counter Active" : "Resume Counter",
            action: #selector(toggleEnabled),
            keyEquivalent: "t"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        // Quick Typing Bar
        let typingBarItem = NSMenuItem(
            title: "Quick Typing Bar (⌥⇧W)",
            action: #selector(toggleTypingBar),
            keyEquivalent: ""
        )
        typingBarItem.target = self
        menu.addItem(typingBarItem)

        // Test Typing Burst (Preview)
        let demoItem = NSMenuItem(
            title: "Test Typing Burst (Preview)",
            action: #selector(runDemoBurst),
            keyEquivalent: "d"
        )
        demoItem.target = self
        menu.addItem(demoItem)

        menu.addItem(NSMenuItem.separator())

        // Design Theme Submenu
        let themeSubmenuItem = NSMenuItem(title: "Design Theme", action: nil, keyEquivalent: "")
        themeMenu = NSMenu()

        for theme in DesignTheme.allCases {
            let item = NSMenuItem(
                title: theme.rawValue,
                action: #selector(selectTheme(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = theme
            themeMenu.addItem(item)
        }
        themeSubmenuItem.submenu = themeMenu
        menu.addItem(themeSubmenuItem)

        // Idle Fade Delay Submenu
        let timeoutSubmenuItem = NSMenuItem(title: "Idle Fade Delay", action: nil, keyEquivalent: "")
        timeoutMenu = NSMenu()

        for seconds in [1.5, 2.0, 3.0, 4.0] {
            let item = NSMenuItem(
                title: "\(seconds)s",
                action: #selector(selectTimeout(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = seconds
            timeoutMenu.addItem(item)
        }
        timeoutSubmenuItem.submenu = timeoutMenu
        menu.addItem(timeoutSubmenuItem)

        menu.addItem(NSMenuItem.separator())

        // Accessibility item
        accessibilityItem = NSMenuItem(
            title: "Check Accessibility...",
            action: #selector(openAccessibility),
            keyEquivalent: ""
        )
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit WPM Counter", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    public func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }

    private func updateMenuState() {
        toggleItem.title = WPMEngine.shared.isEnabled ? "✓ Counter Active" : "Resume Counter"

        // Theme checkmarks
        for item in themeMenu.items {
            if let theme = item.representedObject as? DesignTheme {
                item.state = (WPMEngine.shared.theme == theme) ? .on : .off
            }
        }

        // Timeout checkmarks
        for item in timeoutMenu.items {
            if let seconds = item.representedObject as? TimeInterval {
                item.state = (WPMEngine.shared.idleTimeout == seconds) ? .on : .off
            }
        }

        let isTrusted = KeyMonitor.isAccessibilityTrusted(prompt: false)
        if isTrusted {
            accessibilityItem.title = "✓ Accessibility: Granted"
            accessibilityItem.action = nil
        } else {
            accessibilityItem.title = "Grant Accessibility Permission..."
            accessibilityItem.action = #selector(openAccessibility)
        }
    }

    @objc private func toggleEnabled() {
        WPMEngine.shared.isEnabled.toggle()
        if !WPMEngine.shared.isEnabled {
            WPMEngine.shared.isVisible = false
            WPMEngine.shared.currentWPM = 0
            WPMEngine.shared.displayWPM = 0
        }
        updateMenuState()
    }

    @objc private func toggleTypingBar() {
        TypingBarWindow.shared.toggle()
    }

    @objc private func selectTheme(_ sender: NSMenuItem) {
        if let theme = sender.representedObject as? DesignTheme {
            WPMEngine.shared.theme = theme
            updateMenuState()
        }
    }

    @objc private func runDemoBurst() {
        OverlayWindow.shared.updatePosition()
        OverlayWindow.shared.orderFrontRegardless()
        WPMEngine.shared.triggerDemoBurst()
    }

    @objc private func selectTimeout(_ sender: NSMenuItem) {
        if let seconds = sender.representedObject as? TimeInterval {
            WPMEngine.shared.idleTimeout = seconds
            updateMenuState()
        }
    }

    @objc private func openAccessibility() {
        KeyMonitor.openAccessibilitySettings()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

import AppKit
import ApplicationServices

public final class KeyMonitor {
    public static let shared = KeyMonitor()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isMonitoring = false

    private init() {}

    public static func isAccessibilityTrusted(prompt: Bool = false) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        } else {
            return AXIsProcessTrusted()
        }
    }

    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    public func start() {
        guard !isMonitoring else { return }
        isMonitoring = true

        _ = KeyMonitor.isAccessibilityTrusted(prompt: true)

        // Global monitor for keystrokes in other applications
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor in case our own menu or app has focus
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }

    public func stop() {
        guard isMonitoring else { return }
        isMonitoring = false

        if let global = globalMonitor {
            NSEvent.removeMonitor(global)
            globalMonitor = nil
        }
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
            localMonitor = nil
        }
    }

    private func shouldIgnore(event: NSEvent) -> Bool {
        // 1. Ignore hardware/OS key repeats (e.g. holding down Backspace, Space, or any character)
        if event.isARepeat {
            return true
        }

        // 2. Ignore modifier shortcuts (Cmd+C, Cmd+V, Cmd+Tab, Ctrl+C, etc.)
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) || flags.contains(.control) {
            return true
        }

        // 3. Ignore non-typing navigation and function keys
        let code = event.keyCode
        switch code {
        case 53: // Escape
            return true
        case 123...126: // Arrow keys: Left, Right, Down, Up
            return true
        case 115, 116, 119, 121: // Home, PageUp, End, PageDown
            return true
        case 114: // Insert/Help
            return true
        case 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111: // F1 to F12
            return true
        default:
            break
        }

        return false
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Global hotkey: Option + Shift + W toggles the Quick Typing Bar
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.option) && flags.contains(.shift) && !flags.contains(.command) && !flags.contains(.control) {
            if event.keyCode == 13 || event.charactersIgnoringModifiers?.lowercased() == "w" {
                DispatchQueue.main.async {
                    TypingBarWindow.shared.toggle()
                }
                return
            }
        }

        // When Typing Bar is active and focused, don't trigger the background overlay counter
        if TypingBarWindow.shared.isKeyWindow {
            return
        }

        if shouldIgnore(event: event) {
            return
        }

        // Identify Backspace (51) and Forward Delete (117)
        let isBackspace = (event.keyCode == 51 || event.keyCode == 117)

        DispatchQueue.main.async {
            WPMEngine.shared.registerKeystroke(isBackspace: isBackspace)
        }
    }
}

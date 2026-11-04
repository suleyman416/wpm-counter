import Foundation
import SwiftUI
import Combine

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

public enum DesignTheme: String, CaseIterable {
    case braun = "Braun Industrial"
    case monochrome = "Monochrome Studio"
    case linear = "Linear Slate"

    public func color(for wpm: Int) -> Color {
        switch self {
        case .braun:
            switch wpm {
            case 0...40:   return Color(hex: "94A3B8") // Matte Industrial Slate
            case 41...75:  return Color(hex: "F8FAFC") // Pure Crisp Titanium White
            case 76...100: return Color(hex: "F59E0B") // Solid Warm Amber
            default:       return Color(hex: "FF5500") // Solid Braun Cadmium Orange
            }
        case .monochrome:
            switch wpm {
            case 0...40:   return Color(hex: "64748B") // Muted Zinc
            case 41...75:  return Color(hex: "CBD5E1") // Cool Silver
            default:       return Color(hex: "FFFFFF") // Solid Brilliant White
            }
        case .linear:
            switch wpm {
            case 0...40:   return Color(hex: "94A3B8") // Cool Slate
            case 41...70:  return Color(hex: "E2E8F0") // Solid Chalk White
            case 71...100: return Color(hex: "818CF8") // Solid Hyper Indigo
            default:       return Color(hex: "F43F5E") // Solid Crimson Rose
            }
        }
    }
}

public final class WPMEngine: ObservableObject {
    public static let shared = WPMEngine()

    @Published public var currentWPM: Int = 0
    @Published public var displayWPM: Int = 0
    @Published public var isVisible: Bool = false
    @Published public var isEnabled: Bool = true
    @Published public var theme: DesignTheme = .braun
    @Published public var bumpScale: CGFloat = 1.0
    @Published public var idleTimeout: TimeInterval = 1.8

    public var currentColor: Color {
        theme.color(for: displayWPM)
    }

    private var timestamps: [Date] = []
    // 4.0s rolling window: industry standard for capturing natural inter-word reading pauses
    private let windowDuration: TimeInterval = 4.0
    private var lastKeystrokeTime: Date = Date.distantPast
    private var sessionStartTime: Date?
    private var decayTimer: Timer?
    private var demoTimer: Timer?

    private init() {
        startDecayTimer()
    }

    private func startDecayTimer() {
        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            self?.tickDecay()
        }
    }

    public func registerKeystroke(isBackspace: Bool = false) {
        guard isEnabled else { return }

        let now = Date()

        // If the gap since last key is > 1.2s, initialize a fresh typing run
        if let last = timestamps.last, now.timeIntervalSince(last) > 1.2 {
            timestamps.removeAll()
            sessionStartTime = now
        } else if sessionStartTime == nil {
            sessionStartTime = now
        }

        lastKeystrokeTime = now

        if isBackspace {
            // Net text output: backspacing removes a typed character rather than awarding speed
            if !timestamps.isEmpty {
                timestamps.removeLast()
            }
        } else {
            timestamps.append(now)
        }

        // Purge timestamps older than the 4.0s sliding window horizon
        let cutoff = now.addingTimeInterval(-windowDuration)
        timestamps = timestamps.filter { $0 >= cutoff }

        // Require at least 2 character keystrokes to activate the HUD
        guard timestamps.count >= 2, let sessionStart = sessionStartTime else {
            return
        }

        // True active duration within the rolling window
        let activeTime = min(now.timeIntervalSince(sessionStart), windowDuration)
        let timeSpan = max(activeTime, 1.0) // Minimum 1.0s baseline for stable scaling

        // Standard WPM: (Net Keystrokes in window / 5) / (TimeSpan in minutes)
        let words = Double(timestamps.count) / 5.0
        let minutes = timeSpan / 60.0
        var rawWPM = Int(round(words / minutes))

        // Upper physiological ceiling
        rawWPM = min(rawWPM, 200)

        // Balanced Exponential Moving Average (55% historic / 45% live)
        // Dampens 1-word micro-bursts and tracks true Monkeytype continuous pace
        if currentWPM == 0 {
            currentWPM = rawWPM
            displayWPM = rawWPM
        } else {
            let smoothed = Double(currentWPM) * 0.55 + Double(rawWPM) * 0.45
            currentWPM = Int(round(smoothed))
        }

        withAnimation(.easeOut(duration: 0.12)) {
            self.displayWPM = self.currentWPM
        }

        if !isVisible {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                self.isVisible = true
            }
        }

        // Subtle micro-bump on keypress
        withAnimation(.spring(response: 0.12, dampingFraction: 0.55)) {
            self.bumpScale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) { [weak self] in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                self?.bumpScale = 1.0
            }
        }
    }

    private func tickDecay() {
        let elapsed = Date().timeIntervalSince(lastKeystrokeTime)

        if !isVisible {
            if elapsed > 1.2 && !timestamps.isEmpty {
                timestamps.removeAll()
                sessionStartTime = nil
            }
            return
        }

        if elapsed > idleTimeout {
            if displayWPM > 0 {
                let decayed = Int(Double(displayWPM) * 0.75)
                withAnimation(.easeOut(duration: 0.1)) {
                    self.displayWPM = decayed
                }
            }

            if displayWPM <= 4 || elapsed > (idleTimeout + 0.5) {
                withAnimation(.easeOut(duration: 0.35)) {
                    self.isVisible = false
                    self.displayWPM = 0
                    self.currentWPM = 0
                    self.timestamps.removeAll()
                    self.sessionStartTime = nil
                }
            }
        } else if elapsed > 0.85 {
            // Mid-sentence thinking pause: natural cadence deceleration
            let cutoff = Date().addingTimeInterval(-windowDuration)
            timestamps = timestamps.filter { $0 >= cutoff }
            let words = Double(timestamps.count) / 5.0
            let rawWPM = Int(round(words / (windowDuration / 60.0)))
            if rawWPM < currentWPM {
                currentWPM = rawWPM
                withAnimation(.easeOut(duration: 0.14)) {
                    self.displayWPM = self.currentWPM
                }
            }
        }
    }

    public func triggerDemoBurst() {
        demoTimer?.invalidate()
        var step = 0
        let targetNumbers = [24, 42, 58, 70, 80, 88, 90, 91, 89, 88]

        demoTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.lastKeystrokeTime = Date()

            if step < targetNumbers.count {
                let num = targetNumbers[step]
                withAnimation(.easeOut(duration: 0.1)) {
                    self.currentWPM = num
                    self.displayWPM = num
                    self.isVisible = true
                    self.bumpScale = 1.06
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.65)) {
                        self.bumpScale = 1.0
                    }
                }
                step += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

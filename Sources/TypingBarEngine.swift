import Foundation
import SwiftUI
import Combine
import AppKit

public final class TypingBarEngine: ObservableObject {
    public static let shared = TypingBarEngine()

    @Published public var inputText: String = ""
    @Published public var targetExcerpt: String? = nil
    @Published public var isRunning: Bool = false
    @Published public var isCompleted: Bool = false
    @Published public var currentWPM: Int = 0
    @Published public var finalWPM: Int = 0
    @Published public var accuracy: Double = 100.0
    @Published public var elapsedTime: TimeInterval = 0.0
    @Published public var wordCount: Int = 0

    private var startTime: Date?
    private var timer: Timer?
    private var keystrokeCount: Int = 0
    private var errorCount: Int = 0

    private init() {}

    public func startIfNeeded() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        startTime = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    public func onInputChanged(_ newText: String) {
        if !isRunning && !newText.isEmpty && !isCompleted {
            startIfNeeded()
        }

        keystrokeCount += 1

        if let target = targetExcerpt, !target.isEmpty {
            validateAgainstTarget(newText: newText, target: target)
        } else {
            // Freeform mode: count words by splitting whitespace or standard 5 chars/word
            let words = newText.split { $0.isWhitespace }.count
            wordCount = words
            updateLiveWPM()
        }
    }

    private func validateAgainstTarget(newText: String, target: String) {
        var errors = 0
        let targetChars = Array(target)
        let inputChars = Array(newText)

        for i in 0..<inputChars.count {
            if i < targetChars.count {
                if inputChars[i] != targetChars[i] {
                    errors += 1
                }
            } else {
                errors += 1
            }
        }

        errorCount = errors
        let totalTyped = max(inputChars.count, 1)
        let correctCount = max(0, totalTyped - errors)
        accuracy = (Double(correctCount) / Double(totalTyped)) * 100.0

        let words = newText.split { $0.isWhitespace }.count
        wordCount = words
        updateLiveWPM()

        // Auto-complete if target reached
        if newText.count >= target.count {
            finishSprint()
        }
    }

    private func tick() {
        guard let start = startTime, isRunning else { return }
        elapsedTime = Date().timeIntervalSince(start)
        updateLiveWPM()
    }

    private func updateLiveWPM() {
        guard let start = startTime else { return }
        let duration = max(Date().timeIntervalSince(start), 0.5)
        let minutes = duration / 60.0

        // Standard typing speed: (characters / 5.0) / minutes
        let chars = Double(inputText.count)
        let words = chars / 5.0
        let rawWPM = Int(round(words / minutes))
        currentWPM = max(0, min(rawWPM, 250))
    }

    public func finishSprint() {
        guard isRunning || !inputText.isEmpty else { return }
        timer?.invalidate()
        timer = nil
        isRunning = false
        isCompleted = true

        if let start = startTime {
            elapsedTime = max(Date().timeIntervalSince(start), 0.5)
        }

        let minutes = max(elapsedTime / 60.0, 0.01)
        if let target = targetExcerpt, !target.isEmpty {
            let correctChars = max(0, inputText.count - errorCount)
            let netWords = Double(correctChars) / 5.0
            finalWPM = max(0, Int(round(netWords / minutes)))
        } else {
            let words = Double(inputText.count) / 5.0
            finalWPM = max(0, Int(round(words / minutes)))
        }
        currentWPM = finalWPM
    }

    public func reset() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isCompleted = false
        startTime = nil
        inputText = ""
        targetExcerpt = nil
        currentWPM = 0
        finalWPM = 0
        accuracy = 100.0
        elapsedTime = 0.0
        wordCount = 0
        keystrokeCount = 0
        errorCount = 0
    }

    public func pasteExcerptFromClipboard() {
        guard let clip = NSPasteboard.general.string(forType: .string) else { return }
        let trimmed = clip.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            reset()
            targetExcerpt = trimmed
        }
    }
}

import SwiftUI

public struct OverlayView: View {
    @ObservedObject var engine: WPMEngine = WPMEngine.shared

    public init() {}

    public var body: some View {
        // Pure solid minimalist typography - ZERO glow, ZERO blur halos
        Text("\(engine.displayWPM)")
            .font(.system(size: 64, weight: .semibold, design: .default))
            .monospacedDigit()
            .foregroundColor(engine.currentColor)
            // Crisp, subtle black optical contrast shadow solely for legibility over white backgrounds
            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 0, y: 1.5)
            .scaleEffect(engine.isVisible ? engine.bumpScale : 0.88)
            .offset(y: engine.isVisible ? 0 : 6)
            .opacity(engine.isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: engine.isVisible)
            .animation(.spring(response: 0.12, dampingFraction: 0.55), value: engine.bumpScale)
            .animation(.easeInOut(duration: 0.16), value: engine.displayWPM)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(20)
    }
}

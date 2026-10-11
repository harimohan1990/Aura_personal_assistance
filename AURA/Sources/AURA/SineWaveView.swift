import SwiftUI

public struct SineWaveView: View {
    public let isSpeaking: Bool
    public let isListening: Bool
    public let audioLevel: Float

    public init(isSpeaking: Bool, isListening: Bool, audioLevel: Float = 0.0) {
        self.isSpeaking = isSpeaking
        self.isListening = isListening
        self.audioLevel = audioLevel
    }

    public var body: some View {
        TimelineView(.animation(paused: !isSpeaking && !isListening)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2
                let baseAmp: CGFloat = isSpeaking ? (20.0 + CGFloat(audioLevel * 14.0)) : (isListening ? (12.0 + CGFloat(audioLevel * 16.0)) : 5.0)
                let speed: Double = isSpeaking ? 3.6 : (isListening ? 2.4 : 0.8)

                struct WaveConfig {
                    let color: Color
                    let freq: CGFloat
                    let ampMultiplier: CGFloat
                    let phaseOffset: Double
                    let lineWidth: CGFloat
                }

                let waves: [WaveConfig] = isSpeaking ? [
                    WaveConfig(color: Color(red: 0.93, green: 0.28, blue: 0.60, opacity: 0.9), freq: 0.028, ampMultiplier: 1.1, phaseOffset: 0.0, lineWidth: 2.8),
                    WaveConfig(color: Color(red: 0.55, green: 0.36, blue: 0.96, opacity: 0.85), freq: 0.038, ampMultiplier: 0.85, phaseOffset: 1.6, lineWidth: 2.2),
                    WaveConfig(color: Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.95), freq: 0.020, ampMultiplier: 1.3, phaseOffset: 3.2, lineWidth: 2.8),
                    WaveConfig(color: Color(red: 1.0, green: 0.70, blue: 0.20, opacity: 0.75), freq: 0.046, ampMultiplier: 0.6, phaseOffset: 4.5, lineWidth: 1.8)
                ] : isListening ? [
                    WaveConfig(color: Color(red: 0.06, green: 0.73, blue: 0.50, opacity: 0.85), freq: 0.026, ampMultiplier: 1.1, phaseOffset: 0.0, lineWidth: 2.5),
                    WaveConfig(color: Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.75), freq: 0.034, ampMultiplier: 0.8, phaseOffset: 1.8, lineWidth: 2.0)
                ] : [
                    WaveConfig(color: Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.25), freq: 0.015, ampMultiplier: 0.5, phaseOffset: 0.0, lineWidth: 1.5),
                    WaveConfig(color: Color(red: 0.55, green: 0.36, blue: 0.96, opacity: 0.20), freq: 0.020, ampMultiplier: 0.4, phaseOffset: 1.2, lineWidth: 1.5)
                ]

                for wave in waves {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: midY))

                    let phase = time * speed + wave.phaseOffset
                    let currentAmp = baseAmp * wave.ampMultiplier

                    for x in stride(from: 0, through: width, by: 3) {
                        // Envelope curve to taper smoothly at edges
                        let progress = x / width
                        let envelope = sin(progress * .pi)
                        let y = midY + sin(x * wave.freq + phase) * currentAmp * envelope
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    context.stroke(
                        path,
                        with: .color(wave.color),
                        style: StrokeStyle(lineWidth: wave.lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .frame(height: 56)
        .allowsHitTesting(false)
    }
}

public struct EqualizerBarsView: View {
    public let isSpeaking: Bool
    public let isListening: Bool
    public let audioLevel: Float

    public init(isSpeaking: Bool, isListening: Bool, audioLevel: Float = 0.0) {
        self.isSpeaking = isSpeaking
        self.isListening = isListening
        self.audioLevel = audioLevel
    }

    public var body: some View {
        TimelineView(.animation(paused: !isSpeaking && !isListening)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<16, id: \.self) { idx in
                    let phase = Double(idx) * 0.42
                    let speed = isSpeaking ? 9.0 : 6.0
                    let val = (sin(time * speed + phase) + 1.0) / 2.0
                    let boost = isSpeaking ? CGFloat(audioLevel * 10.0) : CGFloat(audioLevel * 14.0)
                    let barH: CGFloat = (isSpeaking || isListening) ? max(5.0, CGFloat(val * 24.0) + boost) : 4.0

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: isSpeaking ? [
                                    Color(red: 0.93, green: 0.28, blue: 0.60),
                                    Color(red: 0.55, green: 0.36, blue: 0.96),
                                    Color(red: 0.0, green: 0.95, blue: 1.0)
                                ] : isListening ? [
                                    Color(red: 0.06, green: 0.73, blue: 0.50),
                                    Color(red: 0.0, green: 0.95, blue: 1.0)
                                ] : [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3.5, height: min(barH, 32))
                }
            }
            .frame(height: 32)
        }
        .allowsHitTesting(false)
    }
}

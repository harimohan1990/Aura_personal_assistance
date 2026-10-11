import SwiftUI
import AppKit
import MapKit

// MARK: - Interactive Button Style with Mobile Haptic & Hover Feedback
public struct AuraClickableButtonStyle: ButtonStyle {
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : (isHovered ? 1.02 : 1.0))
            .brightness(isHovered ? 0.08 : 0.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                self.isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

public enum MobileTab: String, CaseIterable, Identifiable {
    case assistant = "Assistant"
    case executive = "Executive"
    case apps = "500+ Apps"
    case web = "Web Hub"
    case map = "Map"
    case control = "Control"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .assistant: return "waveform.circle.fill"
        case .executive: return "briefcase.fill"
        case .apps: return "square.grid.2x2.fill"
        case .web: return "safari.fill"
        case .map: return "map.fill"
        case .control: return "slider.horizontal.3"
        }
    }
}

public enum BusinessSection: String, CaseIterable, Identifiable {
    case brief = "Briefing"
    case tasks = "P0 Tasks"
    case email = "AI Email"
    case meeting = "Agenda"
    case kpi = "KPIs"
    case apps = "Tools"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .brief: return "chart.bar.doc.horizontal.fill"
        case .tasks: return "checklist"
        case .email: return "envelope.badge.fill"
        case .meeting: return "calendar.badge.clock"
        case .kpi: return "chart.line.uptrend.xyaxis"
        case .apps: return "building.2.crop.circle.fill"
        }
    }
}

public enum BusinessPriorityFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case p0 = "P0 Critical"
    case p1 = "P1 Strategic"
    case completed = "Done"

    public var id: String { rawValue }
}

public struct ContentView: View {
    @StateObject private var backend = BackendManager.shared
    @StateObject private var speech = SpeechManager.shared
    @StateObject private var mapManager = MapManager.shared
    @StateObject private var business = BusinessManager.shared

    @State private var selectedTab: MobileTab = .assistant
    @State private var commandInput: String = ""
    @State private var appSearchQuery: String = ""
    @State private var mapSearchQuery: String = ""
    @State private var selectedAppCategory: String = "All"
    @State private var googleSearchInput: String = ""
    @State private var youtubeSearchInput: String = ""
    @State private var showHomeAddressSheet: Bool = false
    @State private var editingHomeAddress: String = ""
    @State private var showPowerSheet: Bool = false

    // MARK: - Business Executive State
    @State private var businessSection: BusinessSection = .brief
    @State private var selectedPriorityFilter: BusinessPriorityFilter = .all
    @State private var newDeliverableTitle: String = ""
    @State private var newDeliverablePriority: BusinessPriority = .p0
    @State private var emailRecipient: String = ""
    @State private var emailSubject: String = ""
    @State private var emailPoints: String = ""
    @State private var emailTone: EmailTone = .executiveDirect
    @State private var meetingTitle: String = ""
    @State private var meetingDuration: Int = 30
    @State private var meetingObjective: String = ""
    @State private var runwayCash: String = "500000"
    @State private var runwayBurn: String = "35000"
    @State private var ltvInput: String = "12000"
    @State private var cacInput: String = "3000"
    @State private var mrrInput: String = "45000"
    @State private var prevMrrInput: String = "38000"

    @State private var orbRotation: Double = 0.0
    @State private var isOrbHovered: Bool = false
    @State private var wavePulse: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            // Ambient Futuristic Mobile Background Gradient
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    Color(red: 0.01, green: 0.02, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top iOS Dynamic Island & Status Bar
                dynamicIslandHeader
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // Mobile Screen Content (Tab based)
                TabView(selection: $selectedTab) {
                    assistantMobileTab
                        .tag(MobileTab.assistant)

                    executiveMobileTab
                        .tag(MobileTab.executive)

                    appsMobileTab
                        .tag(MobileTab.apps)

                    webMobileTab
                        .tag(MobileTab.web)

                    mapMobileTab
                        .tag(MobileTab.map)

                    controlMobileTab
                        .tag(MobileTab.control)
                }
                .tabViewStyle(.automatic)

                Spacer(minLength: 0)

                // Bottom Floating iOS Tab Bar
                bottomMobileTabBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }

            // Power & Shutdown Control Center Overlay Modal
            if showPowerSheet {
                powerSheetOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
        }
        .frame(minWidth: 380, minHeight: 620)
        .onAppear {
            editingHomeAddress = mapManager.homeAddress
            // Initialize hands-free continuous speech recognition for accessibility
            speech.setupHandsFree { command in
                Task { @MainActor in
                    submitCommand(command)
                }
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                orbRotation = 360
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                wavePulse = true
            }
        }
    }

    // MARK: - 1. iOS Dynamic Island & Status Header
    private var dynamicIslandHeader: some View {
        HStack(spacing: 8) {
            // App Branding & State
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.55, green: 0.36, blue: 0.96)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)

                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.system(size: 11, weight: .bold))
                }

                Text("AURA")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            // Dynamic Island Pill: Live Status / Speaking Equalizer / Navigation
            HStack(spacing: 6) {
                if mapManager.isNavigating {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    Text(mapManager.routeETA.isEmpty ? "NAVIGATING" : mapManager.routeETA)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                } else if speech.isSpeaking {
                    EqualizerBarsView(isSpeaking: true, isListening: false, audioLevel: speech.audioLevel)
                        .frame(width: 38, height: 16)
                    Text("SPEAKING")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.93, green: 0.28, blue: 0.60))
                } else if speech.isListening {
                    EqualizerBarsView(isSpeaking: false, isListening: true, audioLevel: speech.audioLevel)
                        .frame(width: 36, height: 16)
                    Text(speech.isHandsFreeMode ? "HANDS-FREE" : "LISTENING")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .fill(backend.isConnected ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(backend.isConnected ? "LIVE" : "NATIVE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))

            Spacer()

            // Battery Badge & Speech / Hands-Free Toggles
            HStack(spacing: 6) {
                if let batt = backend.systemStatus?.battery {
                    HStack(spacing: 3) {
                        Image(systemName: batt.status == "Charging" ? "battery.100.bolt" : "battery.100")
                            .font(.system(size: 10))
                            .foregroundColor(batt.status == "Charging" ? .green : .white)
                        Text(batt.percent ?? "100%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }

                Button(action: { speech.toggleHandsFree() }) {
                    Image(systemName: speech.isHandsFreeMode ? "mic.fill" : "mic.slash.fill")
                        .foregroundColor(speech.isHandsFreeMode ? .green : .white.opacity(0.4))
                        .font(.system(size: 11))
                        .frame(width: 26, height: 26)
                        .background(speech.isHandsFreeMode ? Color.green.opacity(0.15) : Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(AuraClickableButtonStyle())
                .help(speech.isHandsFreeMode ? "Hands-Free Voice Active (Click to Pause)" : "Hands-Free Paused (Click to Activate)")

                Button(action: { speech.speechEnabled.toggle() }) {
                    Image(systemName: speech.speechEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundColor(speech.speechEnabled ? Color(red: 0.0, green: 0.95, blue: 1.0) : .white.opacity(0.4))
                        .font(.system(size: 11))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(AuraClickableButtonStyle())

                // Shutdown & Power Menu Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPowerSheet.toggle()
                    }
                }) {
                    Image(systemName: "power")
                        .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.35))
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 26, height: 26)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.22), Color.orange.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.red.opacity(0.35), lineWidth: 0.8))
                        .shadow(color: Color.red.opacity(0.2), radius: 3, x: 0, y: 0)
                }
                .buttonStyle(AuraClickableButtonStyle())
                .help("Shutdown & Power Center (Close AURA, Quit, Sleep, Restart, Shut Down Mac)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 2. Mobile Tab: Voice Assistant
    private var assistantMobileTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero Voice Core Stage
                ZStack {
                    // Expanding Acoustic Ripple Waves
                    if speech.isSpeaking || speech.isListening {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: speech.isSpeaking ? [
                                            Color(red: 0.93, green: 0.28, blue: 0.60, opacity: 0.7),
                                            Color(red: 0.55, green: 0.36, blue: 0.96, opacity: 0.5),
                                            Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.6)
                                        ] : [
                                            Color.green.opacity(0.7),
                                            Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.0
                                )
                                .frame(width: 110, height: 110)
                                .scaleEffect(wavePulse ? (1.5 + CGFloat(i) * 0.4) : 1.0)
                                .opacity(wavePulse ? 0.0 : 0.8)
                                .animation(
                                    Animation.easeOut(duration: 1.6)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 0.5),
                                    value: wavePulse
                                )
                                .allowsHitTesting(false)
                        }
                    }

                    // Radial glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    speech.isSpeaking ? Color(red: 0.93, green: 0.28, blue: 0.60, opacity: 0.45) :
                                    speech.isListening ? Color.green.opacity(0.4) :
                                    Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.25),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .allowsHitTesting(false)

                    // Gyroscope rotating rings
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color.clear, Color(red: 0.55, green: 0.36, blue: 0.96)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 136, height: 136)
                        .rotationEffect(.degrees(speech.isSpeaking ? orbRotation * 2.2 : orbRotation))
                        .allowsHitTesting(false)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.clear, Color(red: 0.93, green: 0.28, blue: 0.60), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                        .frame(width: 154, height: 154)
                        .rotationEffect(.degrees(speech.isSpeaking ? -orbRotation * 1.8 : -orbRotation * 0.7))
                        .allowsHitTesting(false)

                    // Interactive Central Plasma Orb
                    Button(action: {
                        speech.toggleListening { recognizedText in
                            Task { @MainActor in
                                submitCommand(recognizedText)
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: speech.isSpeaking ?
                                            [Color(red: 0.93, green: 0.28, blue: 0.60), Color(red: 0.55, green: 0.36, blue: 0.96)] :
                                            speech.isListening ?
                                            [Color(red: 0.06, green: 0.73, blue: 0.50), Color(red: 0.0, green: 0.95, blue: 1.0)] :
                                            [Color(red: 0.0, green: 0.85, blue: 1.0), Color(red: 0.45, green: 0.25, blue: 0.95)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .scaleEffect(speech.isSpeaking ? (wavePulse ? 1.08 : 0.98) : (isOrbHovered ? 1.05 : 1.0))
                                .shadow(
                                    color: speech.isSpeaking ?
                                        Color(red: 0.93, green: 0.28, blue: 0.60, opacity: 0.85) :
                                        Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.7),
                                    radius: speech.isSpeaking ? 30 : (isOrbHovered ? 24 : 16)
                                )

                            Image(systemName: speech.isListening ? "waveform.badge.mic" : speech.isSpeaking ? "waveform" : "sparkles")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(speech.isSpeaking ? (wavePulse ? 1.15 : 0.95) : 1.0)
                        }
                        .frame(width: 96, height: 96)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        self.isOrbHovered = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .help(speech.isSpeaking ? "Click to stop voice" : "Click orb to speak")
                }
                .frame(height: 160)
                .padding(.top, 10)

                // Sine Wave Visualizer
                SineWaveView(
                    isSpeaking: speech.isSpeaking,
                    isListening: speech.isListening,
                    audioLevel: speech.audioLevel
                )
                .padding(.horizontal, 20)

                // Subtitle / Feedback Speech Bubble
                VStack(spacing: 4) {
                    Text(speech.isListening && !speech.recognizedText.isEmpty ? "\"\(speech.recognizedText)\"" : backend.statusMessage)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(speech.isSpeaking ? Color(red: 0.0, green: 0.95, blue: 1.0) : .white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if speech.isSpeaking {
                        Text("Tap orb to interrupt voice")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    } else if speech.isListening {
                        Text(speech.isHandsFreeMode ? "♿ Hands-Free Voice Active • Speak freely without clicking" : "Listening... Speak command")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green.opacity(0.9))
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                .padding(.horizontal, 16)

                // Accessibility Hands-Free Banner for Motor Disability & Hands-Free Control
                HStack(spacing: 8) {
                    Image(systemName: speech.isHandsFreeMode ? "waveform.badge.mic" : "mic.slash")
                        .foregroundColor(speech.isHandsFreeMode ? Color(red: 0.0, green: 0.95, blue: 1.0) : .white.opacity(0.4))
                        .font(.system(size: 13))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(speech.isHandsFreeMode ? "HANDS-FREE ACCESSIBILITY VOICE" : "MANUAL VOICE MODE")
                                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(speech.isHandsFreeMode ? .green : .white.opacity(0.7))

                            Circle()
                                .fill(speech.isHandsFreeMode ? Color.green : Color.orange)
                                .frame(width: 5, height: 5)
                        }

                        Text(speech.isHandsFreeMode ? "No clicking needed. Automatically hears and responds to your voice." : "Click orb or switch toggle to activate hands-free mode.")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: { speech.toggleHandsFree() }) {
                        Text(speech.isHandsFreeMode ? "ON" : "OFF")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(speech.isHandsFreeMode ? .black : .white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(speech.isHandsFreeMode ? Color.green : Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(speech.isHandsFreeMode ? Color.green.opacity(0.08) : Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(speech.isHandsFreeMode ? Color.green.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1))
                .padding(.horizontal, 16)

                // Live Hearing Indicator (Transcribing utterance)
                if !speech.recognizedText.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "hearingdevice.ear")
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            .font(.system(size: 11))
                        Text("Hearing: \"\(speech.recognizedText)\"")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.35), lineWidth: 1))
                    .padding(.horizontal, 16)
                }

                // Live Navigation Route Banner (Appears when user says "take me home" or navigates)
                if mapManager.isNavigating {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "location.north.circle.fill")
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                    .font(.system(size: 14))
                                Text("NAVIGATING TO \(mapManager.destinationName.uppercased())")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Text(mapManager.routeDistance)
                                Text("•")
                                Text(mapManager.routeETA)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        }

                        if let step = mapManager.turnInstructions.first {
                            Text(step)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(2)
                        }

                        HStack(spacing: 8) {
                            Button(action: {
                                selectedTab = .map
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "map.fill")
                                    Text("View Map")
                                }
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.0, green: 0.95, blue: 1.0))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(AuraClickableButtonStyle())

                            Button(action: {
                                mapManager.openInAppleMaps()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.turn.up.right")
                                    Text("Apple Maps")
                                }
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(AuraClickableButtonStyle())
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.4), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .transition(.scale.combined(with: .opacity))
                }

                // Mobile iOS Command Input Bar
                HStack(spacing: 8) {
                    TextField("Ask AURA, say \"take me home\" or \"close calculator\"...", text: $commandInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .onSubmit {
                            submitCommand(commandInput)
                        }

                    // Mic Button
                    Button(action: {
                        speech.toggleListening { recognizedText in
                            Task { @MainActor in
                                submitCommand(recognizedText)
                            }
                        }
                    }) {
                        Image(systemName: speech.isListening ? "mic.fill" : "mic")
                            .foregroundColor(speech.isListening ? .red : .white.opacity(0.85))
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 30, height: 30)
                            .background(speech.isListening ? Color.red.opacity(0.25) : Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(AuraClickableButtonStyle())

                    // Send Button
                    Button(action: {
                        submitCommand(commandInput)
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                    .disabled(commandInput.trimmingCharacters(in: .whitespaces).isEmpty || backend.isExecuting)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
                .padding(.horizontal, 16)

                // Quick Voice Command Chips
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUICK ACTIONS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chipButton(title: "📊 Executive Brief", isSpecial: true) { submitCommand("executive brief") }
                            chipButton(title: "💼 Business Suite", isSpecial: true) { selectedTab = .executive }
                            chipButton(title: "✉️ Draft Email") { submitCommand("draft email to Team about Q4 roadmap") }
                            chipButton(title: "📅 Meeting Agenda") { submitCommand("meeting agenda for Sprint Review") }
                            chipButton(title: "⚡ Add P0 Task") { submitCommand("add priority task Finalize Strategy Deck") }
                            chipButton(title: "🛑 Shut Down", isDestructive: true) { submitCommand("shut down") }
                            chipButton(title: "✨ Open AURA", isSpecial: true) { submitCommand("open") }
                            chipButton(title: "⚡ Power Options", isSpecial: true) { withAnimation { showPowerSheet = true } }
                            chipButton(title: "🏠 Take Me Home", isSpecial: true) { submitCommand("take me home") }
                            chipButton(title: "🗺️ Open Map") { selectedTab = .map }
                            chipButton(title: "✨ Test Voice Animation", isSpecial: true) { testVoiceAnimation() }
                            chipButton(title: "🧮 Open Calculator") { submitCommand("open calculator") }
                            chipButton(title: "❌ Close Calculator", isDestructive: true) { submitCommand("close calculator") }
                            chipButton(title: "🚀 Open Chrome") { submitCommand("open chrome") }
                            chipButton(title: "❌ Close Chrome", isDestructive: true) { submitCommand("close chrome") }
                            chipButton(title: "💬 Open WhatsApp") { submitCommand("open whatsapp") }
                            chipButton(title: "❌ Close WhatsApp", isDestructive: true) { submitCommand("close whatsapp") }
                            chipButton(title: "⏹️ Close Active Window", isDestructive: true) { submitCommand("close this") }
                            chipButton(title: "📸 Screenshot") { Task { await backend.captureScreenshot() } }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - 2b. Executive Business Copilot Tab
    private var executiveMobileTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Header Banner: Executive Suite
                executiveHeaderCard

                // Section Selector Chips
                executiveSectionBar

                // Content based on selected business section
                switch businessSection {
                case .brief:
                    executiveBriefView
                case .tasks:
                    executiveTasksView
                case .email:
                    executiveEmailStudioView
                case .meeting:
                    executiveMeetingView
                case .kpi:
                    executiveKpiView
                case .apps:
                    executiveAppsView
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Executive Header Card
    private var executiveHeaderCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 0.95, green: 0.45, blue: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.4), radius: 6)

                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("EXECUTIVE SUITE")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("ENTERPRISE")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.2))
                            .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                            .clipShape(Capsule())
                    }

                    Text("C-Level Strategic Copilot & Operations Hub")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                // Critical Deliverables Counter Badge
                let p0Count = business.tasks.filter { !$0.isCompleted && $0.priority == .p0 }.count
                VStack(spacing: 2) {
                    Text("\(p0Count)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(p0Count > 0 ? Color(red: 0.95, green: 0.3, blue: 0.3) : .green)
                    Text("P0 DUE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Quick Status Notice Banner (if any)
            if !business.statusNotice.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    Text(business.statusNotice)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.4), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Executive Section Bar
    private var executiveSectionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(BusinessSection.allCases) { sec in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            businessSection = sec
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: sec.icon)
                                .font(.system(size: 10.5))
                            Text(sec.rawValue)
                                .font(.system(size: 10, weight: businessSection == sec ? .bold : .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            businessSection == sec ?
                                AnyShapeStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 0.95, green: 0.5, blue: 0.2)], startPoint: .leading, endPoint: .trailing)) :
                                AnyShapeStyle(Color.white.opacity(0.06))
                        )
                        .foregroundColor(businessSection == sec ? .black : .white.opacity(0.75))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(businessSection == sec ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Section 1: Executive Daily Briefing View
    private var executiveBriefView: some View {
        let brief = business.dailyBrief ?? business.generateExecutiveBrief()
        return VStack(spacing: 12) {
            // Main Brief Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(brief.dateString.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))

                        Text(brief.greeting)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: {
                        speech.speak(brief.speechBrief)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Speak Brief")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(red: 1.0, green: 0.75, blue: 0.2))
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }

                // Leadership Quote Card
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                        .font(.system(size: 12))
                    Text(brief.focusQuote)
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(10)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Metric Snapshot Row
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CRITICAL (P0)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(brief.pendingP0Count)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(brief.pendingP0Count > 0 ? Color(red: 0.95, green: 0.3, blue: 0.3) : .green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACTIVE TASKS")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(brief.pendingTotalCount)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("MACRO PULSE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Resilient")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.95))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Top Strategic Deliverables
                VStack(alignment: .leading, spacing: 6) {
                    Text("STRATEGIC FOCUS TODAY")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))

                    ForEach(brief.strategicDeliverables, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.75, blue: 0.2))
                                .frame(width: 5, height: 5)
                                .padding(.top, 4)
                            Text(item)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))

            // Action Quick Links
            HStack(spacing: 8) {
                Button(action: {
                    business.dailyBrief = business.generateExecutiveBrief()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Brief")
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(AuraClickableButtonStyle())

                Button(action: {
                    businessSection = .email
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                        Text("Compose Email")
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.95, blue: 1.0))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(AuraClickableButtonStyle())
            }
        }
    }

    // MARK: - Section 2: Executive Tasks & Deliverables View
    private var executiveTasksView: some View {
        VStack(spacing: 12) {
            // Priority Filter Row
            HStack(spacing: 6) {
                ForEach(BusinessPriorityFilter.allCases) { filter in
                    Button(action: {
                        selectedPriorityFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 9.5, weight: selectedPriorityFilter == filter ? .bold : .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(selectedPriorityFilter == filter ? Color.white.opacity(0.18) : Color.white.opacity(0.04))
                            .foregroundColor(selectedPriorityFilter == filter ? .white : .white.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }
                Spacer()

                Button(action: {
                    business.clearCompleted()
                }) {
                    Text("Clear Done")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(AuraClickableButtonStyle())
            }

            // Quick Add Deliverable Field
            HStack(spacing: 6) {
                Menu {
                    Button("P0 - Critical") { newDeliverablePriority = .p0 }
                    Button("P1 - High Strategic") { newDeliverablePriority = .p1 }
                    Button("P2 - Operational") { newDeliverablePriority = .p2 }
                    Button("P3 - Delegated") { newDeliverablePriority = .p3 }
                } label: {
                    Text(newDeliverablePriority.shortLabel)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(Color(hex: newDeliverablePriority.badgeColorHex).opacity(0.25))
                        .foregroundColor(Color(hex: newDeliverablePriority.badgeColorHex))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .menuStyle(.borderlessButton)

                TextField("Add executive deliverable or OKR target...", text: $newDeliverableTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .onSubmit {
                        if !newDeliverableTitle.isEmpty {
                            business.addTask(title: newDeliverableTitle, priority: newDeliverablePriority)
                            newDeliverableTitle = ""
                        }
                    }

                Button(action: {
                    if !newDeliverableTitle.isEmpty {
                        business.addTask(title: newDeliverableTitle, priority: newDeliverablePriority)
                        newDeliverableTitle = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                }
                .buttonStyle(AuraClickableButtonStyle())
                .disabled(newDeliverableTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))

            // Filtered Tasks List
            let filteredTasks = business.tasks.filter { task in
                switch selectedPriorityFilter {
                case .all: return true
                case .p0: return task.priority == .p0
                case .p1: return task.priority == .p1
                case .completed: return task.isCompleted
                }
            }

            if filteredTasks.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green.opacity(0.6))
                    Text("All deliverables up to date.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 6) {
                    ForEach(filteredTasks) { task in
                        HStack(spacing: 8) {
                            Button(action: {
                                business.toggleTask(id: task.id)
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(task.isCompleted ? .green : .white.opacity(0.4))
                            }
                            .buttonStyle(AuraClickableButtonStyle())

                            // Priority Pill
                            Text(task.priority.shortLabel)
                                .font(.system(size: 8.5, weight: .black, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: task.priority.badgeColorHex).opacity(0.2))
                                .foregroundColor(Color(hex: task.priority.badgeColorHex))
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(task.isCompleted ? .white.opacity(0.4) : .white)
                                    .strikethrough(task.isCompleted)
                                    .lineLimit(2)

                                HStack(spacing: 4) {
                                    Text(task.category)
                                    Text("•")
                                    Text("Due: \(task.dueDate)")
                                }
                                .font(.system(size: 8.5))
                                .foregroundColor(.white.opacity(0.4))
                            }

                            Spacer()

                            Button(action: {
                                business.deleteTask(id: task.id)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.25))
                            }
                            .buttonStyle(AuraClickableButtonStyle())
                        }
                        .padding(8)
                        .background(Color.white.opacity(task.isCompleted ? 0.02 : 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }

    // MARK: - Section 3: AI Executive Email Studio View
    private var executiveEmailStudioView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI EXECUTIVE EMAIL COMPOSER")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))

                // Tone Selector Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(EmailTone.allCases) { tone in
                            Button(action: {
                                emailTone = tone
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: tone.icon)
                                        .font(.system(size: 9))
                                    Text(tone.rawValue)
                                        .font(.system(size: 9.5, weight: emailTone == tone ? .bold : .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(emailTone == tone ? Color(red: 1.0, green: 0.75, blue: 0.2) : Color.white.opacity(0.06))
                                .foregroundColor(emailTone == tone ? .black : .white.opacity(0.75))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(AuraClickableButtonStyle())
                        }
                    }
                }

                // Input Form
                VStack(spacing: 6) {
                    HStack {
                        Text("Recipient:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 60, alignment: .leading)
                        TextField("e.g. Board of Directors / Client Team", text: $emailRecipient)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Text("Subject:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 60, alignment: .leading)
                        TextField("e.g. Strategic Alignment & Deliverables", text: $emailSubject)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Context & Bullet Points:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))

                        TextField("e.g. Approve 15% discount; require 2-year commitment; SLA 99.99%", text: $emailPoints)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Generate Button
                Button(action: {
                    _ = business.draftEmail(
                        recipient: emailRecipient,
                        subject: emailSubject,
                        contextPoints: emailPoints,
                        tone: emailTone
                    )
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Generate Executive Draft")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 0.0, green: 0.95, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(AuraClickableButtonStyle())
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))

            // Draft Result Preview Card
            if let draft = business.currentDraft {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DRAFT PREVIEW (\(draft.tone.rawValue.uppercased()))")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            Text(draft.subject)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }

                    Text(draft.body)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    draftActionRow(draft: draft)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.3), lineWidth: 1))
            }
        }
    }

    private func draftActionRow(draft: ExecutiveEmailDraft) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                business.copyDraftToClipboard()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc.fill")
                    Text("Copy Draft")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(AuraClickableButtonStyle())

            Button(action: {
                business.openDraftInMail()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "envelope.fill")
                    Text("Open in Mail")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color(red: 0.0, green: 0.95, blue: 1.0))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(AuraClickableButtonStyle())

            Button(action: {
                speech.speak(draft.body)
            }) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                    .padding(7)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(AuraClickableButtonStyle())
        }
    }

    // MARK: - Section 4: Meeting & Agenda Architect View
    private var executiveMeetingView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("EXECUTIVE MEETING & AGENDA ARCHITECT")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))

                // Meeting Title & Duration
                VStack(spacing: 6) {
                    HStack {
                        Text("Topic:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 55, alignment: .leading)
                        TextField("e.g. Q4 Strategy & Budget Review", text: $meetingTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack(spacing: 8) {
                        Text("Duration:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 6) {
                            ForEach([15, 30, 60], id: \.self) { d in
                                Button(action: {
                                    meetingDuration = d
                                }) {
                                    Text("\(d)m")
                                        .font(.system(size: 10, weight: meetingDuration == d ? .bold : .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(meetingDuration == d ? Color(red: 1.0, green: 0.75, blue: 0.2) : Color.white.opacity(0.06))
                                        .foregroundColor(meetingDuration == d ? .black : .white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(AuraClickableButtonStyle())
                            }
                        }
                    }

                    TextField("Core objective / expected decision...", text: $meetingObjective)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: {
                    _ = business.generateMeetingAgenda(
                        title: meetingTitle,
                        duration: meetingDuration,
                        goal: meetingObjective
                    )
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                        Text("Build Structured Agenda")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 1.0, green: 0.75, blue: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(AuraClickableButtonStyle())
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))

            // Agenda Preview
            if let agenda = business.currentAgenda {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AGENDA: \(agenda.title.uppercased()) (\(agenda.durationMinutes) MIN)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                            Text("Objective: \(agenda.objective)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TIMED DISCUSSION TOPICS:")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))

                        ForEach(agenda.topics, id: \.self) { t in
                            HStack(spacing: 6) {
                                Circle().fill(Color(red: 0.0, green: 0.95, blue: 1.0)).frame(width: 4, height: 4)
                                Text(t)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("DECISION GATES & DELIVERABLES:")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))

                        ForEach(agenda.expectedOutcomes, id: \.self) { o in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 9))
                                Text(o)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Button(action: {
                            business.exportAgendaToNotes()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "note.text.badge.plus")
                                Text("Export to Apple Notes")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(AuraClickableButtonStyle())
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.3), lineWidth: 1))
            }
        }
    }

    // MARK: - Section 5: Financial KPI & Valuation Engine View
    private var executiveKpiView: some View {
        VStack(spacing: 12) {
            // Runway & Burn Rate Calculator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("CASH RUNWAY & BURN RATE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cash Balance ($)")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        TextField("500000", text: $runwayCash)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Burn ($)")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        TextField("35000", text: $runwayBurn)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                let cashVal = Double(runwayCash) ?? 0
                let burnVal = Double(runwayBurn) ?? 1
                let res = business.calculateRunway(cashBalance: cashVal, monthlyBurn: burnVal)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "%.1f MONTHS", res.months))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: res.colorHex))
                        Text(res.status)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color(hex: res.colorHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // LTV to CAC Unit Economics Calculator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.right.circle.fill").foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    Text("LTV : CAC UNIT ECONOMICS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Customer LTV ($)")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        TextField("12000", text: $ltvInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Customer CAC ($)")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        TextField("3000", text: $cacInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                let ltvVal = Double(ltvInput) ?? 0
                let cacVal = Double(cacInput) ?? 1
                let ltvRes = business.calculateLtvCac(ltv: ltvVal, cac: cacVal)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "%.2fx RATIO", ltvRes.ratio))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: ltvRes.colorHex))
                        Text(ltvRes.status)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color(hex: ltvRes.colorHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // MRR & ARR Growth Engine
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.green)
                    Text("MRR & ARR VELOCITY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current MRR ($)")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        TextField("45000", text: $mrrInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prior Mo. MRR ($)")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        TextField("38000", text: $prevMrrInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                let currentMrrVal = Double(mrrInput) ?? 0
                let prevMrrVal = Double(prevMrrInput) ?? 1
                let mrrRes = business.calculateMrrGrowth(currentMrr: currentMrrVal, prevMrr: prevMrrVal)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "+%.1f%% MoM", mrrRes.growthRate))
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(.green)
                        Text("Growth Velocity")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "$%.0f ARR", mrrRes.arr))
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        Text("Annualized Run Rate")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Section 6: Enterprise Application Launch Grid View
    private var executiveAppsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ENTERPRISE TOOLS & APPS")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(business.enterpriseApps) { app in
                    Button(action: {
                        Task {
                            await backend.openApp(app.name)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: app.icon)
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                                .frame(width: 26, height: 26)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(app.category)
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }
            }
        }
    }

    // MARK: - 3. Mobile Tab: Interactive Map & Home Navigation
    private var mapMobileTab: some View {
        VStack(spacing: 8) {
            // Map Search & Quick Action Controls
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 12))

                    TextField("Search destination (e.g. Home, San Francisco)...", text: $mapSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .onSubmit {
                            if !mapSearchQuery.isEmpty {
                                Task {
                                    let res = await mapManager.navigateTo(destination: mapSearchQuery)
                                    if let speechText = res.speech {
                                        speech.speak(speechText)
                                    }
                                }
                            }
                        }

                    if !mapSearchQuery.isEmpty {
                        Button(action: {
                            Task {
                                let res = await mapManager.navigateTo(destination: mapSearchQuery)
                                if let speechText = res.speech {
                                    speech.speak(speechText)
                                }
                            }
                        }) {
                            Text("Go")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.0, green: 0.95, blue: 1.0))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(AuraClickableButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // Quick Navigation Shortcut Buttons
                HStack(spacing: 6) {
                    Button(action: {
                        Task {
                            let res = await mapManager.navigateHome()
                            if let speechText = res.speech {
                                speech.speak(speechText)
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 10))
                            Text("Take Me Home")
                                .font(.system(size: 10.5, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.55, green: 0.36, blue: 0.96)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(AuraClickableButtonStyle())

                    Button(action: {
                        showHomeAddressSheet.toggle()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "pencil")
                                .font(.system(size: 9))
                            Text("Set Home")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(AuraClickableButtonStyle())

                    Spacer()

                    Button(action: {
                        mapManager.requestLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                    .help("Center on My Location")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)

            // Home Address Inline Editor (Sheet/Popover)
            if showHomeAddressSheet {
                HStack(spacing: 8) {
                    Image(systemName: "house")
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    TextField("Enter Home Address or City...", text: $editingHomeAddress)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Button("Save") {
                        mapManager.setHomeAddress(editingHomeAddress)
                        showHomeAddressSheet = false
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.0, green: 0.95, blue: 1.0))
                    .clipShape(Capsule())
                }
                .padding(8)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 14)
            }

            // Interactive MapKit Canvas View
            ZStack(alignment: .bottom) {
                InteractiveMapView()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.4), radius: 10)

                // Route Guidance Floating Overlay Card
                if mapManager.isNavigating {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Destination: \(mapManager.destinationName)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                HStack(spacing: 6) {
                                    Text(mapManager.routeDistance)
                                    Text("•")
                                    Text(mapManager.routeETA)
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            }
                            Spacer()

                            Button(action: {
                                mapManager.openInAppleMaps()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.turn.up.right")
                                        .font(.system(size: 8))
                                    Text("Turn-by-Turn")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(AuraClickableButtonStyle())
                        }

                        if let step = mapManager.turnInstructions.first {
                            Text(step)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .padding(10)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
    }

    // MARK: - 4. Mobile Tab: 500+ Apps Library
    private var appsMobileTab: some View {
        VStack(spacing: 10) {
            // Mobile iOS Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 13))

                TextField("Search 500+ applications (e.g. Chrome, Calc, Figma)...", text: $appSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.white)

                if !appSearchQuery.isEmpty {
                    Button(action: { appSearchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)

            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    let categories = ["All", "Installed", "Utilities", "Developer", "Browsers", "Productivity", "Communication", "Media", "Design", "AI Tools"]
                    ForEach(categories, id: \.self) { cat in
                        Button(action: { selectedAppCategory = cat }) {
                            Text(cat)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(selectedAppCategory == cat ? .black : .white.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    selectedAppCategory == cat ?
                                        LinearGradient(colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.55, green: 0.36, blue: 0.96)], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                        }
                        .buttonStyle(AuraClickableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }

            // Filtered App List
            let filteredApps = backend.apps.filter { app in
                let matchesCategory = (selectedAppCategory == "All") ||
                    (selectedAppCategory == "Installed" && app.isInstalled) ||
                    (app.category.localizedCaseInsensitiveContains(selectedAppCategory))
                let matchesQuery = appSearchQuery.isEmpty ||
                    app.name.localizedCaseInsensitiveContains(appSearchQuery) ||
                    app.key.localizedCaseInsensitiveContains(appSearchQuery)
                return matchesCategory && matchesQuery
            }

            HStack {
                Text("\(filteredApps.count) Applications Available")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                Spacer()
                Text("Tap Open or Close")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)

            // Scrollable App Tiles
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 8) {
                    ForEach(filteredApps.prefix(300)) { app in
                        HStack(spacing: 10) {
                            // iOS Squircle App Icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 38, height: 38)
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))

                                Image(systemName: app.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            }

                            // App Info
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(app.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    if app.isInstalled {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.green)
                                    }
                                }

                                Text(app.category)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.purple.opacity(0.85))
                            }

                            Spacer()

                            // Dual Action Buttons (Open & Close)
                            HStack(spacing: 6) {
                                Button(action: {
                                    Task { await backend.openApp(app.key) }
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 7))
                                        Text("Open")
                                            .font(.system(size: 9.5, weight: .bold))
                                    }
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.14))
                                    .clipShape(Capsule())
                                    .contentShape(Capsule())
                                }
                                .buttonStyle(AuraClickableButtonStyle())

                                Button(action: {
                                    Task { await backend.closeApp(app.key) }
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 7))
                                        Text("Close")
                                            .font(.system(size: 9.5, weight: .bold))
                                    }
                                    .foregroundColor(Color(red: 0.98, green: 0.55, blue: 0.55))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.14))
                                    .clipShape(Capsule())
                                    .contentShape(Capsule())
                                }
                                .buttonStyle(AuraClickableButtonStyle())
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - 5. Mobile Tab: Web Hub
    private var webMobileTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("FAVORITE SITES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                    ForEach(backend.websites) { site in
                        Button(action: {
                            Task { await backend.openWebsite(site.key) }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: site.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.purple)
                                Text(site.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(AuraClickableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)

                // Quick Search Engines
                VStack(spacing: 10) {
                    Text("QUICK SEARCH")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 12))
                        TextField("Search Google immediately...", text: $googleSearchInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .onSubmit {
                                if !googleSearchInput.isEmpty {
                                    submitCommand("google \(googleSearchInput)")
                                    googleSearchInput = ""
                                }
                            }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    HStack(spacing: 8) {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.red.opacity(0.8))
                            .font(.system(size: 12))
                        TextField("Search & play YouTube...", text: $youtubeSearchInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .onSubmit {
                                if !youtubeSearchInput.isEmpty {
                                    submitCommand("play \(youtubeSearchInput) on youtube")
                                    youtubeSearchInput = ""
                                }
                            }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(16)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                .padding(.horizontal, 16)
            }
            .padding(.top, 6)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 6. Mobile Tab: Control Center & Telemetry
    private var controlMobileTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("MACOS TELEMETRY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.horizontal, 16)

                HStack(spacing: 10) {
                    // Battery Card
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Power & Battery")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text(backend.systemStatus?.battery?.percent ?? "100%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(backend.systemStatus?.battery?.status ?? "Normal")
                            .font(.system(size: 9))
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Host Card
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Host Machine")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text(backend.systemStatus?.platform ?? "Darwin")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(backend.systemStatus?.platform_release ?? "macOS")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 16)

                // Quick Tool Buttons
                HStack(spacing: 8) {
                    Button(action: { Task { await backend.captureScreenshot() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                            Text("Screenshot")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(AuraClickableButtonStyle())

                    Button(action: { submitCommand("what time is it") }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                            Text("Time")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }
                .padding(.horizontal, 16)

                // Accessibility & Internet Calling Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("ACCESSIBILITY & INTERNET CALLING")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))

                    // Hands-Free Toggle Card
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hands-Free Voice Mode")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Continuously listens so people with disabilities don't have to click.")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { speech.isHandsFreeMode },
                            set: { speech.toggleHandsFree(enabled: $0) }
                        ))
                        .toggleStyle(.switch)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Wake Word Requirement Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wake Word Requirement")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text(speech.wakeWordRequired ? "Requires \"Hey Aura\" prefix" : "Direct Speech (Responds to any spoken command)")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { speech.wakeWordRequired },
                            set: { speech.setWakeWordRequired($0) }
                        ))
                        .toggleStyle(.switch)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Internet Calling Quick Actions
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                _ = await backend.executeInternetCall(recipient: "", isVideo: false)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                Text("FaceTime Audio")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(AuraClickableButtonStyle())

                        Button(action: {
                            Task {
                                _ = await backend.executeInternetCall(recipient: "", isVideo: true)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                Text("FaceTime Video")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(AuraClickableButtonStyle())

                        Button(action: {
                            Task {
                                _ = await backend.executeInternetCall(recipient: "", isVideo: false, isWhatsApp: true)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "message.fill")
                                Text("WhatsApp")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(AuraClickableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)

                // Power & Shutdown Control Center Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("POWER & SHUTDOWN CONTROLS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                        Spacer()
                        Text("VOICE: \"SHUT DOWN\" / \"OPEN\"")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    }

                    // Primary Standby Button
                    Button(action: { submitCommand("shut down") }) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.16))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "door.left.hand.closed")
                                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                    .font(.system(size: 13, weight: .bold))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Close AURA (Voice Wake Standby)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Window hides, mic stays active — say \"open\" to wake back up.")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            Spacer()
                            Text("SHUT DOWN")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.18))
                                .clipShape(Capsule())
                        }
                        .padding(10)
                        .background(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.25), lineWidth: 1))
                    }
                    .buttonStyle(AuraClickableButtonStyle())

                    // Quick System Power Actions Grid
                    HStack(spacing: 8) {
                        Button(action: { submitCommand("sleep mac") }) {
                            HStack(spacing: 4) {
                                Image(systemName: "moon.stars.fill")
                                Text("Sleep Mac")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(AuraClickableButtonStyle())

                        Button(action: { submitCommand("restart mac") }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Restart Mac")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(AuraClickableButtonStyle())

                        Button(action: { submitCommand("shut down mac") }) {
                            HStack(spacing: 4) {
                                Image(systemName: "power")
                                Text("Shutdown Mac")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(AuraClickableButtonStyle())
                    }

                    // Quit Entire Application
                    Button(action: { auraQuitApp() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.octagon.fill")
                            Text("Quit AURA App Completely")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }
                .padding(.horizontal, 16)

                // Activity Feed
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("COMMAND HISTORY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                        Spacer()
                        if !backend.history.isEmpty {
                            Button(action: { backend.history.removeAll() }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .buttonStyle(AuraClickableButtonStyle())
                        }
                    }

                    if backend.history.isEmpty {
                        Text("No commands executed yet.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(backend.history.prefix(15)) { item in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Image(systemName: item.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .foregroundColor(item.success ? .green : .red)
                                            .font(.system(size: 10))
                                        Text(item.command)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(item.timestamp)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    Text(item.message)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                .padding(.horizontal, 16)
            }
            .padding(.top, 6)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 7. Bottom Floating iOS Tab Bar
    private var bottomMobileTabBar: some View {
        HStack {
            ForEach(MobileTab.allCases) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? Color(red: 0.0, green: 0.95, blue: 1.0) : .white.opacity(0.45))

                        Text(tab.rawValue)
                            .font(.system(size: 8.5, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        selectedTab == tab ?
                            Color.white.opacity(0.08) :
                            Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(AuraClickableButtonStyle())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 10, y: 4)
    }

    // MARK: - Helper Views & Actions
    private func chipButton(title: String, isSpecial: Bool = false, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        let textColor: Color
        let bgColor: Color
        let strokeColor: Color

        if isDestructive {
            textColor = Color(red: 0.98, green: 0.65, blue: 0.65)
            bgColor = Color.red.opacity(0.14)
            strokeColor = Color.red.opacity(0.3)
        } else if isSpecial {
            textColor = Color(red: 0.93, green: 0.45, blue: 0.75)
            bgColor = Color.purple.opacity(0.18)
            strokeColor = Color.purple.opacity(0.4)
        } else {
            textColor = Color.white.opacity(0.85)
            bgColor = Color.white.opacity(0.07)
            strokeColor = Color.white.opacity(0.12)
        }

        return Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(textColor)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(bgColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(AuraClickableButtonStyle())
    }

    private func submitCommand(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        commandInput = ""

        Task {
            let res = await backend.executeCommand(trimmed)
            if let speechText = res.speech {
                speech.speak(speechText)
            }
        }
    }

    private func testVoiceAnimation() {
        let lines = [
            "Greetings! AURA native mobile voice core is active and responding with dynamic harmonics.",
            "Opening your applications, navigating you home, and monitoring macOS telemetry.",
            "All subsystems are online and ready for your command."
        ]
        let picked = lines.randomElement()!
        backend.statusMessage = picked
        speech.speak(picked)
    }

    // MARK: - 8. Power & Shutdown Center Modal Overlay
    private var powerSheetOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPowerSheet = false
                    }
                }

            VStack(spacing: 16) {
                // Header
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.red.opacity(0.85), Color.red.opacity(0.2)],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "power")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("POWER & SHUTDOWN")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Control AURA or macOS System Power")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showPowerSheet = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 20))
                    }
                    .buttonStyle(AuraClickableButtonStyle())
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Actions List
                VStack(spacing: 10) {
                    // Option 1: Close AURA (Standby)
                    powerActionRow(
                        icon: "door.left.hand.closed",
                        iconColor: Color(red: 0.0, green: 0.95, blue: 1.0),
                        badgeText: "VOICE WAKE ACTIVE",
                        badgeColor: Color(red: 0.0, green: 0.95, blue: 1.0),
                        title: "Close AURA (Standby)",
                        subtitle: "Hides AURA window. Background listening stays active — just say \"open\" to wake."
                    ) {
                        withAnimation { showPowerSheet = false }
                        submitCommand("shut down")
                    }

                    // Option 2: Quit Application Completely
                    powerActionRow(
                        icon: "xmark.octagon.fill",
                        iconColor: Color.red,
                        badgeText: "TERMINATE",
                        badgeColor: Color.red,
                        title: "Quit AURA Completely",
                        subtitle: "Exits the app completely and stops all microphone/voice listeners."
                    ) {
                        withAnimation { showPowerSheet = false }
                        auraQuitApp()
                    }

                    // Option 3: Sleep Mac
                    powerActionRow(
                        icon: "moon.stars.fill",
                        iconColor: Color.purple,
                        badgeText: "MACOS",
                        badgeColor: Color.purple,
                        title: "Sleep Mac",
                        subtitle: "Puts the display and macOS computer into instant sleep."
                    ) {
                        withAnimation { showPowerSheet = false }
                        submitCommand("sleep mac")
                    }

                    // Option 4: Restart Mac
                    powerActionRow(
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        iconColor: Color.orange,
                        badgeText: "REBOOT",
                        badgeColor: Color.orange,
                        title: "Restart Mac",
                        subtitle: "Safely reboots your macOS machine."
                    ) {
                        withAnimation { showPowerSheet = false }
                        submitCommand("restart mac")
                    }

                    // Option 5: Shut Down Mac
                    powerActionRow(
                        icon: "power.circle.fill",
                        iconColor: Color.red,
                        badgeText: "SYSTEM SHUTDOWN",
                        badgeColor: Color.red,
                        title: "Shut Down Mac",
                        subtitle: "Powers off your Mac computer completely."
                    ) {
                        withAnimation { showPowerSheet = false }
                        submitCommand("shut down mac")
                    }
                }

                // Voice Prompt Tip
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                        .font(.system(size: 10))
                    Text("Tip: Say \"Shut Down\" anytime to close, and \"Open\" to wake.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.09, blue: 0.14).opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.5), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
            )
            .padding(20)
        }
    }

    private func powerActionRow(
        icon: String,
        iconColor: Color,
        badgeText: String,
        badgeColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)

                        Text(badgeText)
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundColor(badgeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(badgeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(subtitle)
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
            )
        }
        .buttonStyle(AuraClickableButtonStyle())
    }
}

// MARK: - Color Hex Initializer Extension
extension Color {
    public init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}


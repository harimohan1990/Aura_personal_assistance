import Foundation
import AVFoundation
import Speech
import AppKit

@MainActor
public final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = SpeechManager()

    @Published public var isListening: Bool = false
    @Published public var isSpeaking: Bool = false
    @Published public var speechEnabled: Bool = true
    @Published public var recognizedText: String = ""
    @Published public var audioLevel: Float = 0.0

    // MARK: - Hands-Free & Accessibility Mode
    @Published public var isHandsFreeMode: Bool = true // Enabled by default for accessibility / motor disability
    @Published public var wakeWordRequired: Bool = false // False = direct speech; True = requires "Hey Aura"
    @Published public var statusMessage: String = "Hands-Free Voice Active (Listening...)"
    @Published public var isProcessingCommand: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var silenceTimer: Timer? = nil
    private var restartTimer: Timer? = nil
    private var speakingPulseTimer: Timer? = nil

    private var commandCallback: (@Sendable (String) -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
        requestSpeechAuthorization()
    }

    private func requestSpeechAuthorization() {
        // 1. Microphone Hardware Permission (Mandatory on macOS)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            print("[SpeechManager] Microphone access granted: \(granted)")
        }

        // 2. Speech Recognizer Permission
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("[SpeechManager] Speech recognition authorized.")
                    if let self = self, self.isHandsFreeMode && !self.isListening {
                        self.startContinuousListening()
                    }
                default:
                    print("[SpeechManager] Speech recognition authorization status: \(authStatus.rawValue)")
                }
            }
        }
    }

    // MARK: - Speech Synthesis (Text to Speech)

    public func speak(_ text: String) {
        guard speechEnabled, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Temporarily pause recognition so AURA doesn't transcribe its own speech output
        pauseRecognitionForSpeech()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0

        // Find premium Siri or enhanced voice
        if let siriVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.starts(with: "en") && ($0.name.contains("Siri") || $0.name.contains("Samantha") || $0.quality == .enhanced)
        }) {
            utterance.voice = siriVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        self.isSpeaking = true
        startSpeakingPulse()
        synthesizer.speak(utterance)
    }

    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        self.isSpeaking = false
        stopSpeakingPulse()

        if isHandsFreeMode {
            scheduleRecognitionResume(after: 0.3)
        }
    }

    private func startSpeakingPulse() {
        speakingPulseTimer?.invalidate()
        speakingPulseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isSpeaking else { return }
                self.audioLevel = Float.random(in: 0.45...0.95)
            }
        }
    }

    private func stopSpeakingPulse() {
        speakingPulseTimer?.invalidate()
        speakingPulseTimer = nil
        self.audioLevel = 0.0
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
            self.startSpeakingPulse()
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.audioLevel = Float.random(in: 0.7...1.0)
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.stopSpeakingPulse()
            if self.isHandsFreeMode {
                self.scheduleRecognitionResume(after: 0.35)
            }
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.stopSpeakingPulse()
            if self.isHandsFreeMode {
                self.scheduleRecognitionResume(after: 0.35)
            }
        }
    }

    // MARK: - Hands-Free Continuous Speech Recognition

    public func setupHandsFree(onCommandRecognized: @Sendable @escaping (String) -> Void) {
        self.commandCallback = onCommandRecognized
        if isHandsFreeMode {
            startContinuousListening()
        }
    }

    public func toggleHandsFree(enabled: Bool? = nil) {
        let newState = enabled ?? !isHandsFreeMode
        self.isHandsFreeMode = newState
        if newState {
            statusMessage = "Hands-Free Voice Active (Listening...)"
            startContinuousListening()
        } else {
            statusMessage = "Hands-Free Paused (Manual Mode)"
            stopListening()
        }
    }

    public func setWakeWordRequired(_ required: Bool) {
        self.wakeWordRequired = required
    }

    public func startContinuousListening() {
        guard !isSpeaking else { return }

        startAudioEngineIfNeeded()
        startRecognitionSession()
    }

    private func startAudioEngineIfNeeded() {
        let inputNode = audioEngine.inputNode
        if !audioEngine.isRunning {
            inputNode.removeTap(onBus: 0)

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                print("[SpeechManager] Warning: Audio input format not ready yet.")
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self else { return }

                // Echo cancellation guard: Don't feed audio while AURA is speaking out loud
                if self.isSpeaking {
                    return
                }

                self.recognitionRequest?.append(buffer)

                let channelData = buffer.floatChannelData?[0]
                let channelDataValue = channelData?.pointee ?? 0.0
                let rms = abs(channelDataValue)
                Task { @MainActor in
                    self.audioLevel = min(max(rms * 10.0, 0.0), 1.0)
                }
            }

            do {
                audioEngine.prepare()
                try audioEngine.start()
                print("[SpeechManager] Continuous AudioEngine started.")
            } catch {
                print("[SpeechManager] AudioEngine start failed: \(error)")
            }
        }
    }

    private func startRecognitionSession() {
        guard !isSpeaking else { return }

        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        self.recognizedText = ""
        self.isListening = true

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                Task { @MainActor in
                    guard !self.isSpeaking else { return }
                    self.recognizedText = transcription
                    print("[SpeechManager] Transcribed: \"\(transcription)\"")

                    // Reset silence debounce: 1.3 seconds of pause marks end of utterance
                    self.silenceTimer?.invalidate()
                    self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: false) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            guard let self = self, self.isListening, !self.recognizedText.isEmpty, !self.isSpeaking else { return }
                            self.dispatchSpokenUtterance(self.recognizedText)
                        }
                    }
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in
                    if !self.recognizedText.isEmpty && !self.isSpeaking {
                        let text = self.recognizedText
                        self.recognizedText = ""
                        self.dispatchSpokenUtterance(text)
                    } else if self.isHandsFreeMode && !self.isSpeaking {
                        // SFSpeechRecognizer 60-second audio buffer timeout; restart session cleanly
                        self.scheduleRecognitionResume(after: 0.4)
                    }
                }
            }
        }
    }

    private func pauseRecognitionForSpeech() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        self.isListening = false
    }

    public func resumeListeningAfterAction() {
        self.isProcessingCommand = false
        if self.isHandsFreeMode && !self.isSpeaking {
            self.scheduleRecognitionResume(after: 0.3)
        }
    }

    private func scheduleRecognitionResume(after delay: TimeInterval) {
        restartTimer?.invalidate()
        restartTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isHandsFreeMode, !self.isSpeaking, !self.isProcessingCommand else { return }
                self.startContinuousListening()
            }
        }
    }

    private func dispatchSpokenUtterance(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let lower = text.lowercased()

        // If wake word is required, ensure phrase begins with wake word
        if wakeWordRequired {
            let wakeWords = ["hey aura", "hi aura", "ok aura", "aura"]
            let hasWakeWord = wakeWords.contains { lower.starts(with: $0) }
            if !hasWakeWord {
                self.recognizedText = ""
                if isHandsFreeMode && !isSpeaking && !isProcessingCommand {
                    scheduleRecognitionResume(after: 0.2)
                }
                return
            }
        }

        self.recognizedText = ""
        pauseRecognitionForSpeech()
        self.isProcessingCommand = true

        print("[SpeechManager] Final voice command dispatched: \"\(text)\"")
        let cb = self.commandCallback
        cb?(text)
    }

    // MARK: - Legacy / Manual Toggle Listening (Preserved)

    public func toggleListening(onCommandRecognized: @Sendable @escaping (String) -> Void) {
        self.commandCallback = onCommandRecognized
        if isSpeaking {
            stopSpeaking()
            return
        }

        if isListening {
            let pending = recognizedText.trimmingCharacters(in: .whitespaces)
            stopListening()
            if !pending.isEmpty {
                onCommandRecognized(pending)
            }
        } else {
            startListening(onCommandRecognized: onCommandRecognized)
        }
    }

    public func startListening(onCommandRecognized: @Sendable @escaping (String) -> Void) {
        self.commandCallback = onCommandRecognized
        startContinuousListening()
    }

    public func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        restartTimer?.invalidate()
        restartTimer = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        self.isListening = false
        self.audioLevel = 0.0
    }
}

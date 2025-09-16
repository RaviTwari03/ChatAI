//
//  TTSService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 07/09/25.
//

import Foundation
import AVFoundation

enum VoiceProvider: String, Codable { case system, openai }

struct VoiceOption: Identifiable, Hashable {
    let id = UUID()
    // System voice identifier or OpenAI voice name
    let identifier: String
    let name: String
    let subtitle: String
    let provider: VoiceProvider
    let language: String

    // MARK: Presets
    static let systemPresets: [VoiceOption] = [
        VoiceOption(identifier: "com.apple.ttsbundle.Samantha-compact", name: "Samantha", subtitle: "US English", provider: .system, language: "en-US"),
        VoiceOption(identifier: "com.apple.ttsbundle.Daniel-compact",   name: "Daniel",   subtitle: "UK English", provider: .system, language: "en-GB"),
        VoiceOption(identifier: "com.apple.ttsbundle.Moira-compact",    name: "Moira",    subtitle: "Ireland",    provider: .system, language: "en-IE"),
        VoiceOption(identifier: "com.apple.ttsbundle.Tessa-compact",    name: "Tessa",    subtitle: "South Africa",provider: .system, language: "en-ZA"),
        VoiceOption(identifier: "com.apple.ttsbundle.Karen-compact",    name: "Karen",    subtitle: "Australia",  provider: .system, language: "en-AU")
    ]

    static let openAIStandard: [VoiceOption] = [
        VoiceOption(identifier: "alloy",   name: "Alloy",   subtitle: "OpenAI • Standard TTS", provider: .openai, language: "en"),
        VoiceOption(identifier: "echo",    name: "Echo",    subtitle: "OpenAI • Standard TTS", provider: .openai, language: "en"),
        VoiceOption(identifier: "fable",   name: "Fable",   subtitle: "OpenAI • Standard TTS", provider: .openai, language: "en"),
        VoiceOption(identifier: "onyx",    name: "Onyx",    subtitle: "OpenAI • Standard TTS", provider: .openai, language: "en"),
        VoiceOption(identifier: "nova",    name: "Nova",    subtitle: "OpenAI • Standard TTS", provider: .openai, language: "en"),
        VoiceOption(identifier: "shimmer", name: "Shimmer", subtitle: "OpenAI • Standard TTS", provider: .openai, language: "en")
    ]

    static let openAIRealtime: [VoiceOption] = [
        VoiceOption(identifier: "ash",    name: "Ash",    subtitle: "OpenAI • Realtime", provider: .openai, language: "en"),
        VoiceOption(identifier: "ballad", name: "Ballad", subtitle: "OpenAI • Realtime", provider: .openai, language: "en"),
        VoiceOption(identifier: "coral",  name: "Coral",  subtitle: "OpenAI • Realtime", provider: .openai, language: "en"),
        VoiceOption(identifier: "sage",   name: "Sage",   subtitle: "OpenAI • Realtime", provider: .openai, language: "en"),
        VoiceOption(identifier: "verse",  name: "Verse",  subtitle: "OpenAI • Realtime", provider: .openai, language: "en")
    ]

    static let availableVoices: [VoiceOption] = systemPresets + openAIStandard + openAIRealtime

    static let defaultVoice: VoiceOption = systemPresets.first!
}

final class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    @Published var isSpeaking: Bool = false
    @Published var selectedVoice: VoiceOption = .defaultVoice {
        didSet {
            UserDefaults.standard.set(selectedVoice.identifier, forKey: "selectedVoiceIdentifier")
            UserDefaults.standard.set(selectedVoice.provider.rawValue, forKey: "selectedVoiceProvider")
        }
    }

    var onFinish: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self

        // Load saved voice preference if present
        let savedId = UserDefaults.standard.string(forKey: "selectedVoiceIdentifier")
        let savedProvider = UserDefaults.standard.string(forKey: "selectedVoiceProvider").flatMap { VoiceProvider(rawValue: $0) }
        if let id = savedId, let provider = savedProvider,
           let found = VoiceOption.availableVoices.first(where: { $0.identifier == id && $0.provider == provider }) {
            selectedVoice = found
        }
    }

    func speak(_ text: String, language: String? = nil) {
        stop() // stop any current playback
        switch selectedVoice.provider {
        case .system:
            speakSystem(text, language: language)
        case .openai:
            Task { await speakOpenAI(text) }
        }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        player?.stop()
        isSpeaking = false
    }

    // MARK: System TTS
    private func speakSystem(_ text: String, language: String?) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        let utterance = AVSpeechUtterance(string: text)
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoice.identifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language ?? selectedVoice.language)
        }
        utterance.rate = 0.48
        isSpeaking = true
        synth.speak(utterance)
    }

    // MARK: OpenAI TTS
    private func openAIAPIKey() -> String? {
        Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String
    }

    private func synthesizeOpenAI(text: String, voice: String) async throws -> Data {
        guard let apiKey = openAIAPIKey(), !apiKey.isEmpty else {
            throw NSError(domain: "TTSService", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Missing OPENAI_API_KEY in Info.plist"])
        }
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "gpt-4o-mini-tts",
            "input": text,
            "voice": voice,
            "format": "mp3"
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200 else {
            let errText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "TTSService", code: status, userInfo: [NSLocalizedDescriptionKey: errText])
        }
        return data
    }

    private func speakOpenAI(_ text: String) async {
        do {
            let data = try await synthesizeOpenAI(text: text, voice: selectedVoice.identifier)
            try await MainActor.run {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, mode: .default, options: [.duckOthers, .defaultToSpeaker])
                try? session.setActive(true)
                self.player = try AVAudioPlayer(data: data)
                self.player?.prepareToPlay()
                self.player?.play()
                self.isSpeaking = true
            }
        } catch {
            print("OpenAI TTS error: \(error)")
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}

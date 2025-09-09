//
//  TTSService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 07/09/25.
//

import Foundation
import AVFoundation

struct VoiceOption: Identifiable, Hashable {
    let id = UUID()
    let identifier: String
    let name: String
    let language: String
    
    static let defaultVoice = VoiceOption(
        identifier: "com.apple.ttsbundle.Samantha-compact",
        name: "Samantha",
        language: "en-US"
    )
    
    static let availableVoices: [VoiceOption] = [
        VoiceOption(identifier: "com.apple.ttsbundle.Samantha-compact", name: "Samantha (US)", language: "en-US"),
        VoiceOption(identifier: "com.apple.ttsbundle.Daniel-compact", name: "Daniel (UK)", language: "en-GB"),
        VoiceOption(identifier: "com.apple.ttsbundle.Moira-compact", name: "Moira (Ireland)", language: "en-IE"),
        VoiceOption(identifier: "com.apple.ttsbundle.Tessa-compact", name: "Tessa (South Africa)", language: "en-ZA"),
        VoiceOption(identifier: "com.apple.ttsbundle.Karen-compact", name: "Karen (Australia)", language: "en-AU")
    ]
}

final class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    @Published var selectedVoice: VoiceOption = .defaultVoice {
        didSet {
            // Save the selected voice identifier to UserDefaults
            UserDefaults.standard.set(selectedVoice.identifier, forKey: "selectedVoiceIdentifier")
        }
    }
    
    var onFinish: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self
        
        // Load saved voice preference
        if let savedVoiceId = UserDefaults.standard.string(forKey: "selectedVoiceIdentifier"),
           let savedVoice = VoiceOption.availableVoices.first(where: { $0.identifier == savedVoiceId }) {
            selectedVoice = savedVoice
        }
    }

    func speak(_ text: String, language: String? = nil) {
        // Configure category to play through speaker
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        let utterance = AVSpeechUtterance(string: text)
        
        // Use the selected voice
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoice.identifier) {
            utterance.voice = voice
        } else {
            // Fallback to default voice if selected voice is not available
            utterance.voice = AVSpeechSynthesisVoice(language: language ?? "en-US")
        }
        
        utterance.rate = 0.48
        isSpeaking = true
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        isSpeaking = false
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

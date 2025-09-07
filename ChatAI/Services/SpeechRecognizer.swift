//
//  SpeechRecognizer.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 07/09/25.
//

import Foundation
import AVFoundation
import Speech

/// Simple speech-to-text helper built on SFSpeechRecognizer + AVAudioEngine.
/// - Request authorization with `requestAuthorization()` before first use.
/// - Call `start()` to begin dictation and `stop()` to end.
/// - Observe `transcript` for live text.
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages.first ?? "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Permission
    func requestAuthorization() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async { [weak self] in
                    self?.authorizationStatus = status
                    continuation.resume()
                }
            }
        }
        // Also request microphone permission using AVAudioSession for broader compatibility
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .undetermined:
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                session.requestRecordPermission { _ in continuation.resume() }
            }
        default:
            break
        }
    }

    // MARK: - Recording control
    func start() throws {
        guard !isRecording else { return }
        transcript = ""

        // Ensure permissions
        guard authorizationStatus == .authorized else {
            throw NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized. Enable in Settings."])
        }
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            throw NSError(domain: "SpeechRecognizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Microphone access denied. Enable in Settings."])
        }

        let audioSession = AVAudioSession.sharedInstance()
        // Use playAndRecord so we can capture mic while allowing TTS playback between turns.
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self?.finish()
                }
            }
        }

        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    func stop() {
        guard isRecording else { return }
        finish()
    }

    private func finish() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        DispatchQueue.main.async {
            self.isRecording = false
            // Deactivate session softly
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}

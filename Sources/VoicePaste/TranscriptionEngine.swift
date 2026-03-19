import Foundation
import AVFoundation
import Speech

/// Manages audio capture via AVAudioEngine and on-device speech recognition
/// via SFSpeechRecognizer. Streams mic audio into a recognition request and
/// delivers partial + final transcription results via callbacks.
class TranscriptionEngine {
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    /// Tracks whether permissions have been granted
    private var isAuthorized = false

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        requestPermissions()
    }

    // MARK: - Permissions

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                self?.isAuthorized = true
                print("[VoicePaste] Speech recognition authorized")
            case .denied:
                print("[VoicePaste] Speech recognition denied by user")
            case .restricted:
                print("[VoicePaste] Speech recognition restricted on this device")
            case .notDetermined:
                print("[VoicePaste] Speech recognition not determined")
            @unknown default:
                break
            }
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard isAuthorized else {
            onError?(TranscriptionError.notAuthorized)
            return
        }
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            onError?(TranscriptionError.recognizerUnavailable)
            return
        }

        // Cancel any in-progress task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Set up audio session
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create recognition request — on-device if available
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        // Prefer on-device recognition (macOS 13+ / iOS 16+)
        if #available(macOS 13, *) {
            request.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
            if speechRecognizer.supportsOnDeviceRecognition {
                print("[VoicePaste] Using on-device recognition")
            } else {
                print("[VoicePaste] On-device not available, using server")
            }
        }

        self.recognitionRequest = request

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            if let error = error {
                // Don't report cancellation as an error
                let nsError = error as NSError
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                    // Recognition was cancelled — this is normal on keyUp
                    return
                }
                self?.onError?(error)
                return
            }

            guard let result = result else { return }

            let text = result.bestTranscription.formattedString

            if result.isFinal {
                self?.onFinalResult?(text)
            } else {
                self?.onPartialResult?(text)
            }
        }

        // Install audio tap — feed mic buffers to recognizer
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // Start the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("[VoicePaste] Audio engine started — listening")
        } catch {
            onError?(error)
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        print("[VoicePaste] Audio engine stopped — finalizing transcription")
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case notAuthorized
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized. Grant permission in System Settings → Privacy & Security → Speech Recognition."
        case .recognizerUnavailable:
            return "Speech recognizer is not available for the current locale."
        }
    }
}

import SwiftUI

@main
struct VoicePasteApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Image(systemName: appState.menuBarIcon)
        }
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var status: VoiceStatus = .ready
    @Published var lastTranscription: String = ""

    let hotkeyManager: HotkeyManager
    let transcriptionEngine: TranscriptionEngine
    let textPaster: TextPaster

    var menuBarIcon: String {
        switch status {
        case .ready:
            return "mic"
        case .listening:
            return "mic.fill"
        case .transcribing:
            return "text.bubble"
        case .error:
            return "mic.slash"
        }
    }

    init() {
        let engine = TranscriptionEngine()
        let paster = TextPaster()
        let hotkey = HotkeyManager()

        self.transcriptionEngine = engine
        self.textPaster = paster
        self.hotkeyManager = hotkey

        hotkey.onKeyDown = { [weak self] in
            self?.startListening()
        }

        hotkey.onKeyUp = { [weak self] in
            self?.stopListening()
        }

        engine.onPartialResult = { [weak self] text in
            Task { @MainActor in
                self?.lastTranscription = text
            }
        }

        engine.onFinalResult = { [weak self] text in
            Task { @MainActor in
                self?.lastTranscription = text
                self?.status = .ready
                if !text.isEmpty {
                    paster.paste(text: text)
                }
            }
        }

        engine.onError = { [weak self] error in
            Task { @MainActor in
                self?.status = .error
                print("Transcription error: \(error.localizedDescription)")
                // Auto-recover after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self?.status = .ready
            }
        }
    }

    func startListening() {
        guard status == .ready else { return }
        status = .listening
        transcriptionEngine.startRecording()
    }

    func stopListening() {
        guard status == .listening else { return }
        status = .transcribing
        transcriptionEngine.stopRecording()
    }
}

// MARK: - Status

enum VoiceStatus: String {
    case ready = "Ready"
    case listening = "Listening..."
    case transcribing = "Transcribing..."
    case error = "Error"
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack {
            Text("VoicePaste")
                .font(.headline)

            Divider()

            Label(appState.status.rawValue, systemImage: appState.menuBarIcon)
                .foregroundColor(statusColor)

            if !appState.lastTranscription.isEmpty {
                Divider()
                Text(appState.lastTranscription)
                    .font(.caption)
                    .lineLimit(3)
                    .frame(maxWidth: 250, alignment: .leading)
            }

            Divider()

            Text("Hold \(appState.hotkeyManager.hotkeyDescription) to dictate")
                .font(.caption2)
                .foregroundColor(.secondary)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(4)
    }

    var statusColor: Color {
        switch appState.status {
        case .ready: return .primary
        case .listening: return .green
        case .transcribing: return .orange
        case .error: return .red
        }
    }
}

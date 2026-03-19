# VoicePaste

## What This Is
Free, open-source macOS accessibility tool. Global hotkey → on-device speech recognition → paste into frontmost app. Built for people with motor disabilities who need reliable voice input in terminals.

## Architecture
- **SwiftUI MenuBarExtra** — no dock icon, no main window, lives in menubar
- **HotKey library** (soffes/HotKey) — Carbon global hotkey API wrapper
- **AVAudioEngine** — mic capture, streams buffers to recognizer
- **SFSpeechRecognizer** — Apple's on-device speech-to-text
- **TextPaster** — clipboard + CGEvent Cmd+V simulation, restores clipboard after

## Project Structure
```
Sources/VoicePaste/
├── VoicePasteApp.swift          # @main, MenuBarExtra, AppState
├── HotkeyManager.swift          # Global hotkey (⌥⇧Space)
├── TranscriptionEngine.swift    # AVAudioEngine + SFSpeechRecognizer
└── TextPaster.swift             # Paste via clipboard + CGEvent
```

## Build & Run
```bash
./build.sh              # builds + creates .build/VoicePaste.app
open .build/VoicePaste.app
```
Requires: macOS 13+, Swift 5.9+

## Key Decisions
- **Swift Package Manager** over Xcode project — buildable from CLI, reviewable diffs
- **On-device recognition preferred** — `requiresOnDeviceRecognition` set when supported
- **Clipboard save/restore** — doesn't destroy user's clipboard
- **Ad-hoc codesigning** — no Apple dev account needed for local use
- **LSUIElement = true** — no dock icon

## Permissions
App needs four macOS permissions on first launch:
1. Microphone (Info.plist + entitlements)
2. Speech Recognition (Info.plist)
3. Accessibility (for CGEvent paste — user grants in System Settings)
4. Input Monitoring (for global hotkey when app not focused — user grants in System Settings)

**⚠️ Re-sign gotcha:** Every `codesign` invalidates Accessibility + Input Monitoring permissions. macOS does NOT re-prompt — the app silently stops working. After any rebuild, user must manually remove and re-add VoicePaste in both Accessibility AND Input Monitoring, then restart the app.

## Future Phases
- Phase 2: iOS remote keyboard (websocket to Mac)
- Phase 3: Standalone Claude voice assistant (iOS)
- Phase 4: CC session bridge (if remote API exists)

## GitHub
`Gerk/voicepaste` — public, main branch

## Community Context
Built to address accessibility gaps in Claude Code terminal voice input.
See: anthropics/claude-code#36055

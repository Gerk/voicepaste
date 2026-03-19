# VoicePaste — Session Notes

## Status: Phase 1 Built (2026-03-19)

App compiles, bundles, and is ready for first real test. Not yet tested live.

## What was built
- Full SwiftUI MenuBarExtra app — no dock icon, mic icon in menubar
- **HotkeyManager** — global ⌥⇧Space via soffes/HotKey library (Carbon API wrapper)
  - keyDown → start recording, keyUp → stop + transcribe + paste
- **TranscriptionEngine** — AVAudioEngine mic capture → SFSpeechRecognizer streaming
  - Prefers on-device recognition when available (`requiresOnDeviceRecognition`)
  - Falls back to Apple's server transparently
  - Filters out error code 216 (normal cancellation on keyUp)
- **TextPaster** — copies text to clipboard → CGEvent simulates Cmd+V → restores previous clipboard
- **AppState** — ties everything together, drives menubar icon state changes
- **build.sh** — `swift build -c release` + .app bundle creation + ad-hoc codesigning with entitlements

## Build details
- Swift Package Manager project (not Xcode project — CLI-buildable, reviewable diffs)
- HotKey 0.2.1 dependency fetched from GitHub
- Entitlements file grants `com.apple.security.device.audio-input`
- Info.plist has `LSUIElement=true` (no dock icon), mic + speech recognition usage descriptions
- Builds cleanly with Command Line Tools (no full Xcode needed)
- XCTest path warning is cosmetic — doesn't affect build

## GitHub
- Repo: `Gerk/voicepaste` (public)
- Branch: `main`
- 2 commits pushed

## Decisions confirmed by Mark
- App name: **VoicePaste** (was placeholder, now final)
- Hotkey: **⌥⇧Space** (Option + Shift + Space)
- GitHub repo name: `Gerk/voicepaste`
- Public repo (open-source accessibility tool, not commercial)

## Not yet done
- **First live test** — need to `open .build/VoicePaste.app`, grant permissions, try it
- Test targets: iTerm2, VS Code terminal, Terminal.app, TextEdit
- Test offline with Voice Control enabled
- Error UX — what happens when permissions are denied
- Configurable hotkey UI (currently hardcoded)
- Visual/audio feedback on activation
- README could link to #36055 more prominently

## Open questions (unanswered)
- Does Mark use Hammerspoon or Karabiner? (potential hotkey conflicts)
- Optional hulk/whisper integration as a toggle, or keep pure macOS?

## Future phases (from plan, not started)
- Phase 2: iOS remote keyboard — speak on phone, text appears on Mac (websocket)
- Phase 3: Standalone Claude voice assistant — iOS app, direct API, no CC session
- Phase 4: CC session bridge — if Claude Code ever exposes remote API

## Key files
```
Sources/VoicePaste/
├── VoicePasteApp.swift          # @main, MenuBarExtra, AppState, status enum
├── HotkeyManager.swift          # Global hotkey (⌥⇧Space), key handlers
├── TranscriptionEngine.swift    # AVAudioEngine + SFSpeechRecognizer
└── TextPaster.swift             # Clipboard save/paste/restore via CGEvent
```

## Permissions the app needs (user grants on first launch)
1. Microphone
2. Speech Recognition
3. Accessibility (for CGEvent Cmd+V simulation)
4. Input Monitoring (for global hotkey when app not focused)

## Community context
Built to address accessibility gaps in Claude Code's terminal voice input.
GitHub issue: anthropics/claude-code#36055
The irony: using macOS *accessibility* APIs to fix an *accessibility* gap in Claude Code.

# VoicePaste

A free, open-source macOS accessibility tool that lets you dictate text into any application — including terminals where macOS dictation doesn't work.

**Hold a hotkey → speak → release → text appears in the frontmost app.**

Built for people with motor disabilities who need reliable voice input in tools like Claude Code, iTerm2, and VS Code's integrated terminal.

## Why This Exists

macOS has world-class dictation built in. It works everywhere — except in terminal emulators, where many developers spend their day. Meanwhile, Claude Code's built-in voice input is unreliable and can't be pointed at a custom STT server.

VoicePaste bypasses the problem entirely. It captures speech via Apple's on-device `SFSpeechRecognizer`, then pastes the result into whatever window is focused. Claude Code (or any terminal) just sees keyboard input.

No cloud dependency. No model downloads. No API keys. Works offline.

See [anthropics/claude-code#36055](https://github.com/anthropics/claude-code/issues/36055) for community discussion on accessibility gaps in Claude Code.

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+ toolchain (Xcode or Command Line Tools)

## Build

```bash
./build.sh
```

This creates `.build/VoicePaste.app`.

## Run

```bash
open .build/VoicePaste.app
```

On first launch, macOS will prompt for three permissions:
1. **Microphone** — to capture your voice
2. **Speech Recognition** — to transcribe on-device
3. **Accessibility** — to simulate Cmd+V in the frontmost app

Grant all three. VoicePaste appears as a mic icon in your menubar — no dock icon, no windows.

## Usage

**Hold `⌥⇧Space` (Option + Shift + Space) → speak → release.**

The transcribed text is pasted into whatever application is focused. Works with:
- iTerm2
- Terminal.app
- VS Code integrated terminal
- Claude Code
- Any standard text field

The menubar icon changes to show status:
- 🎤 Ready
- 🎤 (filled) Listening
- 💬 Transcribing

## How It Works

1. **HotKey** library registers a global `keyDown`/`keyUp` handler
2. On key down: `AVAudioEngine` starts capturing mic audio
3. Audio buffers stream into `SFSpeechRecognizer` for live recognition
4. On key up: audio stops, final transcription is captured
5. Text is copied to clipboard → `CGEvent` simulates Cmd+V → clipboard is restored

All processing happens on-device using Apple's built-in speech models.

## Project Structure

```
Sources/VoicePaste/
├── VoicePasteApp.swift          # @main, MenuBarExtra UI, app state
├── HotkeyManager.swift          # Global hotkey via HotKey library
├── TranscriptionEngine.swift    # AVAudioEngine + SFSpeechRecognizer
└── TextPaster.swift             # Clipboard + Cmd+V simulation
```

## License

MIT

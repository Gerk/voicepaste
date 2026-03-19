# VoicePaste — Next Steps Plan

## Current State (2026-03-19)
Working Phase 1: hold Option+Shift+Space → speak → release → text pasted via clipboard+Cmd+V.
Reliable enough for testing. Flaky in terminals due to PTY paste path.

## Priority 1: Key-by-key typing (replace clipboard+Cmd+V)
- Rewrite TextPaster to use `CGEvent.keyboardSetUnicodeString()` per character
- Use `CGEventSource(.privateState)` to isolate from hardware modifier state
- NO overlay — just swap the output method, one change at a time
- This is the most likely fix for terminal reliability since PTYs expect individual keystrokes
- Already wrote and tested the code once (reverted with the overlay) — just needs to be applied standalone

## Priority 2: Focus-safe visual feedback
The NSPanel approach stole focus. Alternative approaches to try:
- **Menubar text**: show live partial text in the menubar icon area (no window at all)
- **NSWindow level .screenSaver** with `ignoresMouseEvents = true` — completely transparent to input
- **Core Animation layer** on a transparent window that never becomes key/main
- Research how macOS's own dictation bubble works — it doesn't steal focus

## Priority 3: Polish
- Configurable hotkey (UI in menu dropdown)
- Error feedback when permissions missing
- Auto-start on login (LaunchAgent or Login Items)
- Audio feedback (subtle click on start/stop)

## Priority 4: ESP32 Bluetooth push-to-talk button
- ESP32 with a single GPIO button, BLE GATT peripheral
- Button down → BLE notify → Mac starts recording
- Button up → BLE notify → Mac stops, transcribes, types
- Mac side: `CoreBluetooth` `CBCentralManager` — no special permissions beyond Bluetooth
- Completely bypasses hotkey/Input Monitoring/Accessibility permission hell
- Mark has ESP32 hardware and experience — this is a real option, not theoretical
- Could be a desk button, a foot pedal, or even a wearable ring button

## Parking Lot
- Trailing space behavior — maybe configurable or context-aware
- Whisper/hulk integration as optional backend toggle
- The re-sign permission invalidation is a pain during dev — consider a stable signing identity or a dev workflow that avoids it

## Architecture Note
Apple likely didn't make dictation work in terminals for the same reason we're hitting friction — the PTY paste path is unreliable. Key-by-key is the right approach, not clipboard hacks. If that works, we've solved something Apple chose not to.

import Foundation
import HotKey
import AppKit

/// Manages the global hotkey registration using the HotKey library.
/// Hold-to-talk: keyDown starts recording, keyUp stops and triggers paste.
class HotkeyManager {
    private var hotKey: HotKey?

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    /// Human-readable description of the current hotkey for the menu
    var hotkeyDescription: String {
        "⌥⇧Space"
    }

    init() {
        // Default: Option + Shift + Space
        // Chosen to avoid conflicts with common shortcuts:
        //   - Cmd+Space = Spotlight
        //   - Ctrl+Space = input source switching
        //   - Option+Space = non-breaking space (rarely used in terminals)
        //   - Option+Shift+Space = unlikely to conflict with anything
        setupHotkey(key: .space, modifiers: [.option, .shift])
    }

    func setupHotkey(key: Key, modifiers: NSEvent.ModifierFlags) {
        // Remove existing hotkey if any
        hotKey = nil

        let hk = HotKey(key: key, modifiers: modifiers)

        hk.keyDownHandler = { [weak self] in
            print("[VoicePaste] Hotkey pressed — start recording")
            self?.onKeyDown?()
        }

        hk.keyUpHandler = { [weak self] in
            print("[VoicePaste] Hotkey released — stop recording")
            self?.onKeyUp?()
        }

        hotKey = hk
    }
}

import Foundation
import AppKit
import CoreGraphics

/// Pastes transcribed text into the frontmost application.
///
/// Phase 1 approach: copy text to the system clipboard, then simulate
/// Cmd+V via CGEvent. This works reliably with terminals (iTerm2,
/// Terminal.app, VS Code integrated terminal) and standard text fields.
///
/// Trade-off: overwrites the clipboard. A future Phase 2 could use
/// AXUIElement to insert text directly without touching the clipboard.
class TextPaster {

    /// Saves and restores the clipboard around the paste operation
    /// to minimize disruption to the user's clipboard contents.
    func paste(text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let previousContents = pasteboard.string(forType: .string)

        // Set our transcribed text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to ensure pasteboard is updated before simulating keypress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.simulatePaste()

            // Restore previous clipboard after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let previous = previousContents {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                }
            }
        }

        print("[VoicePaste] Pasted: \(text)")
    }

    /// Simulates Cmd+V keypress via CGEvent.
    /// Requires Accessibility permission in System Settings.
    private func simulatePaste() {
        // Virtual keycode for 'V' is 9
        let vKeyCode: CGKeyCode = 9

        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            print("[VoicePaste] Failed to create CGEvent — check Accessibility permissions")
            return
        }

        // Add Command modifier
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        // Post to the HID event stream (goes to frontmost app)
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

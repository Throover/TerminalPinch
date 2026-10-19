import Cocoa
import Carbon

/// Change la taille du texte du terminal au premier plan en gardant la taille de sa fenêtre.
final class Zoomer {
    static let shared = Zoomer()

    private var pending = 0
    private var busy = false
    private var target: NSRunningApplication?

    func enqueue(_ steps: Int, app: NSRunningApplication) {
        if target?.processIdentifier != app.processIdentifier { pending = 0 }
        target = app
        pending += steps
        flush()
    }

    // Regroupe les pas pendant qu'un changement est en cours, pour rester fluide.
    private func flush() {
        guard !busy, pending != 0, let app = target else { return }
        let n = pending
        pending = 0
        busy = true
        let finish = { [weak self] in
            self?.busy = false
            self?.flush()
        }
        if app.bundleIdentifier == Terminals.appleTerminal {
            DispatchQueue.main.async { Self.zoomAppleTerminal(n); finish() }
        } else {
            Self.zoomWithKeystrokes(n, pid: app.processIdentifier, done: finish)
        }
    }

    // Terminal d'Apple : AppleScript, puis on remet la fenêtre à sa taille.
    private static func zoomAppleTerminal(_ delta: Int) {
        let script = """
        tell application "Terminal"
            if (count of windows) is 0 then return
            set w to front window
            set b to bounds of w
            set t to selected tab of w
            set s to (font size of t) + (\(delta))
            if s < 6 then set s to 6
            if s > 96 then set s to 96
            set font size of t to s
            set bounds of w to b
        end tell
        """
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
        if let err = err { NSLog("TerminalPinch AppleScript: \(err)") }
    }

    // Autres terminaux : raccourci Cmd = / Cmd -, puis on remet la fenêtre à sa taille (Accessibilité).
    private static func zoomWithKeystrokes(_ n: Int, pid: pid_t, done: @escaping () -> Void) {
        let window = focusedWindow(pid: pid)
        let frame = window.flatMap(getFrame)
        guard let key = n > 0 ? Keys.bigger : Keys.smaller else { done(); return }
        for _ in 0..<abs(n) { Keys.post(key) }

        guard let window = window, let frame = frame else { done(); return }
        var checks = 0
        func restore() {
            if let cur = getFrame(window), cur != frame { setFrame(window, frame) }
            checks += 1
            if checks < 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: restore)
            } else {
                done()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: restore)
    }

    private static func focusedWindow(pid: pid_t) -> AXUIElement? {
        var value: CFTypeRef?
        let app = AXUIElementCreateApplication(pid)
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let v = value, CFGetTypeID(v) == AXUIElementGetTypeID() else { return nil }
        return (v as! AXUIElement)
    }

    private static func getFrame(_ w: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?, sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(w, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(w, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let p = posRef, let s = sizeRef else { return nil }
        var pos = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(p as! AXValue, .cgPoint, &pos)
        AXValueGetValue(s as! AXValue, .cgSize, &size)
        return CGRect(origin: pos, size: size)
    }

    private static func setFrame(_ w: AXUIElement, _ f: CGRect) {
        var size = f.size, pos = f.origin
        if let s = AXValueCreate(.cgSize, &size) { AXUIElementSetAttributeValue(w, kAXSizeAttribute as CFString, s) }
        if let p = AXValueCreate(.cgPoint, &pos) { AXUIElementSetAttributeValue(w, kAXPositionAttribute as CFString, p) }
    }
}

/// Trouve les touches « = » et « - » selon la disposition du clavier (QWERTY, AZERTY, QWERTZ…).
enum Keys {
    struct Key { let code: CGKeyCode; let shift: Bool }

    static var bigger: Key? { find("=") ?? find("+") }
    static var smaller: Key? { find("-") }

    static func post(_ key: Key) {
        let src = CGEventSource(stateID: .hidSystemState)
        var flags: CGEventFlags = .maskCommand
        if key.shift { flags.insert(.maskShift) }
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: src, virtualKey: key.code, keyDown: down)
            e?.flags = flags
            e?.post(tap: .cghidEventTap)
        }
    }

    private static func find(_ char: String) -> Key? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return char == "=" ? Key(code: 24, shift: false) : char == "-" ? Key(code: 27, shift: false) : nil
        }
        let data = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data
        return data.withUnsafeBytes { raw -> Key? in
            guard let layout = raw.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return nil }
            for shift in [false, true] {
                for code in 0..<128 {
                    var dead: UInt32 = 0
                    var chars = [UniChar](repeating: 0, count: 4)
                    var len = 0
                    let mods: UInt32 = shift ? UInt32(shiftKey >> 8) & 0xFF : 0
                    UCKeyTranslate(layout, UInt16(code), UInt16(kUCKeyActionDown), mods,
                                   UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                   &dead, 4, &len, &chars)
                    if len > 0, String(utf16CodeUnits: chars, count: len) == char {
                        return Key(code: CGKeyCode(code), shift: shift)
                    }
                }
            }
            return nil
        }
    }
}

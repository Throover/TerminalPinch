import Cocoa

/// Écoute les pincements du trackpad (sans les bloquer) et les convertit en pas de taille de police.
final class GestureMonitor {
    static let shared = GestureMonitor()

    private var tap: CFMachPort?
    private var accumulated: CGFloat = 0
    var isRunning: Bool { tap != nil }

    func start() -> Bool {
        if tap != nil { return true }
        // 29 = gesture, 30 = magnify
        let mask = CGEventMask((1 << 29) | (1 << 30))
        guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                        options: .listenOnly, eventsOfInterest: mask,
                                        callback: gestureCallback, userInfo: nil) else { return false }
        tap = t
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, t, 0), .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
        return true
    }

    fileprivate func reenable() {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
    }

    fileprivate func handle(_ ev: NSEvent) {
        guard let app = NSWorkspace.shared.frontmostApplication,
              Terminals.isActive(app.bundleIdentifier) else { return }
        if ev.phase == .began { accumulated = 0 }
        accumulated += ev.magnification

        let up = CGFloat(Settings.upStep), down = CGFloat(Settings.downStep)
        var steps = 0
        while accumulated >= up { steps += 1; accumulated -= up }
        while accumulated <= -down { steps -= 1; accumulated += down }
        if steps != 0 { Zoomer.shared.enqueue(steps, app: app) }
    }
}

private func gestureCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                             refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        GestureMonitor.shared.reenable()
    } else if let ev = NSEvent(cgEvent: event), ev.type == .magnify {
        GestureMonitor.shared.handle(ev)
    }
    return Unmanaged.passUnretained(event)
}

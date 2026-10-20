import Cocoa

enum CLI {
    static let factor = 1.3

    static func run(_ args: [String]) -> Int32 {
        if args.first == "--diag" { return diag(args.count > 1 ? args[1] : nil, listen: args.contains("--listen")) }
        guard args.count >= 2, args[0] == "--adjust", ["slower", "faster"].contains(args[1]) else {
            print("Usage: TerminalPinch --adjust slower|faster [+|-]")
            return 64
        }
        let f = args[1] == "slower" ? factor : 1 / factor
        let which = args.count > 2 ? args[2] : "both"
        var up = Settings.upStep, down = Settings.downStep
        if which != "-" { up = Settings.clamp(up * f) }
        if which != "+" { down = Settings.clamp(down * f) }
        Settings.upStep = up
        Settings.downStep = down
        Settings.d.synchronize()

        // Prévient l'app si elle tourne, pour appliquer tout de suite.
        DistributedNotificationCenter.default().postNotificationName(
            Settings.changedNotification, object: nil,
            userInfo: ["upStep": up, "downStep": down], deliverImmediately: true)

        print(L.f("cli.result", Int(Settings.speed(fromStep: up).rounded()), Int(Settings.speed(fromStep: down).rounded())))
        return 0
    }

    /// Diagnostic pour le support : autorisations et capacité à écouter le geste.
    /// Lancer via `open -n TerminalPinch.app --args --diag /chemin/fichier.txt` pour que macOS l'attribue à l'app.
    static var pinches = 0

    static func diag(_ path: String?, listen: Bool) -> Int32 {
        let mask = CGEventMask((1 << 29) | (1 << 30))
        let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                                    eventsOfInterest: mask, callback: { _, _, e, _ in
                                        if NSEvent(cgEvent: e)?.type == .magnify { CLI.pinches += 1 }
                                        return Unmanaged.passUnretained(e)
                                    }, userInfo: nil)
        if listen, let tap = tap {
            CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRunInMode(.defaultMode, 60, false)
        }
        let text = """
        version=\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "?")
        accessibility=\(AXIsProcessTrusted())
        inputMonitoring=\(CGPreflightListenEventAccess())
        gestureTap=\(tap != nil)
        pinchEventsReceived=\(listen ? String(pinches) : "-")
        """
        if let path = path { try? text.write(toFile: path, atomically: true, encoding: .utf8) } else { print(text) }
        return 0
    }
}

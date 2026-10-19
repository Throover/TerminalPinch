import Cocoa

// Mode ligne de commande (utilisé par les commandes Claude Code) : TerminalPinch --adjust slower|faster [+|-]
if CommandLine.arguments.count > 1 {
    exit(CLI.run(Array(CommandLine.arguments.dropFirst())))
}

// Une seule instance : si l'app tourne déjà, on lui demande d'afficher ses réglages.
let me = NSRunningApplication.current
if let other = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
    .first(where: { $0.processIdentifier != me.processIdentifier }) {
    other.activate(options: [])
    if let url = other.bundleURL { NSWorkspace.shared.open(url) }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

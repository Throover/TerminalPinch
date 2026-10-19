import Cocoa

struct TerminalApp: Identifiable {
    let id: String     // bundle identifier
    let name: String
}

enum Terminals {
    static let appleTerminal = "com.apple.Terminal"

    static let all: [TerminalApp] = [
        TerminalApp(id: appleTerminal, name: "Terminal"),
        TerminalApp(id: "com.googlecode.iterm2", name: "iTerm2"),
        TerminalApp(id: "com.mitchellh.ghostty", name: "Ghostty"),
        TerminalApp(id: "dev.warp.Warp-Stable", name: "Warp"),
        TerminalApp(id: "net.kovidgoyal.kitty", name: "kitty"),
        TerminalApp(id: "org.alacritty", name: "Alacritty"),
        TerminalApp(id: "com.github.wez.wezterm", name: "WezTerm"),
        TerminalApp(id: "co.zeit.hyper", name: "Hyper"),
        TerminalApp(id: "org.tabby", name: "Tabby"),
    ]

    static var installed: [TerminalApp] {
        all.filter { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.id) != nil }
    }

    static func isActive(_ bundleID: String?) -> Bool {
        guard let id = bundleID else { return false }
        return all.contains { $0.id == id } && !Settings.disabledTerminals.contains(id)
    }
}

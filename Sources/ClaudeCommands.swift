import Foundation

/// Installe les commandes Claude Code (skills) qui règlent la vitesse via le mode ligne de commande de l'app.
enum ClaudeCommands {
    static let marker = "<!-- terminalpinch -->"
    static var skillsDir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/skills")
    }
    static var claudeInstalled: Bool {
        FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude").path)
    }

    static func isValid(_ name: String) -> Bool {
        name.range(of: "^[a-z0-9][a-z0-9-]{0,39}$", options: .regularExpression) != nil
    }

    /// Met les fichiers en accord avec les réglages (appelé au lancement et à chaque changement).
    static func sync() {
        for name in Settings.installedCommands { remove(name) }
        Settings.installedCommands = []
        guard Settings.claudeEnabled, claudeInstalled else { return }

        let slower = Settings.slowerCommand, faster = Settings.fasterCommand
        guard isValid(slower), isValid(faster), slower != faster else { return }
        write(slower, action: "slower", description: L.t("skill.slower.desc"))
        write(faster, action: "faster", description: L.t("skill.faster.desc"))
        Settings.installedCommands = [slower, faster]
    }

    private static func write(_ name: String, action: String, description: String) {
        let exe = Bundle.main.executablePath ?? "/Applications/TerminalPinch.app/Contents/MacOS/TerminalPinch"
        let content = """
        ---
        name: \(name)
        description: \(description)
        argument-hint: "[+|-]"
        ---
        \(marker)

        Run exactly: `"\(exe)" --adjust \(action) $ARGUMENTS`

        Then reply in one short line, in the user's language, saying what changed and the new speeds it printed.
        """
        let dir = skillsDir.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? content.write(to: dir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }

    // Ne supprime que les dossiers créés par TerminalPinch.
    private static func remove(_ name: String) {
        let dir = skillsDir.appendingPathComponent(name)
        let file = dir.appendingPathComponent("SKILL.md")
        guard let text = try? String(contentsOf: file), text.contains(marker) else { return }
        try? FileManager.default.removeItem(at: dir)
    }
}

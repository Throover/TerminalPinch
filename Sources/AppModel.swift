import Cocoa
import ServiceManagement

final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var upSpeed: Double { didSet { Settings.upStep = Settings.step(fromSpeed: upSpeed) } }
    @Published var downSpeed: Double { didSet { Settings.downStep = Settings.step(fromSpeed: downSpeed) } }

    @Published var inputGranted = false
    @Published var axGranted = false
    @Published var monitorRunning = false

    @Published var menuBar: Bool {
        didSet { Settings.menuBarEnabled = menuBar; AppDelegate.shared?.updateStatusItem() }
    }
    @Published var claude: Bool {
        didSet { Settings.claudeEnabled = claude; ClaudeCommands.sync() }
    }
    @Published var slowerName: String { didSet { saveCommandNames() } }
    @Published var fasterName: String { didSet { saveCommandNames() } }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if launchAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch { NSLog("TerminalPinch login item: \(error)") }
        }
    }
    @Published var disabledTerminals: Set<String> { didSet { Settings.disabledTerminals = disabledTerminals } }

    private var timer: Timer?

    private init() {
        upSpeed = Settings.speed(fromStep: Settings.upStep)
        downSpeed = Settings.speed(fromStep: Settings.downStep)
        menuBar = Settings.menuBarEnabled
        claude = Settings.claudeEnabled
        slowerName = Settings.slowerCommand
        fasterName = Settings.fasterCommand
        launchAtLogin = SMAppService.mainApp.status == .enabled
        disabledTerminals = Settings.disabledTerminals
    }

    var namesValid: Bool {
        ClaudeCommands.isValid(slowerName) && ClaudeCommands.isValid(fasterName) && slowerName != fasterName
    }

    private func saveCommandNames() {
        guard namesValid else { return }
        Settings.slowerCommand = slowerName
        Settings.fasterCommand = fasterName
        ClaudeCommands.sync()
    }

    func applyExternalSteps(up: Double, down: Double) {
        upSpeed = Settings.speed(fromStep: up)
        downSpeed = Settings.speed(fromStep: down)
    }

    // Vérifie les autorisations régulièrement et démarre l'écoute dès que c'est possible.
    func startPolling() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        inputGranted = CGPreflightListenEventAccess()
        axGranted = AXIsProcessTrusted()
        if !monitorRunning, inputGranted || axGranted {
            monitorRunning = GestureMonitor.shared.start()
        }
    }

    func requestInput() {
        if !CGRequestListenEventAccess() { openPrivacy("Privacy_ListenEvent") }
    }

    func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(opts) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.axGranted == false { self?.openPrivacy("Privacy_Accessibility") }
            }
        }
    }

    func openPrivacy(_ anchor: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") {
            NSWorkspace.shared.open(url)
        }
    }

    func relaunch() {
        let path = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1; open \"\(path)\""]
        try? task.run()
        NSApp.terminate(nil)
    }
}

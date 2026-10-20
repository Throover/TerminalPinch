import Foundation

enum Settings {
    static let d = UserDefaults.standard
    static let changedNotification = Notification.Name("app.terminalpinch.settingsChanged")
    static let donationURL = "https://ko-fi.com/throover"

    // Quantité de pincement pour 1 point de police : plus grand = plus lent.
    static let minStep = 0.02, maxStep = 1.0
    static func clamp(_ v: Double) -> Double { min(max(v, minStep), maxStep) }

    static var upStep: Double {
        get { d.object(forKey: "upStep") as? Double ?? 0.15 }
        set { d.set(clamp(newValue), forKey: "upStep") }
    }
    static var downStep: Double {
        get { d.object(forKey: "downStep") as? Double ?? 0.30 }
        set { d.set(clamp(newValue), forKey: "downStep") }
    }

    // Conversion pas <-> vitesse affichée (0 = lent, 100 = rapide), échelle logarithmique.
    static func speed(fromStep s: Double) -> Double {
        log(clamp(s) / maxStep) / log(minStep / maxStep) * 100
    }
    static func step(fromSpeed v: Double) -> Double {
        clamp(maxStep * pow(minStep / maxStep, v / 100))
    }

    static var onboardingDone: Bool {
        get { d.bool(forKey: "onboardingDone") }
        set { d.set(newValue, forKey: "onboardingDone") }
    }
    static var menuBarEnabled: Bool {
        get { d.object(forKey: "menuBarEnabled") as? Bool ?? true }
        set { d.set(newValue, forKey: "menuBarEnabled") }
    }
    static var claudeEnabled: Bool {
        get { d.bool(forKey: "claudeEnabled") }
        set { d.set(newValue, forKey: "claudeEnabled") }
    }
    static var slowerCommand: String {
        get { d.string(forKey: "slowerCommand") ?? L.t("cmd.slower") }
        set { d.set(newValue, forKey: "slowerCommand") }
    }
    static var fasterCommand: String {
        get { d.string(forKey: "fasterCommand") ?? L.t("cmd.faster") }
        set { d.set(newValue, forKey: "fasterCommand") }
    }
    static var installedCommands: [String] {
        get { d.stringArray(forKey: "installedCommands") ?? [] }
        set { d.set(newValue, forKey: "installedCommands") }
    }
    static var disabledTerminals: Set<String> {
        get { Set(d.stringArray(forKey: "disabledTerminals") ?? []) }
        set { d.set(Array(newValue), forKey: "disabledTerminals") }
    }
}

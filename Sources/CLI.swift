import Foundation

enum CLI {
    static let factor = 1.3

    static func run(_ args: [String]) -> Int32 {
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
}

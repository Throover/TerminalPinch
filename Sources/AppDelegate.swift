import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var window: NSWindow?
    private let model = AppModel.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Changements faits par les commandes Claude Code pendant que l'app tourne.
        DistributedNotificationCenter.default().addObserver(
            forName: Settings.changedNotification, object: nil, queue: .main) { [weak self] note in
            guard let up = note.userInfo?["upStep"] as? Double,
                  let down = note.userInfo?["downStep"] as? Double else { return }
            self?.model.applyExternalSteps(up: up, down: down)
        }

        model.startPolling()
        ClaudeCommands.sync()   // remet à jour le chemin de l'app si elle a été déplacée
        updateStatusItem()

        if !Settings.onboardingDone { showOnboarding() }
    }

    // Rouvrir l'app (depuis Applications ou le Launchpad) affiche les réglages.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Settings.onboardingDone ? showSettings() : showOnboarding()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func showOnboarding() {
        show(OnboardingView(finish: { [weak self] in
            Settings.onboardingDone = true
            self?.window?.close()
        }), title: "TerminalPinch")
    }

    @objc func showSettings() {
        show(SettingsView(), title: L.t("settings.title"))
    }

    @objc func donate() {
        if let url = URL(string: Settings.donationURL) { NSWorkspace.shared.open(url) }
    }

    private func show<V: View>(_ view: V, title: String) {
        window?.close()
        let w = NSWindow(contentViewController: NSHostingController(rootView: view))
        w.title = title
        w.styleMask = [.titled, .closable]
        w.isReleasedWhenClosed = false
        w.center()
        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    func updateStatusItem() {
        guard Settings.menuBarEnabled else {
            if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
            statusItem = nil
            return
        }
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "hand.pinch", accessibilityDescription: "TerminalPinch")
            ?? NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "TerminalPinch")

        let menu = NSMenu()
        let sliders = NSMenuItem()
        let host = NSHostingView(rootView: SpeedSliders().padding(.horizontal, 14).padding(.vertical, 8))
        host.frame = NSRect(x: 0, y: 0, width: 280, height: 110)
        sliders.view = host
        menu.addItem(sliders)
        menu.addItem(.separator())
        menu.addItem(withTitle: L.t("menu.settings"), action: #selector(showSettings), keyEquivalent: ",").target = self
        if !Settings.donationURL.isEmpty {
            menu.addItem(withTitle: L.t("menu.donate"), action: #selector(donate), keyEquivalent: "").target = self
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: L.t("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }
}

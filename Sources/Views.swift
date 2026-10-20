import SwiftUI

// MARK: - Éléments communs

struct SpeedSliders: View {
    @ObservedObject var m = AppModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row(L.t("speed.up"), $m.upSpeed)
            row(L.t("speed.down"), $m.downSpeed)
        }
    }

    private func row(_ title: String, _ value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline)
            HStack(spacing: 6) {
                Image(systemName: "tortoise").foregroundStyle(.secondary).help(L.t("speed.slow"))
                Slider(value: value, in: 0...100)
                Image(systemName: "hare").foregroundStyle(.secondary).help(L.t("speed.fast"))
            }
        }
    }
}

struct PermissionRow: View {
    let title: String
    let detail: String
    let section: String
    let granted: Bool
    let request: () -> Void
    let open: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(granted ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                if granted {
                    Text(L.t("perm.granted")).foregroundStyle(.green)
                } else {
                    Button(L.t("perm.allow"), action: request).buttonStyle(.borderedProminent)
                }
            }
            if !granted {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.t("perm.popup")).font(.caption)
                    Text(L.f("perm.steps", section)).font(.caption).foregroundStyle(.secondary)
                    Button(L.t("perm.openSettings"), action: open).font(.caption)
                }
                .padding(.leading, 24)
            }
        }
    }
}

struct PermissionsSection: View {
    @ObservedObject var m = AppModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PermissionRow(title: L.t("perm.ax.title"), detail: L.t("perm.ax.desc"),
                          section: L.t("perm.ax.title"), granted: m.axGranted,
                          request: m.requestAccessibility, open: { m.openPrivacy("Privacy_Accessibility") })
            Text(L.t("perm.automation")).font(.caption).foregroundStyle(.secondary)
            if m.axGranted && !m.monitorRunning {
                HStack {
                    Text(L.t("perm.restart")).font(.caption)
                    Button(L.t("perm.relaunch"), action: m.relaunch).font(.caption)
                }
            }
        }
    }
}

struct ControlSection: View {
    @ObservedObject var m = AppModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(L.t("control.menubar"), isOn: $m.menuBar)
            Toggle(L.t("control.claude"), isOn: $m.claude)
                .disabled(!ClaudeCommands.claudeInstalled)
            if !ClaudeCommands.claudeInstalled {
                Text(L.t("control.claude.missing")).font(.caption).foregroundStyle(.secondary)
            } else if m.claude {
                VStack(alignment: .leading, spacing: 6) {
                    commandField(L.t("control.slowerName"), $m.slowerName)
                    commandField(L.t("control.fasterName"), $m.fasterName)
                    if m.namesValid {
                        Text(L.f("control.example", m.slowerName))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    } else {
                        Text(L.t("control.invalid")).font(.caption).foregroundStyle(.red)
                    }
                }
                .padding(.leading, 20)
            }
            if !m.menuBar {
                Text(L.t("finish.reopen")).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func commandField(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 190, alignment: .leading)
            Text("/").foregroundStyle(.secondary)
            TextField("", text: text).textFieldStyle(.roundedBorder).frame(width: 150)
        }
    }
}

struct TerminalsSection: View {
    @ObservedObject var m = AppModel.shared

    var body: some View {
        let list = Terminals.installed
        VStack(alignment: .leading, spacing: 6) {
            ForEach(list) { t in
                Toggle(t.name, isOn: Binding(
                    get: { !m.disabledTerminals.contains(t.id) },
                    set: { on in if on { m.disabledTerminals.remove(t.id) } else { m.disabledTerminals.insert(t.id) } }))
            }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @ObservedObject var m = AppModel.shared
    @State private var step = 0
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case 0: welcome
                case 1: page(L.t("perm.title"), L.t("perm.body")) { PermissionsSection() }
                case 2: page(L.t("control.title"), L.t("control.body")) {
                    VStack(alignment: .leading, spacing: 20) { SpeedSliders(); ControlSection() }
                }
                default: done
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(28)

            Divider()
            HStack {
                if step > 0 { Button(L.t("back")) { step -= 1 } }
                Spacer()
                if step == 1 && !m.axGranted {
                    Button(L.t("later")) { step += 1 }
                }
                if step < 3 {
                    Button(L.t("continue")) { step += 1 }
                        .keyboardShortcut(.defaultAction)
                        .disabled(step == 1 && !m.axGranted)
                } else {
                    Button(L.t("done"), action: finish).keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
        }
        .frame(width: 560, height: 600)
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 112, height: 112)
            Text(L.t("welcome.title")).font(.largeTitle).bold()
            Text(L.t("welcome.body")).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var done: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.t("finish.title")).font(.largeTitle).bold()
            Text(L.t("finish.body"))
            Toggle(L.t("finish.login"), isOn: $m.launchAtLogin)
            Text(L.t("finish.reopen")).font(.callout).foregroundStyle(.secondary)
            if let url = URL(string: Settings.donationURL), !Settings.donationURL.isEmpty {
                Link(L.t("menu.donate"), destination: url).font(.callout)
            }
        }
    }

    private func page<C: View>(_ title: String, _ body: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title).bold()
            Text(body).foregroundStyle(.secondary)
            content()
        }
    }
}

// MARK: - Réglages

struct SettingsView: View {
    @ObservedObject var m = AppModel.shared

    var body: some View {
        Form {
            Section(L.t("speed.title")) { SpeedSliders() }
            Section(L.t("perm.title")) { PermissionsSection() }
            Section(L.t("control.title")) { ControlSection() }
            Section(L.t("terminals.title")) { TerminalsSection() }
            Section {
                Toggle(L.t("finish.login"), isOn: $m.launchAtLogin)
                HStack {
                    if let url = URL(string: Settings.donationURL), !Settings.donationURL.isEmpty {
                        Link(L.t("menu.donate"), destination: url)
                    }
                    Spacer()
                    Button(L.t("menu.quit")) { NSApp.terminate(nil) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 680)
    }
}

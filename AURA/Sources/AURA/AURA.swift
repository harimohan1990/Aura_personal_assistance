import SwiftUI
import AppKit

@main
struct AURAApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Native macOS Top Menu Bar Companion Extra
        MenuBarExtra("AURA", systemImage: "sparkles") {
            VStack(alignment: .leading, spacing: 6) {
                Text("AURA AI Desktop Assistant")
                    .font(.headline)

                Divider()

                Button("Open AURA Dashboard") {
                    appDelegate.showMainWindow()
                }

                Button("📸 Take Screenshot") {
                    Task {
                        await BackendManager.shared.captureScreenshot()
                    }
                }

                Button("🔋 Check Battery Status") {
                    Task {
                        _ = await BackendManager.shared.executeCommand("battery status")
                    }
                }

                Divider()

                Button("Launch Google Chrome") {
                    Task { await BackendManager.shared.openApp("chrome") }
                }
                Button("Close Google Chrome") {
                    Task { await BackendManager.shared.closeApp("chrome") }
                }

                Button("Launch WhatsApp") {
                    Task { await BackendManager.shared.openApp("whatsapp") }
                }
                Button("Close WhatsApp") {
                    Task { await BackendManager.shared.closeApp("whatsapp") }
                }

                Divider()

                Button("Quit AURA") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

final class AURAWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMainMenu()
        showMainWindow()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // Application Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About AURA", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide AURA", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit AURA", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit Menu (Essential for TextFields: Cut, Copy, Paste, Select All)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Window Menu
        let winMenuItem = NSMenuItem()
        let winMenu = NSMenu(title: "Window")
        winMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        winMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        winMenu.addItem(NSMenuItem.separator())
        winMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        winMenuItem.submenu = winMenu
        mainMenu.addItem(winMenuItem)

        NSApp.mainMenu = mainMenu
    }

    func showMainWindow() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: ContentView())
        let win = AURAWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.minSize = NSSize(width: 380, height: 620)
        win.center()
        win.title = "AURA AI Assistant"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.contentViewController = hosting
        win.isReleasedWhenClosed = false
        win.backgroundColor = NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.10, alpha: 1.0)
        win.acceptsMouseMovedEvents = true
        win.makeKeyAndOrderFront(nil)
        win.makeKey()

        self.window = win
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideMainWindow() {
        if let existing = window {
            existing.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in Menu Bar when main window is closed
    }

    func applicationWillTerminate(_ notification: Notification) {
        BackendManager.shared.shutdown()
    }
}

// MARK: - Global Window & Lifecycle Control Helpers
@MainActor
public func auraOpenWindow() {
    if let delegate = NSApp.delegate as? AppDelegate {
        delegate.showMainWindow()
    } else {
        NSApp.unhide(nil)
        for win in NSApp.windows where win is AURAWindow {
            win.makeKeyAndOrderFront(nil)
            win.makeKey()
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
public func auraCloseWindow() {
    if let delegate = NSApp.delegate as? AppDelegate {
        delegate.hideMainWindow()
    } else {
        for win in NSApp.windows where win is AURAWindow {
            win.orderOut(nil)
        }
    }
}

@MainActor
public func auraQuitApp() {
    BackendManager.shared.shutdown()
    NSApplication.shared.terminate(nil)
}


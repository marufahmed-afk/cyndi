import SwiftUI
import AppKit
import Carbon.HIToolbox

@main
struct CyndiMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = Store()
    private var panel: NotchPanel!
    private var hosting: NSHostingView<RootOverlayView>?
    private var statusItem: NSStatusItem!
    private var showDotsItem: NSMenuItem!
    private var hotkey: Hotkey?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Fonts.register()
        setupStatusItem()
        setupPanel()
        layout()

        hotkey = Hotkey(keyCode: UInt32(kVK_Space),
                        modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.toggle()
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(otherAppActivated),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let cmd = event.modifierFlags.contains(.command)

            if cmd, event.keyCode == UInt16(kVK_ANSI_N) {
                self.newChecklist(); return nil
            }

            guard self.store.isOpen else { return event }

            if cmd {
                switch event.keyCode {
                case UInt16(kVK_ANSI_1): self.store.selectIndex(0); self.panel.makeKey(); return nil
                case UInt16(kVK_ANSI_2): self.store.selectIndex(1); self.panel.makeKey(); return nil
                case UInt16(kVK_ANSI_3): self.store.selectIndex(2); self.panel.makeKey(); return nil
                case UInt16(kVK_ANSI_4): self.store.selectIndex(3); self.panel.makeKey(); return nil
                case UInt16(kVK_ANSI_5): self.store.selectIndex(4); self.panel.makeKey(); return nil
                case UInt16(kVK_ANSI_6): self.store.selectIndex(5); self.panel.makeKey(); return nil
                case UInt16(kVK_Delete), UInt16(kVK_ForwardDelete):
                    self.deleteChecklist(); return nil
                default: return event
                }
            }

            switch event.keyCode {
            case UInt16(kVK_Escape):
                self.close(); return nil
            case UInt16(kVK_LeftArrow) where self.store.draft.isEmpty:
                self.step(-1); return nil
            case UInt16(kVK_RightArrow) where self.store.draft.isEmpty:
                self.step(1); return nil
            default:
                return event
            }
        }

        panel.present()
    }

    private func newChecklist() {
        store.newNote()
        if !store.isOpen {
            open()
        } else {
            panel.makeKey()
        }
    }

    private func deleteChecklist() {
        let hasRemaining = store.deleteActiveNote()
        if hasRemaining {
            panel.makeKey()
        } else {
            close()
        }
    }

    private func step(_ delta: Int) {
        let count = store.notes.count
        guard count > 0 else { return }
        let next = (store.activeIndex + delta + count) % count
        store.select(store.notes[next].id)
        panel.makeKey()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◗"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Cyndi (⌘⇧Space)", action: #selector(toggle), keyEquivalent: ""))
        menu.addItem(.separator())
        showDotsItem = NSMenuItem(title: "Show checklist dots", action: #selector(toggleShowDots), keyEquivalent: "")
        showDotsItem.state = store.showDots ? .on : .off
        menu.addItem(showDotsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        menu.items.last?.target = NSApp
        statusItem.menu = menu
    }

    private func setupPanel() {
        panel = NotchPanel(keyCapable: true)
        let band = NSScreen.screenWithMouse?.notchRect.height ?? 30
        let root = RootOverlayView(
            store: store,
            bandHeight: band,
            onTapDot: { [weak self] id in self?.tapDot(id) },
            onDelete: { [weak self] in self?.deleteChecklist() },
            onDimClick: { [weak self] in self?.close() })
        let hosting = NSHostingView(rootView: root)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear
        self.hosting = hosting
        panel.contentView = hosting
    }

    private func layout() {
        let band = NSScreen.screenWithMouse?.notchRect.height ?? 30
        hosting?.rootView = RootOverlayView(
            store: store,
            bandHeight: band,
            onTapDot: { [weak self] id in self?.tapDot(id) },
            onDelete: { [weak self] in self?.deleteChecklist() },
            onDimClick: { [weak self] in self?.close() })
        applyFrame()
    }

    private func applyFrame() {
        guard let screen = NSScreen.screenWithMouse else { return }
        if store.isOpen {
            panel.setFrame(screen.frame, display: true)
        } else {
            let band = screen.notchRect.height
            let bandFrame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - band,
                                   width: screen.frame.width, height: band)
            panel.setFrame(bandFrame, display: true)
        }
    }

    @objc private func screensChanged() { layout() }

    @objc private func otherAppActivated(_ note: Notification) {
        guard store.isOpen else { return }
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        if app?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            close()
        }
    }

    @objc private func toggle() {
        store.isOpen ? close() : open()
    }

    @objc private func toggleShowDots() {
        store.showDots.toggle()
        showDotsItem.state = store.showDots ? .on : .off
    }

    private func open() {
        if store.notes.isEmpty {
            store.newNote()
        }
        store.isOpen = true
        applyFrame()
        panel.present()
        panel.makeKey()
    }

    private func close() {
        store.isOpen = false
        store.draft = ""
        applyFrame()
        panel.resignKey()
    }

    private func tapDot(_ id: UUID) {
        if store.isOpen && store.activeNoteID == id {
            close()
        } else {
            store.select(id)
            if !store.isOpen { open() } else { panel.makeKey() }
        }
    }
}

import SwiftUI
import AppKit
import Combine
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
    private var dotsPanel: NotchPanel!
    private var editorPanel: NotchPanel!
    private var editorHosting: NSHostingView<EditorView>?
    private var dimWindow: NSWindow!
    private var statusItem: NSStatusItem!
    private var hotkey: Hotkey?
    private var keyMonitor: Any?
    private var storeObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Fonts.register()
        setupStatusItem()
        setupDim()
        setupDotsPanel()
        setupEditorPanel()
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

        storeObserver = store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, self.store.isOpen else { return }
                self.editorHosting?.layoutSubtreeIfNeeded()
                self.positionEditor()
            }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let cmd = event.modifierFlags.contains(.command)

            if cmd, event.keyCode == UInt16(kVK_ANSI_N) {
                self.newChecklist(); return nil
            }

            guard self.store.isOpen else { return event }

            if cmd {
                switch event.keyCode {
                case UInt16(kVK_ANSI_1): self.store.selectIndex(0); self.editorPanel.makeKey(); return nil
                case UInt16(kVK_ANSI_2): self.store.selectIndex(1); self.editorPanel.makeKey(); return nil
                case UInt16(kVK_ANSI_3): self.store.selectIndex(2); self.editorPanel.makeKey(); return nil
                case UInt16(kVK_ANSI_4): self.store.selectIndex(3); self.editorPanel.makeKey(); return nil
                case UInt16(kVK_ANSI_5): self.store.selectIndex(4); self.editorPanel.makeKey(); return nil
                case UInt16(kVK_ANSI_6): self.store.selectIndex(5); self.editorPanel.makeKey(); return nil
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

        dotsPanel.present()
    }

    private func newChecklist() {
        store.newNote()
        if !store.isOpen {
            open()
        } else {
            editorPanel.makeKey()
        }
    }

    private func deleteChecklist() {
        let hasRemaining = store.deleteActiveNote()
        if hasRemaining {
            editorPanel.makeKey()
        } else {
            close()
        }
    }

    private func step(_ delta: Int) {
        let count = store.notes.count
        guard count > 0 else { return }
        let next = (store.activeIndex + delta + count) % count
        store.select(store.notes[next].id)
        editorPanel.makeKey()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◗"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Cyndi (⌘⇧Space)", action: #selector(toggle), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        menu.items.last?.target = NSApp
        statusItem.menu = menu
    }

    private func setupDotsPanel() {
        dotsPanel = NotchPanel(keyCapable: false)
        let root = DotsView(store: store) { [weak self] id in self?.tapDot(id) }
        let hosting = NSHostingView(rootView: root)
        hosting.wantsLayer = true
        dotsPanel.contentView = hosting
    }

    private func setupEditorPanel() {
        editorPanel = NotchPanel(keyCapable: true)
        let band = NSScreen.screenWithMouse?.notchRect.height ?? 30
        let hosting = NSHostingView(rootView: EditorView(store: store, bandHeight: band, onDelete: { [weak self] in self?.deleteChecklist() }))
        hosting.sizingOptions = [.intrinsicContentSize]
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear
        editorHosting = hosting
        editorPanel.contentView = hosting
    }

    private func setupDim() {
        guard let screen = NSScreen.screenWithMouse else { return }
        dimWindow = NSWindow(contentRect: screen.frame, styleMask: .borderless,
                             backing: .buffered, defer: false)
        dimWindow.isOpaque = false
        dimWindow.backgroundColor = NSColor(red: 6/255, green: 9/255, blue: 11/255, alpha: 0.68)
        dimWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
        dimWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        dimWindow.ignoresMouseEvents = false
        dimWindow.isReleasedWhenClosed = false
        let click = NSClickGestureRecognizer(target: self, action: #selector(dimClicked))
        dimWindow.contentView?.addGestureRecognizer(click)
    }

    private func layout() {
        guard let screen = NSScreen.screenWithMouse else { return }
        let band = screen.notchRect.height
        let dotsFrame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - band,
                               width: screen.frame.width, height: band)
        dotsPanel.setFrame(dotsFrame, display: true)

        editorHosting?.rootView = EditorView(store: store, bandHeight: band, onDelete: { [weak self] in self?.deleteChecklist() })
        positionEditor()
        dimWindow?.setFrame(screen.frame, display: false)
    }

    private func positionEditor() {
        guard let screen = NSScreen.screenWithMouse else { return }
        let bleed = EditorView.shadowBleed
        let panelW: CGFloat = 420 + bleed.leading + bleed.trailing
        let totalH = max(editorHosting?.fittingSize.height ?? 0, 1)
        let top = screen.frame.maxY + bleed.top
        let ex = screen.frame.midX - panelW / 2
        editorPanel.setFrame(NSRect(x: ex, y: top - totalH, width: panelW, height: totalH), display: true)
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

    private func open() {
        if store.notes.isEmpty {
            store.newNote()
        }
        store.isOpen = true
        editorHosting?.layoutSubtreeIfNeeded()
        positionEditor()
        dimWindow?.orderFrontRegardless()
        editorPanel.present()
        editorPanel.makeKey()
        dotsPanel.orderFrontRegardless()
    }

    private func close() {
        dimWindow?.orderOut(nil)
        editorPanel.orderOut(nil)
        store.isOpen = false
        store.draft = ""
    }

    private func tapDot(_ id: UUID) {
        if store.isOpen && store.activeNoteID == id {
            close()
        } else {
            store.select(id)
            if !store.isOpen { open() } else { editorPanel.makeKey() }
        }
    }

    @objc private func dimClicked() { close() }
}

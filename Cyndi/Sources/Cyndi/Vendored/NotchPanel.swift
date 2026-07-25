import AppKit

final class NotchPanel: NSPanel {
    private let keyCapable: Bool

    init(keyCapable: Bool) {
        self.keyCapable = keyCapable
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { keyCapable }
    override var canBecomeMain: Bool { false }

    func present() {
        orderFrontRegardless()
    }
}

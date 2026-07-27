import AppKit

extension NSScreen {
    static var screenWithMouse: NSScreen? {
        let location = NSEvent.mouseLocation
        return screens.first { NSMouseInRect(location, $0.frame, false) } ?? .main
    }

    var hasNotch: Bool {
        auxiliaryTopLeftArea != nil && auxiliaryTopRightArea != nil
    }

    var menuBarHeight: CGFloat {
        let h = frame.maxY - visibleFrame.maxY
        return h > 0 ? h : 30
    }

    var notchWidth: CGFloat {
        if let l = auxiliaryTopLeftArea?.width, let r = auxiliaryTopRightArea?.width {
            return frame.width - l - r
        }
        return 196
    }

    var notchRect: NSRect {
        let width = notchWidth
        let height = hasNotch ? safeAreaInsets.top : menuBarHeight
        let x = frame.midX - width / 2
        let y = frame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
}

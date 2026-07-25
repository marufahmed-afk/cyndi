import SwiftUI

struct SketchRoundedRect: InsettableShape {
    var tl: CGSize, tr: CGSize, br: CGSize, bl: CGSize
    var inset: CGFloat = 0

    static let small = SketchRoundedRect(
        tl: .init(width: 6, height: 4), tr: .init(width: 4, height: 7),
        br: .init(width: 7, height: 4), bl: .init(width: 4, height: 6)
    )
    static let medium = SketchRoundedRect(
        tl: .init(width: 12, height: 8), tr: .init(width: 8, height: 13),
        br: .init(width: 14, height: 9), bl: .init(width: 9, height: 12)
    )

    func inset(by amount: CGFloat) -> SketchRoundedRect {
        var copy = self
        copy.inset += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        var p = Path()
        p.move(to: CGPoint(x: r.minX + tl.width, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - tr.width, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + tr.height),
                       control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - br.height))
        p.addQuadCurve(to: CGPoint(x: r.maxX - br.width, y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + bl.width, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - bl.height),
                       control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + tl.height))
        p.addQuadCurve(to: CGPoint(x: r.minX + tl.width, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

struct NotchPanelShape: Shape {
    var ear: CGFloat = 12
    var bottom: CGFloat = 20

    func path(in r: CGRect) -> Path {
        let e = ear
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + e))
        p.addQuadCurve(to: CGPoint(x: r.minX + e, y: r.minY + e),
                       control: CGPoint(x: r.minX + e, y: r.minY + e * 0.45))
        p.addLine(to: CGPoint(x: r.minX + e, y: r.maxY - bottom))
        p.addQuadCurve(to: CGPoint(x: r.minX + e + bottom, y: r.maxY),
                       control: CGPoint(x: r.minX + e, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - e - bottom, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - e, y: r.maxY - bottom),
                       control: CGPoint(x: r.maxX - e, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - e, y: r.minY + e))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + e),
                       control: CGPoint(x: r.maxX - e, y: r.minY + e * 0.45))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

struct WobblingTick: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 16
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * s, y: rect.minY + y * s)
        }
        var p = Path()
        p.move(to: pt(2.6, 8.9))
        p.addCurve(to: pt(6.2, 13.4), control1: pt(4.2, 10.2), control2: pt(5.1, 11.6))
        p.addCurve(to: pt(14, 1.9), control1: pt(8.1, 8.9), control2: pt(10.4, 5.2))
        return p
    }
}

struct CrownStroke: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 20, sy = rect.height / 8
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var p = Path()
        p.move(to: pt(1.5, 6.4))
        p.addCurve(to: pt(18.4, 6.1), control1: pt(6, 6.9), control2: pt(13.5, 6.6))
        return p
    }
}

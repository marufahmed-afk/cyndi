import SwiftUI

struct FillingDot: View {
    let color: Color
    let completion: Double
    let diameter: CGFloat
    let dimmed: Bool

    init(color: Color, completion: Double, diameter: CGFloat = 15, dimmed: Bool = false) {
        self.color = color
        self.completion = completion
        self.diameter = diameter
        self.dimmed = dimmed
    }

    var body: some View {
        ZStack {
            Circle().fill(Ink.white(0.09))
            Circle()
                .fill(color)
                .mask(alignment: .bottom) {
                    Rectangle().frame(height: diameter * completion)
                }
            Circle().strokeBorder(dimmed ? Ink.white(0.35) : color, lineWidth: 1.4)
        }
        .frame(width: diameter, height: diameter)
        .opacity(dimmed ? 0.4 : 1)
    }
}

struct DotsView: View {
    @ObservedObject var store: Store
    let onTapNote: (UUID) -> Void

    private var notchHalf: CGFloat { 110 }
    private var gap: CGFloat { 10 }
    private var leftCapacity: Int { 3 }

    var body: some View {
        GeometryReader { geo in
            let center = geo.size.width / 2
            let visible = Array(store.notes.prefix(6))
            let leftNotes = Array(visible.prefix(leftCapacity))
            let rightNotes = Array(visible.dropFirst(leftCapacity))

            ZStack(alignment: .topLeading) {
                dotGroup(leftNotes.reversed(), anchorX: center - notchHalf, rightToLeft: true, height: geo.size.height)
                dotGroup(rightNotes, anchorX: center + notchHalf, rightToLeft: false, height: geo.size.height)
            }
        }
    }

    private func dotGroup(_ notes: [Note], anchorX: CGFloat, rightToLeft: Bool, height: CGFloat) -> some View {
        let hit: CGFloat = 20
        return ForEach(Array(notes.enumerated()), id: \.element.id) { idx, note in
            let offset = CGFloat(idx) * (hit + gap - 5)
            let x = rightToLeft ? anchorX - hit - offset : anchorX + offset
            dot(note)
                .frame(width: hit, height: height)
                .position(x: x + hit / 2, y: height / 2)
        }
    }

    private func dot(_ note: Note) -> some View {
        let selected = store.isOpen && note.id == store.activeNoteID
        return ZStack {
            FillingDot(color: note.color.color, completion: note.completion,
                       dimmed: store.isOpen && !selected)
            if selected {
                CrownStroke()
                    .stroke(note.color.color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 18, height: 8)
                    .offset(y: 13)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTapNote(note.id) }
    }
}

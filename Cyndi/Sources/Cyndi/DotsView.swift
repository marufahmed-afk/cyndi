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

    private var gap: CGFloat { 10 }
    private var hit: CGFloat { 20 }
    private var leftInset: CGFloat { 20 }
    private var maxVisible: Int { 6 }

    private var step: CGFloat { hit + gap - 5 }

    var body: some View {
        GeometryReader { geo in
            let overflow = max(0, store.notes.count - maxVisible)
            let visible = Array(store.notes.suffix(maxVisible))

            ZStack(alignment: .topLeading) {
                if overflow > 0 {
                    overflowPill(overflow)
                        .frame(width: hit, height: geo.size.height)
                        .position(x: leftInset + hit / 2, y: geo.size.height / 2)
                }
                ForEach(Array(visible.enumerated()), id: \.element.id) { idx, note in
                    let slot = overflow > 0 ? idx + 1 : idx
                    let x = leftInset + CGFloat(slot) * step
                    dot(note)
                        .frame(width: hit, height: geo.size.height)
                        .position(x: x + hit / 2, y: geo.size.height / 2)
                }
            }
        }
    }

    private func overflowPill(_ count: Int) -> some View {
        Text("+\(count)")
            .font(Fonts.kalam(11))
            .foregroundStyle(Ink.white(0.55))
            .frame(width: hit, height: 15)
            .background(Capsule().fill(Ink.white(0.09)))
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

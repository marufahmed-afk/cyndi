import SwiftUI

struct HandCheckbox: View {
    let item: ChecklistItem
    let color: Color
    let rotation: Double

    var body: some View {
        SketchRoundedRect.small
            .strokeBorder(item.done ? color : Ink.white(0.50), lineWidth: 1.5)
            .background(SketchRoundedRect.small.fill(item.done ? Ink.white(0.05) : .clear))
            .frame(width: 17, height: 17)
            .overlay {
                if item.done {
                    WobblingTick()
                        .stroke(color, style: StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round))
                        .frame(width: 16, height: 16)
                }
            }
            .rotationEffect(.degrees(rotation))
    }
}

struct EditorView: View {
    @ObservedObject var store: Store
    var bandHeight: CGFloat
    var onDelete: () -> Void = {}
    @FocusState private var fieldFocused: Bool

    private var note: Note { store.activeNote }

    private let sideMargin: CGFloat = 12

    var body: some View {
        panel
            .frame(width: 420 + sideMargin * 2, alignment: .center)
            .padding(.top, bandHeight)
            .background(
                Ink.panelBlack.clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 5, bottomLeadingRadius: 20,
                        bottomTrailingRadius: 20, topTrailingRadius: 5,
                        style: .continuous)
                )
            )
            .fixedSize()
            .shadow(color: .black.opacity(0.6), radius: 25, x: 0, y: 26)
            .onAppear { fieldFocused = true }
            .onChange(of: store.activeNoteID) { fieldFocused = true }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            positionLine
            ForEach(Array(note.items.enumerated()), id: \.element.id) { idx, item in
                itemRow(item, index: idx)
            }
            draftRow
            progressBar
            footer
        }
        .padding(EdgeInsets(top: 18, leading: 20, bottom: 15, trailing: 20))
        .frame(width: 420, alignment: .leading)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            FillingDot(color: note.color.color, completion: note.completion, diameter: 11)
                .alignmentGuide(.firstTextBaseline) { $0.height - 2 }
            Text(note.title)
                .font(Fonts.caveat(28))
                .foregroundStyle(Ink.primary)
            Spacer()
            Text("\(note.doneCount)/\(note.items.count)")
                .font(Fonts.kalam(12))
                .foregroundStyle(Ink.white(0.45))
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.white(0.35))
            }
            .buttonStyle(.plain)
            .help("Delete this checklist (⌘⌫)")
        }
        .padding(.bottom, 4)
    }

    private var positionLine: some View {
        Text("note \(store.activeIndex + 1) of \(store.notes.count) · last touched first")
            .font(Fonts.kalam(11.5))
            .foregroundStyle(Ink.white(0.30))
            .padding(.bottom, 8)
    }

    private func itemRow(_ item: ChecklistItem, index: Int) -> some View {
        let rot = (Double(index % 3) - 1) * 1.5
        return HStack(spacing: 11) {
            HandCheckbox(item: item, color: note.color.color, rotation: rot)
            Text(item.text)
                .font(Fonts.kalam(17))
                .foregroundStyle(item.done ? Ink.white(0.40) : Ink.primary)
                .strikethrough(item.done, color: Ink.white(0.40))
            Spacer()
        }
        .frame(height: 34)
        .contentShape(Rectangle())
        .onTapGesture { store.toggleItem(noteID: note.id, itemID: item.id) }
    }

    private var draftRow: some View {
        HStack(spacing: 11) {
            SketchRoundedRect.small
                .strokeBorder(Ink.white(0.28), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: 17, height: 17)
                .rotationEffect(.degrees(-1.4))
            ZStack(alignment: .leading) {
                if store.draft.isEmpty {
                    Text("start typing…")
                        .font(Fonts.kalam(17))
                        .foregroundStyle(Ink.white(0.30))
                }
                TextField("", text: $store.draft)
                    .textFieldStyle(.plain)
                    .font(Fonts.kalam(17))
                    .foregroundStyle(Ink.primary)
                    .focused($fieldFocused)
                    .onSubmit { store.commitDraft(); fieldFocused = true }
            }
            Spacer()
        }
        .frame(height: 34)
    }

    private var progressBar: some View {
        SketchRoundedRect.small
            .strokeBorder(Ink.white(0.24), lineWidth: 1.3)
            .background(
                GeometryReader { g in
                    note.color.color
                        .frame(width: g.size.width * note.completion)
                        .clipShape(SketchRoundedRect.small)
                }
            )
            .frame(height: 7)
            .padding(.top, 13)
    }

    private var footer: some View {
        HStack {
            Text("↵ new item · ← → switch · ⌘N new · ⌘⌫ delete")
            Spacer()
            Text("⌘⇧Space to close · saved locally")
        }
        .font(Fonts.kalam(11.5))
        .foregroundStyle(Ink.white(0.40))
        .padding(.top, 12)
    }
}

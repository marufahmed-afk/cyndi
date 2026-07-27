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

    enum Field: Hashable {
        case title
        case item(UUID)
        case draft
    }

    @State private var focus: Field?
    @FocusState private var titleFocused: Bool

    private var note: Note { store.activeNote ?? Note(title: "", colorID: NoteColor.printYellow.id, items: []) }

    private var titleBinding: Binding<String> {
        Binding(
            get: { store.activeNote?.title ?? "" },
            set: { store.setTitle($0, noteID: note.id) }
        )
    }

    static let flare: CGFloat = 13
    static let notchRadius: CGFloat = 13
    static let panelWidth: CGFloat = 420
    static let shadowBleed = EdgeInsets(top: 0, leading: 55, bottom: 55, trailing: 55)

    var body: some View {
        VStack(spacing: 0) {
            Ink.panelBlack.frame(width: Self.panelWidth, height: bandHeight)
            if store.activeNote != nil {
                panel
            }
        }
        .clipShape(editorShape)
        .shadow(color: .black.opacity(0.5), radius: 22, x: 0, y: 10)
        .padding(Self.shadowBleed)
        .onAppear { focus = .draft }
        .onChange(of: store.activeNoteID) { focus = .draft }
        .onChange(of: focus) {
            titleFocused = (focus == .title)
            if case .item = focus { store.editingItem = true } else { store.editingItem = false }
        }
        .onChange(of: titleFocused) {
            if titleFocused { focus = .title }
        }
    }

    private var editorShape: NotchPanelShape {
        NotchPanelShape(flare: Self.flare, radius: Self.notchRadius)
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
        .padding(EdgeInsets(top: 18, leading: 20 + Self.flare, bottom: 15, trailing: 20 + Self.flare))
        .frame(width: Self.panelWidth, alignment: .leading)
        .background(Ink.panelBlack)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            FillingDot(color: note.color.color, completion: note.completion, diameter: 11)
                .alignmentGuide(.firstTextBaseline) { $0.height - 2 }
            ZStack(alignment: .leading) {
                if (store.activeNote?.title ?? "").isEmpty {
                    Text("untitled")
                        .font(Fonts.caveat(28))
                        .foregroundStyle(Ink.white(0.30))
                }
                TextField("", text: titleBinding)
                    .textFieldStyle(.plain)
                    .font(Fonts.caveat(28))
                    .foregroundStyle(Ink.primary)
                    .focused($titleFocused)
                    .onSubmit { focus = firstFieldAfterTitle }
            }
            .fixedSize(horizontal: false, vertical: true)
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
        Text("note \(store.activeIndex + 1) of \(store.notes.count) · newest on the right")
            .font(Fonts.kalam(11.5))
            .foregroundStyle(Ink.white(0.30))
            .padding(.bottom, 8)
    }

    private func itemRow(_ item: ChecklistItem, index: Int) -> some View {
        let rot = (Double(index % 3) - 1) * 1.5
        return HStack(spacing: 11) {
            HandCheckbox(item: item, color: note.color.color, rotation: rot)
                .contentShape(Rectangle())
                .onTapGesture { store.toggleItem(noteID: note.id, itemID: item.id) }
            EditableItemField(
                text: itemTextBinding(item),
                isFocused: focus == .item(item.id),
                font: Fonts.kalamNS(17),
                textColor: NSColor(item.done ? Ink.white(0.40) : Ink.primary),
                strikethrough: item.done,
                placeholder: "",
                placeholderColor: NSColor(Ink.white(0.30)),
                onFocus: { focus = .item(item.id) },
                onSubmit: { addItem(after: item.id) },
                onMoveUp: { focus = fieldBefore(.item(item.id)) },
                onMoveDown: { focus = fieldAfter(.item(item.id)) },
                onDeleteWhenEmpty: { deleteItem(item.id) }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 34)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(rowHighlight(focus == .item(item.id)))
        .padding(.horizontal, -6)
        .padding(.vertical, -1)
    }

    private func rowHighlight(_ active: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Ink.white(active ? 0.05 : 0))
    }

    private func itemTextBinding(_ item: ChecklistItem) -> Binding<String> {
        Binding(
            get: { store.activeNote?.items.first { $0.id == item.id }?.text ?? "" },
            set: { store.setItemText($0, noteID: note.id, itemID: item.id) }
        )
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
                        .allowsHitTesting(false)
                }
                EditableItemField(
                    text: $store.draft,
                    isFocused: focus == .draft,
                    font: Fonts.kalamNS(17),
                    textColor: NSColor(Ink.primary),
                    strikethrough: false,
                    placeholder: "",
                    placeholderColor: NSColor(Ink.white(0.30)),
                    clearOnSubmit: true,
                    onFocus: { focus = .draft },
                    onSubmit: { store.commitDraft(); focus = .draft },
                    onMoveUp: { focus = fieldBefore(.draft) },
                    onMoveDown: {},
                    onDeleteWhenEmpty: {}
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 34)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(rowHighlight(focus == .draft))
        .padding(.horizontal, -6)
        .padding(.vertical, -1)
    }

    private var firstFieldAfterTitle: Field {
        if let first = note.items.first { return .item(first.id) }
        return .draft
    }

    private func fieldBefore(_ field: Field) -> Field {
        let items = note.items
        switch field {
        case .title:
            return .title
        case .item(let id):
            guard let idx = items.firstIndex(where: { $0.id == id }) else { return .title }
            return idx > 0 ? .item(items[idx - 1].id) : .title
        case .draft:
            return items.last.map { .item($0.id) } ?? .title
        }
    }

    private func fieldAfter(_ field: Field) -> Field {
        let items = note.items
        switch field {
        case .title:
            return firstFieldAfterTitle
        case .item(let id):
            guard let idx = items.firstIndex(where: { $0.id == id }) else { return .draft }
            return idx < items.count - 1 ? .item(items[idx + 1].id) : .draft
        case .draft:
            return .draft
        }
    }

    private func addItem(after itemID: UUID) {
        if let newID = store.insertItem(after: itemID, noteID: note.id) {
            focus = .item(newID)
        }
    }

    private func deleteItem(_ itemID: UUID) {
        let target = fieldBefore(.item(itemID))
        store.deleteItem(noteID: note.id, itemID: itemID)
        focus = target
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

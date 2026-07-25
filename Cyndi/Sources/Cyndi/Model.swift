import SwiftUI

struct NoteColor: Identifiable, Hashable {
    let id: String
    let color: Color

    static let printYellow = NoteColor(id: "yellow", color: Color(hex: 0xF2C200))
    static let processCyan = NoteColor(id: "cyan", color: Color(hex: 0x0088B0))
    static let processMagenta = NoteColor(id: "magenta", color: Color(hex: 0xD6006C))
    static let green = NoteColor(id: "green", color: Color(hex: 0x4F9D69))
    static let violet = NoteColor(id: "violet", color: Color(hex: 0x7B5EA7))

    static let palette: [NoteColor] = [printYellow, processCyan, processMagenta, green, violet]
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    var text: String
    var done: Bool = false
}

struct Note: Identifiable {
    let id = UUID()
    var title: String
    var color: NoteColor
    var items: [ChecklistItem]

    var completion: Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.filter(\.done).count) / Double(items.count)
    }

    var doneCount: Int { items.filter(\.done).count }
}

@MainActor
final class Store: ObservableObject {
    @Published var notes: [Note]
    @Published var activeNoteID: UUID
    @Published var isOpen: Bool = false
    @Published var draft: String = ""

    init() {
        let seed = [
            Note(title: "spike", color: .printYellow, items: [
                ChecklistItem(text: "dots hug the notch", done: true),
                ChecklistItem(text: "expand from the notch", done: true),
                ChecklistItem(text: "one editable note", done: false)
            ]),
            Note(title: "groceries", color: .processCyan, items: [
                ChecklistItem(text: "oat milk", done: false),
                ChecklistItem(text: "coffee", done: true)
            ]),
            Note(title: "ideas", color: .processMagenta, items: [])
        ]
        notes = seed
        activeNoteID = seed[0].id
    }

    var activeIndex: Int { notes.firstIndex { $0.id == activeNoteID } ?? 0 }
    var activeNote: Note? { notes.first { $0.id == activeNoteID } }

    func select(_ id: UUID) {
        activeNoteID = id
        draft = ""
    }

    func selectIndex(_ index: Int) {
        guard notes.indices.contains(index) else { return }
        select(notes[index].id)
    }

    @discardableResult
    func newNote() -> UUID {
        let color = NoteColor.palette[notes.count % NoteColor.palette.count]
        let note = Note(title: "untitled", color: color, items: [])
        notes.insert(note, at: 0)
        activeNoteID = note.id
        draft = ""
        return note.id
    }

    @discardableResult
    func deleteActiveNote() -> Bool {
        guard notes.count > 0 else { return false }
        let idx = activeIndex
        notes.remove(at: idx)
        draft = ""
        guard !notes.isEmpty else { return false }
        let next = min(idx, notes.count - 1)
        activeNoteID = notes[next].id
        return true
    }

    func toggleItem(noteID: UUID, itemID: UUID) {
        guard let n = notes.firstIndex(where: { $0.id == noteID }),
              let i = notes[n].items.firstIndex(where: { $0.id == itemID }) else { return }
        notes[n].items[i].done.toggle()
    }

    func commitDraft() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !notes.isEmpty else { return }
        notes[activeIndex].items.append(ChecklistItem(text: text))
        draft = ""
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum Ink {
    static let panelBlack = Color(hex: 0x05080A)
    static let primary = Color(hex: 0xF3F2F2)
    static func white(_ a: Double) -> Color { Color(hex: 0xF3F2F2, alpha: a) }
}

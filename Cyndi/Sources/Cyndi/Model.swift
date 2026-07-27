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

    static func named(_ id: String) -> NoteColor {
        palette.first { $0.id == id } ?? printYellow
    }
}

struct ChecklistItem: Identifiable, Codable {
    var id = UUID()
    var text: String
    var done: Bool = false
}

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var colorID: String
    var items: [ChecklistItem]

    var color: NoteColor { NoteColor.named(colorID) }

    var completion: Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.filter(\.done).count) / Double(items.count)
    }

    var doneCount: Int { items.filter(\.done).count }
}

@MainActor
final class Store: ObservableObject {
    @Published var notes: [Note] { didSet { persist() } }
    @Published var activeNoteID: UUID
    @Published var isOpen: Bool = false
    @Published var draft: String = ""
    @Published var editingItem: Bool = false
    @Published var showDots: Bool {
        didSet { UserDefaults.standard.set(showDots, forKey: Self.showDotsKey) }
    }

    private let storage = NoteStorage()
    private static let showDotsKey = "showDots"

    init() {
        let loaded = storage.load()
        notes = loaded
        activeNoteID = loaded.last?.id ?? UUID()
        let defaults = UserDefaults.standard
        showDots = defaults.object(forKey: Self.showDotsKey) as? Bool ?? true
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
        let note = Note(title: "untitled", colorID: color.id, items: [])
        notes.append(note)
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

    func setTitle(_ title: String, noteID: UUID) {
        guard let n = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[n].title = title
    }

    func toggleItem(noteID: UUID, itemID: UUID) {
        guard let n = notes.firstIndex(where: { $0.id == noteID }),
              let i = notes[n].items.firstIndex(where: { $0.id == itemID }) else { return }
        notes[n].items[i].done.toggle()
    }

    func setItemText(_ text: String, noteID: UUID, itemID: UUID) {
        guard let n = notes.firstIndex(where: { $0.id == noteID }),
              let i = notes[n].items.firstIndex(where: { $0.id == itemID }) else { return }
        notes[n].items[i].text = text
    }

    func deleteItem(noteID: UUID, itemID: UUID) {
        guard let n = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[n].items.removeAll { $0.id == itemID }
    }

    @discardableResult
    func insertItem(after itemID: UUID?, noteID: UUID) -> UUID? {
        guard let n = notes.firstIndex(where: { $0.id == noteID }) else { return nil }
        let item = ChecklistItem(text: "")
        if let itemID, let i = notes[n].items.firstIndex(where: { $0.id == itemID }) {
            notes[n].items.insert(item, at: i + 1)
        } else {
            notes[n].items.append(item)
        }
        return item.id
    }

    func commitDraft() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !notes.isEmpty else { return }
        notes[activeIndex].items.append(ChecklistItem(text: text))
        draft = ""
    }

    private func persist() { storage.save(notes) }
}

struct NoteStorage {
    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cyndi", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("notes.json")
    }

    func load() -> [Note] {
        guard let data = try? Data(contentsOf: fileURL),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else { return [] }
        return notes
    }

    func save(_ notes: [Note]) {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: fileURL, options: .atomic)
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
    static let dimColor = Color(hex: 0x06090B, alpha: 0.68)
    static func white(_ a: Double) -> Color { Color(hex: 0xF3F2F2, alpha: a) }
}

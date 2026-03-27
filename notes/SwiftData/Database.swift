internal import Combine
import Foundation
import SwiftData

@MainActor
final class Database: ObservableObject {
    static let shared = Database()

    @Published var notes: [Note] = []
    @Published var removedNotes: [Note] = []
    private var context: ModelContext?

    var editingNote: Note?

    @Published var removedOnServerNotes: [Note] = []

    init() {}

    func run(context: ModelContext) {
        self.context = context
        DispatchQueue.main.async {
            _ = self.fetchAllNotes()
        }
    }

    func fetchAllNotes() -> [Note] {
        do {
            let fetchDescriptor = FetchDescriptor<Note>(sortBy: [
                SortDescriptor(\.idx, order: .forward)
            ])
            let allNotes = try context!.fetch(fetchDescriptor)
            for note in allNotes {
                if note.removeTime > 0 {
                    if note.removeTime < Time.getCurrentTime() {
                        _ = delete(note)
                    } else {
                        removedNotes.append(note)
                    }
                } else {
                    notes.append(note)
                }
            }
            notes.sort { $0.idx < $1.idx }
            for i in notes.indices {
                notes[i].idx = Int32(i) * 100000
                print(notes[i].toString())
            }
            for note in removedNotes {
                print(note.toString())
            }
            return notes
        } catch {
            Message.shared.showError("Unexpected error: (\(20))")
            return []
        }
    }

    func create(_ note: Note) -> Bool {
        do {
            context!.insert(note)
            note.idx = getLastIdx()
            try context!.save()
            notes.append(note)
            return true
        } catch {
            return false
        }
    }

    func createFromApiNote(_ apiNote: ApiNote) -> Bool {
        do {
            let note = Note(
                title: apiNote.title ?? "",
                content: apiNote.content ?? "",
                mongoId: apiNote.mongoId,
                version: Int32(apiNote.version),
                idx: Int32(notes.count * 100000),
                removeTime: 0,
                isRemovedFromServer: false,
                userId: AuthManager.shared.getUserId(),
                isEncrypted: apiNote.isEncrypted ?? false
            )
            context!.insert(note)
            note.idx = getLastIdx()
            try context!.save()
            notes.append(note)
            return true
        } catch {
            return false
        }
    }

    func save(_ note: Note) -> Bool {
        if note == editingNote { return false }
        do {
            context!.insert(note)
            try context!.save()
            return true
        } catch {
            return false
        }
    }

    func moveToTrash(_ note: Note) -> Bool {
        if note == editingNote { return false }
        do {
            note.removeTime = Time.getDeletingTime()
            note.isRemovedFromServer = false
            try context!.save()
            DispatchQueue.main.async {
                if let index = self.notes.firstIndex(where: { $0.id == note.id }
                ) {
                    self.notes.remove(at: index)
                    self.removedNotes.append(note)
                }
            }
            Task {
                await SyncQueue.shared.add(note)
            }
            return true
        } catch {
            return false
        }
    }

    func delete(_ note: Note) -> Bool {
        if note == editingNote { return false }
        do {
            if note.isRemovedFromServer {
                context!.delete(note)
            } else {
                note.removeTime =
                    Time.getCurrentTime() - 7 * 24 * 60 * 60 * 1000

            }
            try context!.save()
            DispatchQueue.main.async {
                if let index = self.removedNotes.firstIndex(where: {
                    $0.id == note.id
                }
                ) {
                    self.removedNotes.remove(at: index)
                }
            }
            return true
        } catch {
            return false
        }
    }

    func move(fromIndex: Int, toIndex: Int) {
        if fromIndex < toIndex {
            for index in fromIndex..<toIndex {
                swap(index, index + 1)
            }
        } else {
            for index in stride(
                from: fromIndex,
                to: toIndex,
                by: -1
            ) {
                swap(index, index - 1)
            }
        }
    }

    func swap(_ fromIndex: Int, _ toIndex: Int) {
        let a = notes[fromIndex]
        let b = notes[toIndex]
        let temp = a.idx
        a.idx = b.idx
        b.idx = temp
        _ = save(a)
        _ = save(b)
        notes[fromIndex] = b
        notes[toIndex] = a
    }

    func restoreFromTrash(_ note: Note) -> Bool {
        if note == editingNote { return false }
        do {
            note.removeTime = 0
            note.idx = getLastIdx()
            try context!.save()
            DispatchQueue.main.async {
                if let index = self.removedNotes.firstIndex(where: {
                    $0.id == note.id
                }
                ) {
                    self.removedNotes.remove(at: index)
                    self.notes.append(note)
                }
            }
            return true
        } catch {
            return false
        }
    }

    func getLastIdx() -> Int32 {
        return Int32(notes.count * 100_000)
    }

    func getNoteIdxById(_ id: String) -> Int {
        if let index = self.notes.firstIndex(where: {
            $0.id.uuidString == id
        }) {
            return index
        }
        return -1
    }

    func getNoteById(_ id: String) -> Note? {
        if let index = self.notes.firstIndex(where: {
            $0.id.uuidString == id
        }) {
            return notes[index]
        }
        return nil
    }

    func getNoteByMongoId(_ mongoId: String) -> Note? {
        if let index = self.notes.firstIndex(where: {
            $0.mongoId == mongoId
        }) {
            return notes[index]
        }
        return nil
    }

    func getRemovedNoteByMongoId(_ mongoId: String) -> Note? {
        if let index = self.removedNotes.firstIndex(where: {
            $0.mongoId == mongoId
        }) {
            return removedNotes[index]
        }
        return nil
    }

    func deletedNoteFromApi(_ mongoId: String) {
        if let note = getRemovedNoteByMongoId(
            mongoId
        ) {
            note.mongoId = ""
            note.isRemovedFromServer = true
            _ = save(note)
            if Time.getCurrentTime() >= note.removeTime {
                _ = delete(note)
            }
            Message.shared.show("Note removed to trash", duration: 2)
        }
    }

    func compareNoteAndUpdateWithSameMongoId(_ note: Note, _ apiNote: ApiNote) {
        if note.removeTime != 0 {
            Task { await SyncQueue.shared.add(note) }
        } else if note.version > apiNote.version {
            Task { await SyncQueue.shared.add(note) }
        } else if note.version < apiNote.version {
            note.title = apiNote.title ?? ""
            note.content = apiNote.content ?? ""
            note.version = Int32(apiNote.version)
            _ = save(note)
        } else if !note.equals(apiNote) {
            _ = createFromApiNote(apiNote)
            note.mongoId = ""
            _ = save(note)
            Task { await SyncQueue.shared.add(note) }
        }
    }

    func updateNoteWithoutTitleAndContents(_ apiNotes: [ApiNote]) {
        Task {
            await SyncQueue.shared.setIsUpdatingNotesFromApi(true)
            var mongoIdToNotes: [String: Note] = [:]

            for note in notes {
                if note.userId.isEmpty {
                    note.userId = AuthManager.shared.getUserId()
                    _ = save(note)
                } else if note.userId != AuthManager.shared.getUserId() {
                    continue
                }

                if note.mongoId.isEmpty {
                    await SyncQueue.shared.add(note)
                } else {
                    mongoIdToNotes[note.mongoId] = note
                }
            }

            for note in removedNotes {
                if note.userId.isEmpty {
                    note.userId = AuthManager.shared.getUserId()
                    _ = save(note)
                } else if note.userId != AuthManager.shared.getUserId() {
                    continue
                }

                if !note.mongoId.isEmpty {
                    mongoIdToNotes[note.mongoId] = note
                }
            }

            for apiNote in apiNotes {
                if let note = mongoIdToNotes[apiNote.mongoId] {
                    if note.version != apiNote.version || note.removeTime != 0 {
                        await SyncQueue.shared.add(note)
                    }
                    mongoIdToNotes.removeValue(forKey: note.mongoId)
                } else {
                    await SyncQueue.shared.add(apiNote.mongoId)
                }
            }

            for note in mongoIdToNotes.values {
                if note.removeTime == 0 {
                    removedOnServerNotes.append(note)
                } else {
                    note.mongoId = ""
                    note.isRemovedFromServer = true
                    _ = save(note)
                }
            }
            await SyncQueue.shared.setIsUpdatingNotesFromApi(false)
        }
    }

    func setNoteAsRemovedOnServer(_ note: Note, _ isConfirmedToRemove: Bool) {
        if isConfirmedToRemove {
            _ = self.moveToTrash(note)
        } else if note.userId == AuthManager.shared.getUserId() {
            note.mongoId = ""
            _ = save(note)
            Task {
                await SyncQueue.shared.add(note)
            }
        }
        removedOnServerNotes.removeAll { $0.id == note.id }
    }

    func updateNote(_ apiNotes: [ApiNote]) {
        Task {
            await SyncQueue.shared.setIsUpdatingNotesFromApi(true)
            var mongoIdToNotes: [String: Note] = [:]

            for note in notes {
                if note.userId.isEmpty {
                    note.userId = AuthManager.shared.getUserId()
                    _ = save(note)
                } else if note.userId != AuthManager.shared.getUserId() {
                    continue
                }

                if note.mongoId.isEmpty {
                    await SyncQueue.shared.add(note)
                } else {
                    mongoIdToNotes[note.mongoId] = note
                }
            }

            for note in removedNotes {
                if note.userId.isEmpty {
                    note.userId = AuthManager.shared.getUserId()
                    _ = save(note)
                } else if note.userId != AuthManager.shared.getUserId() {
                    continue
                }

                if !note.mongoId.isEmpty {
                    mongoIdToNotes[note.mongoId] = note
                }
            }

            for apiNote in apiNotes {
                if let note = mongoIdToNotes[apiNote.mongoId] {
                    compareNoteAndUpdateWithSameMongoId(note, apiNote)
                    mongoIdToNotes.removeValue(forKey: apiNote.mongoId)
                } else {
                    _ = createFromApiNote(apiNote)
                }
            }

            for note in mongoIdToNotes.values {
                if note.removeTime == 0 {
                    removedOnServerNotes.append(note)
                } else {
                    note.mongoId = ""
                    note.isRemovedFromServer = true
                    _ = save(note)
                }
            }
            await SyncQueue.shared.setIsUpdatingNotesFromApi(false)
        }
    }
}

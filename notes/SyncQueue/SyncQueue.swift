import Foundation

actor SyncQueue {
    static let shared = SyncQueue()
    var queue = [String]()
    var hm: [String: String] = [:]
    let DELAY: Double = 60
    var isRunning = false
    var delayTask: Task<Void, Never>?
    var isUpdatingNotesFromApi = false

    private init() {
    }

    private func run() async {
        if isRunning || isUpdatingNotesFromApi { return }
        isRunning = true
        while !queue.isEmpty {
            var success = false
            guard let id = queue.first else {
                success = true
                break
            }
            let mongoId: String? = hm[id]
            if id.starts(with: "mongoid") {
                if mongoId == nil {
                    success = true
                } else {
                    success = await NoteManager.shared.getNoteFromApi(
                        mongoId!
                    )
                }
            } else {
                if let note = await Database.shared.getNoteById(id) {
                    if note.mongoId.isEmpty {
                        success = await NoteManager.shared.createNoteOnApi(note)
                    } else {
                        success = await NoteManager.shared.updateNoteToApi(note)
                    }
                } else {
                    if mongoId == nil {
                        success = true
                    } else {
                        success = await NoteManager.shared.deleteNodeFromApi(
                            mongoId!
                        )
                    }
                }
            }
            if !success {
                if !queue.isEmpty {
                    delay()
                }
                break
            } else {
                queue.removeFirst()
                hm.removeValue(forKey: id)
            }
        }
        isRunning = false
    }

    private func delay() {
        cancelDelay()
        delayTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(DELAY * 1_000_000_000))
                await run()
            } catch {
            }
        }
    }

    private func cancelDelay() {
        delayTask?.cancel()
        delayTask = nil
    }

    func add(_ note: Note) {
        let id = note.id.uuidString
        if hm[id] == nil {
            hm[id] = note.mongoId
            queue.append(id)
            if !isRunning && delayTask == nil {
                Task {
                    await run()
                }
            }
        }
    }

    func add(_ mongoId: String) {
        let key = "mongoid:\(mongoId)"
        if hm[key] == nil {
            hm[key] = mongoId
            queue.append(key)
            if !isRunning && delayTask == nil {
                Task {
                    await run()
                }
            }
        }
    }

    func clear() {
        cancelDelay()
        isRunning = true
        queue.removeAll(keepingCapacity: false)
        hm.removeAll(keepingCapacity: false)
        isRunning = false
    }

    func setIsUpdatingNotesFromApi(_ isUpdatingNotesFromApi: Bool) {
        if isUpdatingNotesFromApi {
            self.isUpdatingNotesFromApi = true
            Task {
                clear()
            }
        } else {
            self.isUpdatingNotesFromApi = false
            Task {
                await run()
            }
        }
    }
}

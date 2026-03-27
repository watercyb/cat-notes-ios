import Alamofire
import Foundation

class NoteManager {
    static let shared = NoteManager()

    let session: Session

    private init() {
        session = NetworkManager.shared.session
    }

    func createNoteOnApi(_ note: Note) async -> Bool {
        await ClerkManager.shared.getToken()
        return await withCheckedContinuation { continuation in
            let parameters: [String: Any] = [
                "title": note.title,
                "content": note.content,
                "version": note.version,
                "isEncrypted": note.isEncrypted,
            ]
            session.request(
                NetworkManager.shared.baseUrl + "/note/create",
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default
            ).response { response in
                if let error = response.error {
                    if let urlError = error.underlyingError as? URLError,
                        urlError.code == .timedOut
                    {
                        DispatchQueue.main.async {
                            Message.shared.showError("No internet connection")
                        }
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(2))")
                        }
                    }
                    continuation.resume(returning: false)
                    return
                }
                let code = response.response?.statusCode ?? -1
                if code >= 400 {
                    NetworkManager.shared.handle(code)
                    continuation.resume(returning: false)
                    return
                }
                guard let data = response.data else {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(7))")
                    }
                    continuation.resume(returning: false)
                    return
                }
                do {
                    let apiRes = try JSONDecoder().decode(
                        ApiRes.self,
                        from: data
                    )
                    if let createdNote = apiRes.note {
                        note.mongoId = createdNote.mongoId
                        DispatchQueue.main.async {
                            _ = Database.shared.save(note)
                            Message.shared.show("Note created")
                        }
                        continuation.resume(returning: true)
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(8))")
                        }
                        continuation.resume(returning: false)
                    }

                } catch {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(9))")
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func deleteNodeFromApi(_ mongoId: String) async -> Bool {
        await ClerkManager.shared.getToken()
        return await withCheckedContinuation { continuation in
            session.request(
                NetworkManager.shared.baseUrl + "/note/" + mongoId,
                method: .delete,
                encoding: JSONEncoding.default
            ).response { response in
                if let error = response.error {
                    if let urlError = error.underlyingError as? URLError,
                        urlError.code == .timedOut
                    {
                        DispatchQueue.main.async {
                            Message.shared.showError("No internet connection")
                        }
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(3))")
                        }
                    }
                    continuation.resume(returning: false)
                    return
                }
                let code = response.response?.statusCode ?? -1
                if code >= 400 {
                    NetworkManager.shared.handle(code)
                    continuation.resume(returning: false)
                    return
                }
                guard let data = response.data else {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(10))")
                    }
                    continuation.resume(returning: false)
                    return
                }
                do {
                    let apiRes = try JSONDecoder().decode(
                        ApiRes.self,
                        from: data
                    )
                    if apiRes.success ?? false {
                        DispatchQueue.main.async {
                            Database.shared.deletedNoteFromApi(mongoId)
                        }
                    }
                    continuation.resume(returning: true)
                } catch {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(11))")
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func updateNoteToApi(_ note: Note) async -> Bool {
        await ClerkManager.shared.getToken()
        return await withCheckedContinuation { continuation in
            let parameters: [String: Any] = [
                "noteId": note.mongoId,
                "title": note.title,
                "content": note.content,
                "version": note.version,
                "isEncrypted": note.isEncrypted,
            ]
            session.request(
                NetworkManager.shared.baseUrl + "/note/update",
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default
            ).response { response in
                if let error = response.error {
                    if let urlError = error.underlyingError as? URLError,
                        urlError.code == .timedOut
                    {
                        DispatchQueue.main.async {
                            Message.shared.showError("No internet connection")
                        }
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(4))")
                        }
                    }
                    continuation.resume(returning: false)
                    return
                }
                let code = response.response?.statusCode ?? -1
                if code >= 400 {
                    NetworkManager.shared.handle(code)
                    continuation.resume(returning: false)
                    return
                }
                guard let data = response.data else {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(11))")
                    }
                    continuation.resume(returning: false)
                    return
                }
                do {
                    let apiRes = try JSONDecoder().decode(
                        ApiRes.self,
                        from: data
                    )
                    if let success = apiRes.success {
                        if !success {
                            if let noteFromServer = apiRes.noteFromServer,
                                let newNote = apiRes.newNote
                            {
                                DispatchQueue.main.async {
                                    note.mongoId = newNote.mongoId
                                    _ = Database.shared.save(note)
                                    _ = Database.shared.createFromApiNote(
                                        noteFromServer
                                    )
                                    Message.shared.show(
                                        "A newer version is found, both two versions are kept.",
                                        duration: 2
                                    )
                                }
                            }
                        } else {
                            if let apiNote = apiRes.note {
                                DispatchQueue.main.async {
                                    note.mongoId = apiNote.mongoId
                                    note.title = apiNote.title ?? ""
                                    note.content = apiNote.content ?? ""
                                    note.version = Int32(apiNote.version)
                                    _ = Database.shared.save(note)
                                }
                            }
                        }
                        continuation.resume(returning: true)
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(12))")
                        }
                        continuation.resume(returning: false)
                    }

                } catch {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(13))")
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func getNoteFromApi(_ mongoId: String) async -> Bool {
        await ClerkManager.shared.getToken()
        return await withCheckedContinuation { continuation in
            session.request(
                NetworkManager.shared.baseUrl + "/note/" + mongoId,
                method: .get,
                encoding: JSONEncoding.default
            ).response { response in
                if let error = response.error {
                    if let urlError = error.underlyingError as? URLError,
                        urlError.code == .timedOut
                    {
                        DispatchQueue.main.async {
                            Message.shared.showError("No internet connection")
                        }
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(5))")
                        }
                    }
                    continuation.resume(returning: false)
                    return
                }
                let code = response.response?.statusCode ?? -1
                if code >= 400 {
                    NetworkManager.shared.handle(code)
                    continuation.resume(returning: false)
                    return
                }
                guard let data = response.data else {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(14))")
                    }
                    continuation.resume(returning: false)
                    return
                }
                do {
                    let apiRes = try JSONDecoder().decode(
                        ApiRes.self,
                        from: data
                    )
                    if let apiNote = apiRes.note {
                        DispatchQueue.main.async {
                            if let note = Database.shared.getNoteByMongoId(
                                apiNote.mongoId
                            ) {
                                Database.shared
                                    .compareNoteAndUpdateWithSameMongoId(
                                        note,
                                        apiNote
                                    )
                            } else {
                                _ = Database.shared.createFromApiNote(apiNote)
                            }
                        }
                        continuation.resume(returning: true)
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(15))")
                        }
                        continuation.resume(returning: false)
                    }

                } catch {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(16))")
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func getNotesFromApi() async -> Bool {
        await ClerkManager.shared.getToken()
        return await withCheckedContinuation { continuation in
            session.request(
                NetworkManager.shared.baseUrl + "/note/getNotesIdAndVersion",
                method: .get,
                encoding: JSONEncoding.default
            ).response { response in
                if let error = response.error {
                    if let urlError = error.underlyingError as? URLError,
                        urlError.code == .timedOut
                    {
                        DispatchQueue.main.async {
                            Message.shared.showError("No internet connection")
                        }
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(6))")
                        }
                    }
                    continuation.resume(returning: false)
                    return
                }
                let code = response.response?.statusCode ?? -1
                if code >= 400 {
                    NetworkManager.shared.handle(code)
                    continuation.resume(returning: false)
                    return
                }
                guard let data = response.data else {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(17))")
                    }
                    continuation.resume(returning: false)
                    return
                }
                do {
                    let apiRes = try JSONDecoder().decode(
                        ApiRes.self,
                        from: data
                    )
                    if let apiNotes = apiRes.notes {
                        DispatchQueue.main.async {
                            Database.shared.updateNoteWithoutTitleAndContents(
                                apiNotes
                            )
                        }
                        continuation.resume(returning: true)
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(18))")
                        }
                        continuation.resume(returning: false)
                    }

                } catch {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(19))")
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

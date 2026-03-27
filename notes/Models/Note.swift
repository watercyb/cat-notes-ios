import Foundation
import SwiftData

@Model
final class Note: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID = UUID()
    var title: String
    var content: String
    var mongoId: String
    var version: Int32
    var idx: Int32
    var removeTime: Int64
    var isRemovedFromServer: Bool
    var userId: String
    var isEncrypted: Bool

    init(
        title: String,
        content: String,
        mongoId: String,
        version: Int32,
        idx: Int32,
        removeTime: Int64,
        isRemovedFromServer: Bool,
        userId: String,
        isEncrypted: Bool
    ) {
        self.title = title
        self.content = content
        self.mongoId = mongoId
        self.version = version
        self.idx = idx
        self.removeTime = removeTime
        self.isRemovedFromServer = isRemovedFromServer
        self.userId = userId
        self.isEncrypted = isEncrypted
    }

    func toString() -> String {
        var content: String = content.replacingOccurrences(
            of: "\n",
            with: "\\n"
        )
        if content.count > 15 {
            let endIndex = content.index(content.startIndex, offsetBy: 15)
            content = String(content[..<endIndex])
        }
        return
            "idx: \(idx), title: \(title), mongoId: \(mongoId), version: \(version), userId: \(userId), rT \(removeTime), iR: \(isRemovedFromServer), iE: \(isEncrypted), content: \(content)"
    }
    
    func equals(_ note: ApiNote) -> Bool {
        return title == note.title && content==note.content && note.mongoId==mongoId && Int32(note.version) == version
    }
}

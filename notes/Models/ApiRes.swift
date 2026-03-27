import Foundation

nonisolated struct ApiRes: Codable {
    let success: Bool?
    let message: String?
    let user: ApiUser?
    let note: ApiNote?
    let noteFromServer: ApiNote?
    let newNote: ApiNote?
    let notes: [ApiNote]?
}

nonisolated struct ApiNote: Codable {
    let mongoId: String
    let title: String?
    let content: String?
    let version: Int
    let isEncrypted: Bool?

    // Map "_id" in JSON to mongoId
    enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case title
        case content
        case version
        case isEncrypted
    }
}

nonisolated struct ApiUser: Codable {
    let name: String
    let email: String
    let notes: [ApiNote]
    let isVerified: Bool
}

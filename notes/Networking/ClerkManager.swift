import ClerkKit

class ClerkManager {
    static let shared = ClerkManager()

    private init() {}

    func setClerkLogin() {
        AuthManager.shared.email =
            Clerk.shared.user?.primaryEmailAddress?.emailAddress ?? ""
        AuthManager.shared.type = AuthType.GOOGLE
        AuthManager.shared.name =
            "\(Clerk.shared.user?.firstName ?? "") \(Clerk.shared.user?.lastName ?? "")"
        AuthManager.shared.userId = AuthManager.shared.getUserId()
        AuthManager.shared.currentId = AuthManager.shared.userId
    }

    func getToken() async {
        do {
            let token = try await Clerk.shared.auth.getToken()
            AuthManager.shared.accessToken = token ?? ""
        } catch {
            AuthManager.shared.accessToken = ""
        }
    }
}

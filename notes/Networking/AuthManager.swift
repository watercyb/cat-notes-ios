import Alamofire
internal import Combine
import Foundation

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    let session: Session

    @Published var currentId: String?

    private init() {
        session = NetworkManager.shared.session
        currentId = userId
    }

    var accessToken: String {
        get { UserDefaults.standard.string(forKey: "accessToken") ?? "" }
        set { UserDefaults.standard.setValue(newValue, forKey: "accessToken") }
    }
    var refreshToken: String {
        get { UserDefaults.standard.string(forKey: "refreshToken") ?? "" }
        set { UserDefaults.standard.setValue(newValue, forKey: "refreshToken") }
    }
    var type: AuthType {
        get {
            if let raw = UserDefaults.standard.string(forKey: "type"),
                let value = AuthType(rawValue: raw)
            {
                return value
            }
            return AuthType.NULL
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: "type")
        }
    }
    var email: String {
        get { UserDefaults.standard.string(forKey: "email") ?? "" }
        set { UserDefaults.standard.setValue(newValue, forKey: "email") }
    }
    var name: String {
        get { UserDefaults.standard.string(forKey: "name") ?? "" }
        set { UserDefaults.standard.setValue(newValue, forKey: "name") }
    }
    var userId: String {
        get { UserDefaults.standard.string(forKey: "id") ?? "" }
        set { UserDefaults.standard.setValue(newValue, forKey: "id") }
    }

    func emailLogin(email: String, password: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let url = NetworkManager.shared.baseUrl + "/auth/login"
            let parameters: [String: Any] = [
                "email": email,
                "password": password,
            ]

            session.request(
                url,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default
            )
            .response { response in
                //Check network error
                if let error = response.error {
                    if let urlError = error.underlyingError as? URLError,
                        urlError.code == .timedOut
                    {
                        DispatchQueue.main.async {
                            Message.shared.showError("No internet connection")
                        }
                    } else {
                        DispatchQueue.main.async {
                            Message.shared.showError("Unexpected error: (\(1))")
                        }
                    }
                    continuation.resume(returning: false)
                    return
                }

                //Check HTTP status code
                let code = response.response?.statusCode ?? -1
                if code >= 400 {
                    NetworkManager.shared.handle(code)
                    continuation.resume(returning: false)
                    return
                }

                //Header parsing safely
                let headerFields =
                    response.response?.allHeaderFields as? [String: String]
                    ?? [:]

                if let authHeader = headerFields["Authorization"] {
                    let parts = authHeader.split(separator: " ")
                    if parts.count > 1 {
                        self.accessToken = String(parts[1])
                    }
                }

                if let refreshHeader = headerFields["refreshToken"] {
                    let parts = refreshHeader.split(separator: " ")
                    if parts.count > 1 {
                        self.refreshToken = String(parts[1])
                    }
                }

                //If tokens missing, fail
                guard !self.accessToken.isEmpty else {
                    continuation.resume(returning: false)
                    return
                }

                //Parse response data safely
                guard let data = response.data else {
                    continuation.resume(returning: false)
                    return
                }

                do {
                    let _ = try JSONDecoder().decode(
                        ApiRes.self,
                        from: data
                    )
                    continuation.resume(returning: true)
                } catch {
                    DispatchQueue.main.async {
                        Message.shared.showError("Unexpected error: (\(0))")
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func getUserId() -> String {
        if type == AuthType.NULL { return "" }
        return "\(email)#\(type)"
    }

    func setLogout() {
        AuthManager.shared.email = ""
        AuthManager.shared.type = AuthType.NULL
        AuthManager.shared.name = ""
        AuthManager.shared.userId = ""
        AuthManager.shared.currentId = ""
    }

    func chechAuth() async -> Bool {
        await ClerkManager.shared.getToken()

        return await withCheckedContinuation { continuation in
            session.request(
                NetworkManager.shared.baseUrl + "/auth/check-auth",
                method: .get
            )
            .response { response in
                //Network error (including timeout)
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
                //HTTP error
                let code = response.response?.statusCode ?? -1
                if code >= 400 {
                    NetworkManager.shared.handle(code)
                    continuation.resume(returning: false)
                    return
                }
                //No data
                guard let jsonData = response.data else {
                    continuation.resume(returning: false)
                    return
                }
                //Decode
                do {
                    let apiRes = try JSONDecoder().decode(
                        ApiRes.self,
                        from: jsonData
                    )
                    if let apiNotes = apiRes.user?.notes {
                        DispatchQueue.main.async {
                            Database.shared.updateNote(apiNotes)
                        }
                    }
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

enum AuthType: String {
    case EMAIL
    case GOOGLE
    case NULL
}

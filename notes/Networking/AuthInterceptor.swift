import Alamofire
import Foundation

final class AuthInterceptor: RequestInterceptor {

    private let retryLimit = 1

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var request = urlRequest

        let token = AuthManager.shared.accessToken
        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        request.setValue("android-app", forHTTPHeaderField: "x-client-type")

        completion(.success(request))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard request.retryCount < retryLimit else {
            completion(.doNotRetry)
            return
        }

        if let response = request.response, response.statusCode == 401 {
            refreshAccessToken { success in
                if success {
                    completion(.retry)
                } else {
                    completion(.doNotRetry)
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }

    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        let refreshToken = AuthManager.shared.refreshToken

        let parameters: [String: Any] = [
            "refreshToken": "Bearer \(refreshToken)"
        ]
        AuthManager.shared.session.request(
            "http://localhost:5001/api/auth/refresh",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .response { response in
            guard
                let headerFields = response.response?.allHeaderFields
                    as? [String: String]
            else {
                completion(false)
                return
            }

            if let authHeader = headerFields["Authorization"] {
                let parts = authHeader.split(separator: " ")
                if parts.count > 1 {
                    AuthManager.shared.accessToken = String(parts[1])
                }
            }

            if let refreshHeader = headerFields["refreshToken"] {
                let parts = refreshHeader.split(separator: " ")
                if parts.count > 1 {
                    AuthManager.shared.refreshToken = String(parts[1])
                }
            }

            if AuthManager.shared.accessToken != "" {
                completion(true)
            } else {
                completion(false)
            }

        }
    }
}

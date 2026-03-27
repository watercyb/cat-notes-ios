import Alamofire
import Foundation

class NetworkManager {
    //let baseUrl = "http://localhost:5001/api"
    let baseUrl = "https://notes.bbjdev.com/api"
    static let shared = NetworkManager()
    let session: Session

    private init() {
        session = Session(interceptor: AuthInterceptor())
    }
    
    func handle(_ code: Int) {
        switch code {
        case 401:
            Message.shared.showError("Invalid credentials")
        case 404:
            Message.shared.showError("Server internal error")
        case 422:
            Message.shared.showError("All fields are required")
        case 429:
            Message.shared.showError("Too many requests")
        case 500:
            Message.shared.showError("Server internal error")
        case 503:
            Message.shared.showError("Server internal error")
        default:
            Message.shared.showError("Unexpected error: \(code)")
        }
    }
}

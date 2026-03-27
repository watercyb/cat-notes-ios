import Foundation

final class Time {
    private init() {}  // prevent instantiation

    static func getCurrentTime() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    static func getDeletingTime() -> Int64 {
        return getCurrentTime() + 7 * 24 * 60 * 60
            * 1000
    }
}

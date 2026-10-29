import ClerkKit
import SwiftData
import SwiftUI

@main
struct notesApp: App {
    init() {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["clerk_key"] as? String {
            Clerk.configure(
                publishableKey: key
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            MainWrapper()
        }
        .modelContainer(for: Note.self)
        .environment(Clerk.shared)
    }
}

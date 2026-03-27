import ClerkKit
import ClerkKitUI
import SwiftData
import SwiftUI
import ToastWindow
import WaterfallGrid

struct TopBar: View {
    @Binding var authIsPresented: Bool
    @ObservedObject var db: Database

    var body: some View {
        HStack {
            Spacer()
            if Clerk.shared.user == nil {
                Button(action: { authIsPresented = true }) {
                    Image("Avatar")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .cornerRadius(12)
                }
            } else {
                UserButton(signedOutContent: {
                    Button("Sign in") { authIsPresented = true }
                })
            }
        }
        .task(id: Clerk.shared.user) {
            if Clerk.shared.user != nil {
                ClerkManager.shared.setClerkLogin()
                withAnimation { db.notes = db.notes }
                Task { await AuthManager.shared.chechAuth() }
            } else {
                AuthManager.shared.setLogout()
                withAnimation { db.notes = db.notes }
            }
        }
        .padding()
    }
}

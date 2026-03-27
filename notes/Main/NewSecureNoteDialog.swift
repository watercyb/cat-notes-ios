import CommonCrypto
import CryptoKit
import SwiftUI

struct NewSecureNoteDialog: View {
    @State private var password = ""
    var title: String = "Create Password"
    @Binding var isPresented: Bool
    @ObservedObject var db: Database
    @Binding var selectedNote: Note?
    @Binding var showingEditor: Bool

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text(title)
                        .font(.headline)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .frame(width: 250)

                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .frame(width: 100, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)

                        Button("OK") {
                            if password.isEmpty {
                                Message.shared.showError(
                                    "Please enter a password"
                                )
                            } else {
                                do {
                                    let encrypted: String = try Crypto.shared.encrypt(
                                        password: password,
                                        plaintext: ""
                                    )
                                    let res = db.create(
                                        Note(
                                            title: "",
                                            content: encrypted,
                                            mongoId: "",
                                            version: 0,
                                            idx: 0,
                                            removeTime: 0,
                                            isRemovedFromServer: false,
                                            userId: AuthManager.shared
                                                .getUserId(),
                                            isEncrypted: true
                                        )
                                    )

                                    if res {
                                        Task {
                                            await SyncQueue.shared.add(
                                                db.notes.last!
                                            )
                                        }
                                        selectedNote = db.notes.last
                                        showingEditor = true
                                        password = ""
                                        isPresented = false
                                    }
                                } catch {
                                    Message.shared.showError(
                                        "Unexpected password error"
                                    )
                                }
                            }
                        }
                        .frame(width: 100, height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 10)
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut, value: isPresented)
        }
    }
}

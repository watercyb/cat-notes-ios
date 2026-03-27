import CommonCrypto
import CryptoKit
import SwiftUI

struct ChangePasswordDialog: View {
    @Binding var isPresented: Bool
    @Binding var salt: Data?
    @Binding var key: SymmetricKey?
    @Binding var content: String
    @State private var password = ""
    @State private var confirmPassword = ""

    var title: String = "Update Password"
    @Binding var note: Note
    @Binding var isChangedPassword: Bool

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text(title)
                        .font(.headline)

                    VStack {
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .frame(width: 250)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .frame(width: 250)
                    }

                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .frame(width: 115, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)

                        Button("OK") {
                            if password.isEmpty {
                                Message.shared.showError(
                                    "Please enter a password"
                                )
                            } else if password != confirmPassword {
                                Message.shared.showError(
                                    "Passwords do not match"
                                )
                            } else {
                                do {
                                    let encrypted:
                                        (
                                            salt: Data, key: SymmetricKey,
                                            encryptedText: String
                                        ) = try Crypto.shared.encrypt(
                                            password: password,
                                            plaintext: content
                                        )
                                    salt = encrypted.salt
                                    key = encrypted.key
                                    note.content = encrypted.encryptedText
                                    note.version += 1
                                    _ = Database.shared.save(note)
                                    isChangedPassword = true

                                    Message.shared.show(
                                        "Password changed"
                                    )
                                    isPresented = false
                                } catch {
                                    Message.shared.showError(
                                        "Unexpected password error"
                                    )
                                }
                            }
                        }
                        .frame(width: 115, height: 44)
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

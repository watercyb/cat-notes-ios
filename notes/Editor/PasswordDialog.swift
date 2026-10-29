import CommonCrypto
import CryptoKit
import SwiftUI

struct PasswordDialog: View {
    @Binding var isPresented: Bool
    @Binding var salt: Data?
    @Binding var key: SymmetricKey?
    @Binding var content: String
    @State private var password = ""
    @Binding var isPasswordCorrect: Bool
    var encrypted: String
    @Binding var originalContent: String
    
    var title: String = "Password Required"
    @Binding var note: Note
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text(title)
                        .font(.headline)

                    HStack {
                        Button(action: {
                            Database.shared.editingNote = nil
                            withAnimation {
                                let _ = Database.shared.moveToTrash(note)
                            }
                            isPasswordCorrect = false
                            isPresented = false
                        }) {
                            Image("Remove_button")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .cornerRadius(12)                        }
                        .padding(.trailing, 5)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .frame(width: 200)
                    }

                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isPasswordCorrect = false
                            isPresented = false
                            dismiss()
                        }
                        .frame(width: 115, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)

                        Button("OK") {
                            do {
                                let decrypted = try Crypto.shared.decrypt(
                                    password: password,
                                    encrypted: encrypted
                                )
                                salt = decrypted.salt
                                key = decrypted.key
                                content = decrypted.plaintext
                                originalContent = content
                                isPresented = false
                            } catch {
                                Message.shared.showError(
                                    "Incorrect password"
                                )
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

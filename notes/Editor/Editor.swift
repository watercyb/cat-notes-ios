import CommonCrypto
import CryptoKit
import SwiftUI

struct Editor: View {
    @Environment(\.dismiss) private var dismiss
    @State var note: Note
    @State var title: String = ""
    @State var content: String = ""
    @State var removed = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showingDialog = false

    @State private var showingPasswordDialog = false
    @State var salt: Data? = nil
    @State var key: SymmetricKey? = nil
    @State var isPasswordCorrect = false
    @State var originalContent = ""

    @State private var showingChangePasswordDialog = false
    @State private var isChangedPassword = false

    var body: some View {
        VStack(spacing: 16) {

            // Top bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image("Back")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .cornerRadius(12)
                }

                Spacer()

                if note.isEncrypted
                    && note.userId == AuthManager.shared.currentId
                {
                    Button(action: {
                        showingChangePasswordDialog = true
                    }) {
                        Image("Password")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .cornerRadius(12)
                    }
                    .padding(.trailing, 15)
                }

                Button(action: {
                    showingDialog = true
                }) {
                    Image("Remove_button")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .cornerRadius(12)
                }
                .padding(.trailing, 5)
            }
            .padding(.horizontal, 16)
            .padding(.top)

            // Title box
            TextField("Title", text: $title)
                .font(.title2)
                .padding(12)
                .foregroundColor(.primary)
                .cornerRadius(8)
                .padding(.horizontal)

            // Content box
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("Note")
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 20)
                        .padding(.horizontal, 32)
                }
                TextEditor(text: $content)
                    .padding(12)
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
            }

        }
        .background(Color("Background"))
        .navigationBarHidden(true)  // hide default navigation bar
        .onDisappear {
            Database.shared.editingNote = nil
            if !removed && isPasswordCorrect {
                var currentContent = content
                if note.isEncrypted {
                    do {
                        currentContent = try Crypto.shared.encrypt(
                            salt: salt!,
                            key: key!,
                            plaintext: content
                        )
                    } catch {
                        Message.shared.showError(
                            "Unexpected password error"
                        )
                    }
                }
                if note.title != title || originalContent != content || isChangedPassword {
                    note.title = title
                    note.content = currentContent
                    note.version += 1		
                    _ = Database.shared.save(note)
                    Task { await SyncQueue.shared.add(note) }
                } else {
                }
            }
        }
        .onAppear {
            title = note.title
            if !note.isEncrypted {
                content = note.content
                originalContent = note.content
                isPasswordCorrect = true
            } else {
                showingPasswordDialog = true
            }
            Database.shared.editingNote = note
        }
        .alert(
            note.title.isEmpty ? "Untitled Note" : note.title,
            isPresented: $showingDialog,
        ) {
            Button("Delete", role: .destructive) {
                Database.shared.editingNote = nil
                withAnimation {
                    let _ = Database.shared.moveToTrash(note)
                    removed = true
                }
                dismiss()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Do you want to move this note to the trash?"
            )
        }
        .overlay(
            PasswordDialog(
                isPresented: $showingPasswordDialog,
                salt: $salt,
                key: $key,
                content: $content,
                isPasswordCorrect: $isPasswordCorrect,
                encrypted: note.content,
                originalContent: $originalContent,
                note: $note
            )
        )
        .overlay(
            ChangePasswordDialog(
                isPresented: $showingChangePasswordDialog,
                salt: $salt,
                key: $key,
                content: $content,
                note: $note,
                isChangedPassword: $isChangedPassword
            )
        )
        .onChange(of: isPasswordCorrect) { _, isPasswordCorrect in
            if !isPasswordCorrect {
                dismiss()
            }
        }
    }
}

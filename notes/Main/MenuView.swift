import SwiftUI

struct MenuView: View {
    @Binding var showMenu: Bool
    @Binding var showTrashCan: Bool
    @Binding var selectedNote: Note?
    @Binding var showingEditor: Bool
    @Binding var isLocked: Bool

    var debug: Bool
    var db = Database.shared
    @Binding var showNewSecureNotePassword: Bool

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                Group {
                    Button("NEW NOTE") {
                        let res = db.create(
                            Note(
                                title: "",
                                content: "",
                                mongoId: "",
                                version: 0,
                                idx: 0,
                                removeTime: 0,
                                isRemovedFromServer: false,
                                userId: AuthManager.shared.getUserId(),
                                isEncrypted: false
                            )
                        )

                        if res {
                            Task {
                                await SyncQueue.shared.add(db.notes.last!)
                            }
                            selectedNote = db.notes.last
                            showingEditor = true
                        }

                        showMenu = false
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)

                    Divider()

                    Button("SECURE NOTE") {
                        showNewSecureNotePassword.toggle()
                        showMenu = false
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)

                    Divider()

                    Button("TRASH CAN") {
                        showTrashCan = true
                        showMenu = false
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)

                    //if debug {
                    //}
                }
            }
            .padding()
            .background(Color("Menu_background"))
            .foregroundColor(Color("Blue_text"))
            .font(.custom("Good Pawoo", size: 30))
            .cornerRadius(16)
            .padding()
        }
        .transition(.move(edge: .bottom))
    }
}

import SwiftUI
import WaterfallGrid

struct TrashView: View {
    @ObservedObject private var db = Database.shared

    @State private var showingDialog = false
    @State private var selectedNote: Note?

    private var deletedNotes: [Note] {
        db.removedNotes
    }

    var body: some View {
        ZStack {
            // Main background
            Color("Background")
                .ignoresSafeArea()
            VStack(alignment: .leading) {
                // Top-left title
                Text("Trash Can")
                    .font(.custom("LemiXiaoNaiPaoTi", size: 50))
                    .bold(true)
                    .padding(.horizontal)
                    .padding(.top)
                    .foregroundColor(Color("Blue_text"))

                if db.removedNotes.isEmpty {
                    // Placeholder view when empty
                    VStack {
                        Spacer()
                        Image("Empty_page")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .opacity(1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 100)
                } else {
                    ScrollView {
                        WaterfallGrid(deletedNotes, id: \.id) { note in
                            NoteCard(note: note)
                                .onTapGesture {
                                    selectedNote = note
                                    showingDialog = true
                                }
                        }
                        .gridStyle(
                            columns: 1,
                            spacing: 12,
                            animation: .default
                        )
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .alert(
                (selectedNote?.title == nil)
                    ? "Untitled Note"
                    : (selectedNote!.title.isEmpty
                        ? "Untitled Note" : selectedNote!.title),
                isPresented: $showingDialog,
            ) {
                Button("Restore") {
                    guard let note = selectedNote else { return }
                    withAnimation {
                        _ = db.restoreFromTrash(note)
                    }
                }

                Button("Delete", role: .destructive) {
                    guard let note = selectedNote else { return }
                    withAnimation {
                        _ = db.delete(note)
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "Do you want to permanently delete this note or restore it?"
                )
            }
        }
    }
}

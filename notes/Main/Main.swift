import ClerkKit
import ClerkKitUI
import SwiftData
import SwiftUI
import ToastWindow
import WaterfallGrid

struct Main: View {
    // Clerk
    @State private var authIsPresented = false
    @ObservedObject private var db = Database.shared
    @State private var selectedNote: Note?
    @State private var showMenu = false
    @State private var isLocked = false
    @State private var showingEditor = false
    @State private var debug = true
    @State private var showTrashCan = false
    @State private var showNewSecureNotePassword = false
    @State private var syncTime : Int64 = -1

    // Adaptive grid: 2–3 columns depending on width
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.toastManager) var toastManager
    @Environment(\.scenePhase) var scenePhase

    init(modelContext: ModelContext) {
        db.run(context: modelContext)
    }

    var body: some View {
        ZStack {
            // Main background
            Color("Background")
                .ignoresSafeArea()

            // Main layout
            VStack(spacing: 0) {

                // Top bar
                TopBar(authIsPresented: $authIsPresented, db: db)

                if db.notes.isEmpty {
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
                    // Scrollable notes
                    ScrollView {
                        // WaterfallGrid with notes
                        WaterfallGrid(db.notes, id: \.id) { note in
                            NoteCard(note: note)
                                .onTapGesture {
                                    selectedNote = note
                                }
                                .draggable(note.id.uuidString)
                                .dropDestination(for: String.self) { items, _ in
                                    guard
                                        let newIDString = items.first,
                                        let newID = UUID(
                                            uuidString: newIDString
                                        ),
                                        let fromIndex = db.notes
                                            .firstIndex(where: {
                                                $0.id == newID
                                            }),
                                        let toIndex = db.notes
                                            .firstIndex(
                                                where: { $0.id == note.id }),
                                        fromIndex != toIndex
                                    else { return false }

                                    withAnimation {
                                        db.move(
                                            fromIndex: fromIndex,
                                            toIndex: toIndex
                                        )
                                    }

                                    return true
                                }
                        }
                        .gridStyle(columns: 2, spacing: 12)
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sheet(item: $selectedNote) { note in
                        Editor(
                            note: note
                        )
                    }
                    .refreshable {
                        _ = await NoteManager.shared.getNotesFromApi()
                    }
                }
            }

            // Menu overlay
            if showMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showMenu = false
                        }
                    }

                MenuView(
                    showMenu: $showMenu,
                    showTrashCan: $showTrashCan,
                    selectedNote: $selectedNote,
                    showingEditor: $showingEditor,
                    isLocked: $isLocked,
                    debug: debug,
                    showNewSecureNotePassword: $showNewSecureNotePassword
                )
            }

            // Floating button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if !showMenu {
                        Button {
                            withAnimation {
                                showMenu.toggle()
                            }
                        } label: {
                            Image("Setting")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .cornerRadius(12)
                        }
                        .padding(.bottom, 20)
                        .padding(.trailing, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $authIsPresented) {
            AuthView()
        }
        .sheet(isPresented: $showTrashCan) {
            TrashView()
        }
        .onAppear {
            Message.shared.register(toastManager)
        }
        .alert(
            "Note removed from server",
            isPresented: Binding(
                get: { db.removedOnServerNotes.first != nil },
                set: { _ in }
            ),
            presenting: db.removedOnServerNotes.first
        ) { note in
            Button("Delete", role: .destructive) {
                db.setNoteAsRemovedOnServer(note, true)
            }
            Button("Keep", role: .cancel) {
                db.setNoteAsRemovedOnServer(note, false)
            }
        } message: { note in
            Text(
                "The note \(note.title.isEmpty ? "<No Title>" : note.title) was removed from the server. Do you want to delete your local copy as well?"
            )
        }
        .overlay(
            NewSecureNoteDialog(
                isPresented: $showNewSecureNotePassword,
                db: db,
                selectedNote: $selectedNote,
                showingEditor: $showingEditor
            )
        )
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                if syncTime == -1 {
                    syncTime = Time.getCurrentTime()
                } else {
                    let time = Time.getCurrentTime()
                    if time - syncTime > 1 * 60 * 1000 {
                        Task {
                            await NoteManager.shared.getNotesFromApi()
                        }
                    }
                    syncTime = time
                }
            }
        }
    }
}

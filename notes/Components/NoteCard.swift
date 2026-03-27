import SwiftUI

struct NoteCard: View {
    let note: Note
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var auth = AuthManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }

            if !note.content.isEmpty {
                if !note.isEncrypted {
                    Text(note.content)
                        .font(.body)
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Image("Lock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        Text("Locked")
                            .font(.system(size: 16))
                            .bold()
                            .foregroundColor(Color("Pink_remove"))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (note.userId == auth.currentId
                ? Color("Note_card") : Color("Note_card_other_user"))
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

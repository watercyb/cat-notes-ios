import SwiftData
import SwiftUI

struct MainWrapper: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Main(modelContext: modelContext)
    }
}

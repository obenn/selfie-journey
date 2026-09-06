import SwiftUI
import SwiftData

@main
struct SelfieJourneyApp: App {
    private let container: ModelContainer?
    private let startupError: String?

    init() {
        do {
            #if DEBUG
            let inMemory = ProcessInfo.processInfo.arguments.contains("--uitesting")
            #else
            let inMemory = false
            #endif
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
            container = try ModelContainer(for: Portrait.self, configurations: configuration)
            startupError = nil
        } catch {
            container = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                ContentView().modelContainer(container)
            } else {
                ContentUnavailableView {
                    Label("Your journal couldn't open", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your existing portraits have not been changed. Restart Selfie Journey to try again.\n\n\(startupError ?? "")")
                }
            }
        }
    }
}

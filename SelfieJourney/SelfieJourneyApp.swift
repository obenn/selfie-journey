import SwiftUI
import SwiftData

@main
struct SelfieJourneyApp: App {
    private let container: ModelContainer?
    private let startupError: String?

    init() {
        PrivacyMigration.removeLegacyReportingData()
        do {
            #if DEBUG
            let inMemory = ProcessInfo.processInfo.arguments.contains("--uitesting")
            #else
            let inMemory = false
            #endif
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
            let journal = try ModelContainer(for: Portrait.self, configurations: configuration)
            #if DEBUG
            // Explicit UI fixtures exist only in the isolated in-memory test journal.
            // Release builds can never seed photos or count sample data as a user's streak.
            if inMemory, ProcessInfo.processInfo.arguments.contains("--uitesting-with-portraits"),
               let sample = UIImage(named: "PortraitInspiration"),
               let data = sample.jpegData(compressionQuality: 0.9) {
                for offset in 0..<3 {
                    let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
                    journal.mainContext.insert(Portrait(date: date, imageData: data))
                }
                try journal.mainContext.save()
            }
            #endif
            container = journal
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

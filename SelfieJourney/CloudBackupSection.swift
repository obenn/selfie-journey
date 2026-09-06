import SwiftUI
import SwiftData

struct CloudBackupSection: View {
    let backup: CloudBackupManager
    @Environment(\.modelContext) private var context
    @Query(sort: \Portrait.date) private var portraits: [Portrait]
    @State private var selectedBackup: BackupSummary?
    @State private var showingHistory = false

    var body: some View {
        Section {
            Toggle("Automatic iCloud backups", isOn: Binding(get: { backup.enabled }, set: { value in
                backup.enabled = value
                if value { Task { await backup.backUp(portraits) } }
            }))
            .accessibilityIdentifier("settings.cloudBackupToggle")
            Label(backup.status, systemImage: backup.available ? "icloud" : "icloud.slash")
                .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
            if backup.busy {
                ProgressView(value: backup.progress).tint(JourneyTheme.accent)
                Button("Cancel") { backup.cancel() }
            } else {
                Button("Back up now", systemImage: "arrow.triangle.2.circlepath") {
                    Task { await backup.backUp(portraits, force: true) }
                }.disabled(!backup.available || portraits.isEmpty)
                Button("Restore from iCloud", systemImage: "icloud.and.arrow.down") { showingHistory = true }
                    .disabled(!backup.available)
                    .accessibilityIdentifier("settings.restoreBackup")
                Button("Check iCloud status", systemImage: "arrow.clockwise") { Task { await backup.refresh() } }
            }
            if let date = backup.lastBackup {
                LabeledContent("Latest snapshot", value: date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
            }
        } header: { Text("A SAFER HOME FOR YOUR STORY") } footer: {
            Text("Dated backups keep your portraits and notes in your iCloud Drive. Earlier photos remain in backup history, even after you delete them here. Restore adds missing days and keeps the portraits already on this device. Apple completes uploads when a connection and storage are available.")
        }
        .task { await backup.refresh() }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                List {
                    if backup.backups.isEmpty {
                        ContentUnavailableView("No backups found yet", systemImage: "icloud", description: Text("Back up your journal first, or allow iCloud a moment to find snapshots from your other device."))
                    } else {
                        ForEach(backup.backups) { item in
                            Button { selectedBackup = item } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(JourneyTheme.ink)
                                        Text("Restore missing days").font(.caption).foregroundStyle(JourneyTheme.secondary)
                                    }
                                } icon: { Image(systemName: "clock.arrow.circlepath") }
                            }.disabled(backup.busy)
                        }
                    }
                }
                .navigationTitle("Your iCloud backups").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingHistory = false } } }
                .confirmationDialog("Restore this backup?", isPresented: Binding(get: { selectedBackup != nil }, set: { if !$0 { selectedBackup = nil } }), titleVisibility: .visible) {
                    Button("Restore missing portraits") {
                        if let item = selectedBackup {
                            showingHistory = false
                            Task { await backup.restore(item, into: context) }
                        }
                        selectedBackup = nil
                    }
                    Button("Cancel", role: .cancel) { selectedBackup = nil }
                } message: { Text("Existing days stay as they are. Missing portraits and their notes will be downloaded from iCloud.") }
            }.tint(JourneyTheme.accent)
        }
    }
}

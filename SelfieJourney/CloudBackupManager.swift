import Foundation
import Observation
import SwiftData

nonisolated struct BackupSummary: Identifiable, Sendable {
    let url: URL
    var id: URL { url }
    var date: Date {
        let stamp = url.lastPathComponent.split(separator: "-").first.flatMap { Double($0) } ?? 0
        return Date(timeIntervalSince1970: stamp / 1000)
    }
}

@Observable @MainActor
final class CloudBackupManager {
    var enabled: Bool {
        didSet {
            defaults.set(enabled, forKey: "journey.backup.enabled")
            if !enabled { cancel() }
        }
    }
    private(set) var available = false
    private(set) var busy = false
    private(set) var progress = 0.0
    private(set) var status = "Checking iCloud Drive…"
    private(set) var backups: [BackupSummary] = []
    private(set) var lastBackup: Date?
    var errorMessage: String?
    var restorationMessage: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let archive = BackupArchive()
    @ObservationIgnored private var root: URL?
    @ObservationIgnored private var signature: String?
    @ObservationIgnored private let archiveRoot: URL?
    @ObservationIgnored private var pendingBackup: [Portrait]?
    @ObservationIgnored private var query: NSMetadataQuery?
    @ObservationIgnored private var queryObservers: [NSObjectProtocol] = []
    @ObservationIgnored private var identityObserver: NSObjectProtocol?
    @ObservationIgnored private var lastManifest: BackupManifest?
    @ObservationIgnored private var lastManifestURL: URL?
    @ObservationIgnored private var accountGeneration = UUID()
    @ObservationIgnored private var operation: Task<Void, Never>?
    @ObservationIgnored private let isTesting: Bool

    init(defaults: UserDefaults? = nil, archiveRoot: URL? = nil) {
        self.archiveRoot = archiveRoot
        #if DEBUG
        isTesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        #else
        isTesting = false
        #endif
        self.defaults = defaults ?? (isTesting ? UserDefaults(suiteName: "journey.ui-testing.backups")! : .standard)
        enabled = self.defaults.object(forKey: "journey.backup.enabled") == nil ? true : self.defaults.bool(forKey: "journey.backup.enabled")
        identityObserver = NotificationCenter.default.addObserver(forName: .NSUbiquityIdentityDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.accountGeneration = UUID()
                self.operation?.cancel()
                self.pendingBackup = nil
                self.root = nil
                self.signature = nil
                self.lastBackup = nil
                self.lastManifest = nil
                self.lastManifestURL = nil
                self.available = false
                self.queryObservers.forEach(NotificationCenter.default.removeObserver)
                self.queryObservers = []
                self.query?.stop()
                self.query = nil
                self.backups = []
                await self.refresh()
            }
        }
    }

    deinit {
        if let identityObserver { NotificationCenter.default.removeObserver(identityObserver) }
        queryObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func refresh() async {
        guard !busy else { return }
        guard !isTesting || archiveRoot != nil else {
            status = "iCloud requires a signed device and iCloud Drive."
            return
        }
        let generation = accountGeneration
        let resolved: URL?
        if let archiveRoot { resolved = archiveRoot }
        else { resolved = await archive.cloudRoot() }
        guard generation == accountGeneration else { return }
        root = resolved
        available = resolved != nil
        guard let root else {
            status = "iCloud Drive is unavailable. Check your Apple Account and iCloud Drive in Settings."
            return
        }
        if archiveRoot == nil { startDiscovering() }
        do {
            mergeDiscovered(try await archive.list(at: root))
            if let lastManifest, let lastManifestURL {
                let uploaded = try await archive.isFullyUploaded(lastManifest, url: lastManifestURL, root: root)
                status = uploaded ? "Backed up to iCloud" : "Backup prepared · iCloud upload pending"
            } else {
                status = enabled ? "iCloud is ready for your next backup" : "Automatic backups are off"
            }
        } catch { status = error.localizedDescription }
    }

    /// Snapshot metadata first. Compressed photos are requested individually by the archive actor.
    func backUp(_ portraits: [Portrait], force: Bool = false) async {
        guard enabled || force, !portraits.isEmpty else { return }
        if busy { pendingBackup = portraits; return }
        if root == nil { await refresh() }
        guard let root else { return }
        let sources = portraits.sorted { $0.date < $1.date }
        let metadata = sources.map { BackupSource(id: $0.id, revision: $0.imageRevision, date: $0.date, note: $0.note, poseRawValue: $0.poseRawValue) }
        let newSignature = metadata.map { "\($0.id)|\($0.revision)|\($0.date.timeIntervalSince1970)|\($0.note)|\($0.poseRawValue)" }.joined(separator: "\n")
        guard force || signature != newSignature else { return }
        busy = true
        errorMessage = nil
        restorationMessage = nil
        progress = 0
        status = "Preparing your iCloud backup…"
        let generation = accountGeneration
        operation = Task {
            defer { busy = false; operation = nil }
            do {
                let (manifest, url) = try await archive.write(sources: metadata, to: root, imageDataAt: { index in
                    try Task.checkCancellation()
                    guard generation == self.accountGeneration,
                          sources[index].modelContext != nil,
                          sources[index].imageRevision == metadata[index].revision else { throw BackupError.changedDuringBackup }
                    return sources[index].imageData
                }) { value in Task { @MainActor in self.progress = value } }
                guard generation == accountGeneration else { return }
                signature = newSignature
                lastBackup = manifest.createdAt
                lastManifest = manifest
                lastManifestURL = url
                mergeDiscovered([url])
                let uploaded = try await archive.isFullyUploaded(manifest, url: url, root: root)
                status = uploaded ? "Backed up to iCloud" : "Backup prepared · iCloud upload pending"
            } catch is CancellationError {
                status = "Backup paused. Your portraits are still on this device."
            } catch {
                status = "Backup needs attention"
                errorMessage = error.localizedDescription
            }
        }
        await operation?.value
        if let pending = pendingBackup {
            pendingBackup = nil
            await backUp(pending.filter { $0.modelContext != nil })
        }
    }

    func restore(_ backup: BackupSummary, into context: ModelContext) async {
        guard !busy, let root else { return }
        busy = true
        errorMessage = nil
        restorationMessage = nil
        progress = 0
        status = "Restoring missing portraits…"
        let generation = accountGeneration
        operation = Task {
            var restored = 0
            defer { busy = false; operation = nil }
            do {
                let manifest = try await archive.manifest(at: backup.url)
                let existing = try context.fetch(FetchDescriptor<Portrait>())
                var days = Set(existing.map { Calendar.current.startOfDay(for: $0.date) })
                var ids = Set(existing.map(\.id))
                for (index, entry) in manifest.entries.sorted(by: { $0.date < $1.date }).enumerated() {
                    try Task.checkCancellation()
                    guard generation == accountGeneration else { throw CancellationError() }
                    let day = Calendar.current.startOfDay(for: entry.date)
                    if !days.contains(day), !ids.contains(entry.id) {
                        let data = try await archive.photo(entry, root: root)
                        // Account could change while a photo downloads; never import it into another account's operation.
                        guard generation == accountGeneration else { throw CancellationError() }
                        let portrait = Portrait(date: entry.date, imageData: data, note: entry.note,
                                                pose: PortraitPose(rawValue: entry.poseRawValue ?? "classic") ?? .classic)
                        portrait.id = entry.id
                        portrait.imageRevision = entry.imageRevision
                        context.insert(portrait)
                        do { try context.save() } catch { context.rollback(); throw error }
                        days.insert(day)
                        ids.insert(entry.id)
                        restored += 1
                    }
                    progress = Double(index + 1) / Double(max(1, manifest.entries.count))
                }
                signature = nil
                status = "Restore complete"
                restorationMessage = restored == 0 ? "All days in this backup are already in your journal. Existing portraits were kept." : "Restored \(restored) missing \(restored == 1 ? "portrait" : "portraits"). Existing days in your journal were kept."
            } catch {
                status = "Restore paused"
                errorMessage = "\(restored) portraits restored so far. Existing days were kept. \(error.localizedDescription) You can retry safely."
            }
        }
        await operation?.value
        if let pending = pendingBackup {
            pendingBackup = nil
            await backUp(pending.filter { $0.modelContext != nil })
        }
    }

    func cancel() { pendingBackup = nil; operation?.cancel() }

    private func startDiscovering() {
        guard query == nil else { return }
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K ENDSWITH %@", NSMetadataItemFSNameKey, ".json")
        queryObservers = [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate].map { name in
            NotificationCenter.default.addObserver(forName: name, object: query, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.receiveQueryResults() }
            }
        }
        self.query = query
        query.start()
    }

    private func receiveQueryResults() {
        guard let query, let root else { return }
        query.disableUpdates()
        defer { query.enableUpdates() }
        let urls = query.results.compactMap { ($0 as? NSMetadataItem)?.value(forAttribute: NSMetadataItemURLKey) as? URL }
        mergeDiscovered(urls.filter { $0.deletingLastPathComponent().standardizedFileURL == root.appendingPathComponent("Snapshots").standardizedFileURL })
    }

    private func mergeDiscovered(_ urls: [URL]) {
        backups = Set(backups.map(\.url) + urls).sorted { $0.lastPathComponent > $1.lastPathComponent }.map(BackupSummary.init)
        if lastBackup == nil { lastBackup = backups.first?.date }
    }
}

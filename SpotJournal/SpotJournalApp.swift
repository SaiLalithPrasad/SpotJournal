import SwiftUI
import SwiftData
import MapKit

@main
struct SpotJournalApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: JournalEntry.self, Tag.self, Mood.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(appState.isDark ? .dark : .light)
                .onAppear {
                    appState.modelContext = container.mainContext
                    seedIfNeeded(context: container.mainContext)
                    seedMoodsIfNeeded(context: container.mainContext)
                    processPendingShares(context: container.mainContext)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        processPendingShares(context: container.mainContext)
                        appState.refreshTrigger += 1
                    }
                }
        }
        .modelContainer(container)
    }

    private func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<JournalEntry>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for entry in makeSampleEntries() {
            context.insert(entry)
        }
        try? context.save()
    }

    private func seedMoodsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Mood>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for seed in Mood.defaultSeeds {
            context.insert(Mood(name: seed.name, emoji: seed.emoji, colorHex: seed.colorHex))
        }
        try? context.save()
    }

    private func processPendingShares(context: ModelContext) {
        let pending = SharedContainer.consumePending()
        guard !pending.isEmpty else { return }

        for item in pending {
            let filenames = item.images.compactMap { try? PhotoStore.save($0) }
            guard !filenames.isEmpty else { continue }

            let entry = JournalEntry(
                id: JournalEntry.generateId(),
                photoFileNames: filenames,
                caption: item.meta.caption.isEmpty ? "\u{2014}" : item.meta.caption,
                date: item.meta.date ?? Date(),
                place: "",
                importedAt: Date()
            )
            context.insert(entry)

            // Reverse geocode in background if coordinates are available
            if let lat = item.meta.latitude, let lon = item.meta.longitude {
                let entryId = entry.id
                Task {
                    let place = await PhotoMetadata.reverseGeocode(latitude: lat, longitude: lon)
                    await MainActor.run {
                        if let found = try? context.fetch(
                            FetchDescriptor<JournalEntry>(
                                predicate: #Predicate { $0.id == entryId }
                            )
                        ).first {
                            found.place = place
                            try? context.save()
                        }
                    }
                }
            }
        }
        try? context.save()
    }
}

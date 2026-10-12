import Foundation
import Testing
@testable import GreenhouseMonitor

@MainActor
struct ReadingStoreTests {
    @Test func appendKeepsReadingsOrdered() {
        let store = ReadingStore(fileURL: nil)

        store.append([TestData.reading(id: "b", minutesAgo: 1)], for: "s-1")
        store.append([TestData.reading(id: "a", minutesAgo: 5)], for: "s-1")

        #expect(store.readings(for: "s-1").map(\.id) == ["b", "a"])
        #expect(store.latestReading(for: "s-1")?.id == "b")
    }

    @Test func cachePersistsAcrossInstances() {
        let fileURL = TestData.temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let original = ReadingStore(fileURL: fileURL)
        original.replaceSensors(TestData.sensors)
        original.append([TestData.reading(id: "r-1", minutesAgo: 2)], for: "s-1")

        let reloaded = ReadingStore(fileURL: fileURL)

        #expect(reloaded.sensors == TestData.sensors)
        #expect(reloaded.readings(for: "s-1").map(\.id) == ["r-1"])
    }

    @Test func removeAllReadingsKeepsSensors() {
        let store = ReadingStore(fileURL: nil)
        store.replaceSensors(TestData.sensors)
        store.append([TestData.reading(id: "r-1", minutesAgo: 2)], for: "s-1")

        store.removeAllReadings()

        #expect(store.sensors == TestData.sensors)
        #expect(store.readings(for: "s-1").isEmpty)
    }
}

import Testing
import Foundation
import UIKit
@testable import SpotJournal

struct PhotoStoreTests {

    // Helper to create a small test JPEG
    private func makeTestJPEG() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        return image.jpegData(compressionQuality: 0.5)!
    }

    @Test func saveReturnsFilename() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        #expect(filename.hasPrefix("IMG_"))
        #expect(filename.hasSuffix(".jpg"))

        // Cleanup
        PhotoStore.delete(filename)
    }

    @Test func saveAndLoadRoundTrip() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)

        let loaded = PhotoStore.load(filename)
        #expect(loaded != nil)

        PhotoStore.delete(filename)
    }

    @Test func loadDataReturnsBytes() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)

        let loadedData = PhotoStore.loadData(filename)
        #expect(loadedData != nil)
        #expect(!loadedData!.isEmpty)

        PhotoStore.delete(filename)
    }

    @Test func deleteRemovesFile() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)

        PhotoStore.delete(filename)

        let loaded = PhotoStore.load(filename)
        #expect(loaded == nil)
    }

    @Test func loadNonexistentReturnsNil() {
        let result = PhotoStore.load("nonexistent_file_12345.jpg")
        #expect(result == nil)
    }

    @Test func loadDataNonexistentReturnsNil() {
        let result = PhotoStore.loadData("nonexistent_file_12345.jpg")
        #expect(result == nil)
    }

    @Test func savedFilenamesAreUnique() throws {
        let data = makeTestJPEG()
        let f1 = try PhotoStore.save(data)
        let f2 = try PhotoStore.save(data)
        #expect(f1 != f2)

        PhotoStore.delete(f1)
        PhotoStore.delete(f2)
    }
}

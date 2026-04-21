import Testing
import Foundation
@testable import SpotJournal

struct CaptionParsingTests {

    // MARK: - parseCaptionBlocks

    @Test func emptyStringReturnsNoBlocks() {
        let blocks = parseCaptionBlocks("")
        #expect(blocks.isEmpty)
    }

    @Test func plainTextReturnsSingleProse() {
        let blocks = parseCaptionBlocks("Hello world")
        #expect(blocks.count == 1)
        if case .prose(let text) = blocks[0] {
            #expect(text == "Hello world")
        } else {
            Issue.record("Expected prose block")
        }
    }

    @Test func multilinePloseJoined() {
        let blocks = parseCaptionBlocks("Line one\nLine two\nLine three")
        #expect(blocks.count == 1)
        if case .prose(let text) = blocks[0] {
            #expect(text.contains("Line one"))
            #expect(text.contains("Line three"))
        } else {
            Issue.record("Expected prose block")
        }
    }

    @Test func bulletLines() {
        let text = "- First item\n- Second item\n- Third item"
        let blocks = parseCaptionBlocks(text)
        #expect(blocks.count == 3)

        for block in blocks {
            if case .bullet = block {
                // ok
            } else {
                Issue.record("Expected bullet block, got: \(block)")
            }
        }

        if case .bullet(let item) = blocks[0] {
            #expect(item == "First item")
        }
        if case .bullet(let item) = blocks[2] {
            #expect(item == "Third item")
        }
    }

    @Test func numberedLines() {
        let text = "1. Preheat oven\n2. Mix flour\n3. Bake"
        let blocks = parseCaptionBlocks(text)
        #expect(blocks.count == 3)

        if case .numbered(let n, let item) = blocks[0] {
            #expect(n == 1)
            #expect(item == "Preheat oven")
        } else {
            Issue.record("Expected numbered block")
        }

        if case .numbered(let n, let item) = blocks[2] {
            #expect(n == 3)
            #expect(item == "Bake")
        } else {
            Issue.record("Expected numbered block")
        }
    }

    @Test func mixedContent() {
        let text = "My Recipe\n- flour\n- sugar\n1. Mix\n2. Bake\nEnjoy!"
        let blocks = parseCaptionBlocks(text)

        // Should be: prose("My Recipe"), bullet, bullet, numbered, numbered, prose("Enjoy!")
        #expect(blocks.count == 6)

        if case .prose(let t) = blocks[0] { #expect(t == "My Recipe") }
        if case .bullet(let t) = blocks[1] { #expect(t == "flour") }
        if case .bullet(let t) = blocks[2] { #expect(t == "sugar") }
        if case .numbered(let n, _) = blocks[3] { #expect(n == 1) }
        if case .numbered(let n, _) = blocks[4] { #expect(n == 2) }
        if case .prose(let t) = blocks[5] { #expect(t == "Enjoy!") }
    }

    @Test func bulletWithoutSpaceIsNotBullet() {
        let blocks = parseCaptionBlocks("-nospace")
        #expect(blocks.count == 1)
        if case .prose = blocks[0] {
            // correct — "- " prefix required
        } else {
            Issue.record("Expected prose for '-nospace'")
        }
    }

    @Test func numberedWithoutSpaceIsNotNumbered() {
        let blocks = parseCaptionBlocks("1.nospace")
        #expect(blocks.count == 1)
        if case .prose = blocks[0] {
            // correct — "N. " prefix required
        } else {
            Issue.record("Expected prose for '1.nospace'")
        }
    }

    @Test func highNumberedItems() {
        let blocks = parseCaptionBlocks("42. Answer to everything")
        #expect(blocks.count == 1)
        if case .numbered(let n, let item) = blocks[0] {
            #expect(n == 42)
            #expect(item == "Answer to everything")
        }
    }

    // MARK: - Font Helpers

    @Test func captionLineSpacingValues() {
        #expect(captionLineSpacing(for: .hand) == 2)
        #expect(captionLineSpacing(for: .serif) == 6)
        #expect(captionLineSpacing(for: .sans) == 6)
    }

    @Test func captionSizeHandGetsBoost() {
        #expect(captionSize(for: .hand, base: 16) == 24) // +8
        #expect(captionSize(for: .serif, base: 16) == 16)
        #expect(captionSize(for: .sans, base: 16) == 16)
    }
}

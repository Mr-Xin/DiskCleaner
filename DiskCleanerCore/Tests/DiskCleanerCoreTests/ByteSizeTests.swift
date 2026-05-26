import Testing
@testable import DiskCleanerCore

struct ByteSizeTests {

    @Test func formatsSmallCountsInBytes() {
        #expect(ByteSize.formatted(0) == "0 B")
        #expect(ByteSize.formatted(512) == "512 B")
        #expect(ByteSize.formatted(1023) == "1023 B")
    }

    @Test func formatsLargerCountsWithUnits() {
        #expect(ByteSize.formatted(1024) == "1.0 KB")
        #expect(ByteSize.formatted(1536) == "1.5 KB")
        #expect(ByteSize.formatted(1_048_576) == "1.0 MB")
        #expect(ByteSize.formatted(1_073_741_824) == "1.0 GB")
    }
}

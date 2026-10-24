import Foundation
import MidgarCore
import Testing

@testable import aotd

struct DiagnosticsTests {
    @Test func theLogFileKeepsItsOldName() {
        #expect(AotdMidgar.logFileName == "aotd.log")
    }

    @Test func metadataIsAppendedSortedByKey() {
        let line = Diagnostics.attach(["zeta": 1, "alpha": "a"], to: "Saved")
        #expect(line == "Saved | alpha: a, zeta: 1")
    }

    @Test func emptyMetadataLeavesTheMessageAlone() {
        #expect(Diagnostics.attach([:], to: "Saved") == "Saved")
    }
}

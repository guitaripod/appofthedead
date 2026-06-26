import XCTest
import GRDB
@testable import aotd

final class OracleExplanationCacheTests: XCTestCase {
    var dbQueue: DatabaseQueue!

    override func setUpWithError() throws {
        dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try OracleExplanationCache.createTable(db)
        }
    }

    override func tearDownWithError() throws {
        dbQueue = nil
    }

    private func insert(
        _ db: Database,
        key: String,
        kind: OracleExplanationCache.Kind = .keyword,
        modelId: String = "model-a",
        text: String = "text",
        lastAccessedAt: Date
    ) throws {
        var record = OracleExplanationCache(
            cacheKey: key,
            kind: kind.rawValue,
            modelId: modelId,
            responseText: text,
            createdAt: lastAccessedAt,
            lastAccessedAt: lastAccessedAt
        )
        try record.insert(db)
    }

    func testMakeKeyIsDeterministic() {
        let a = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: "anubis", input: "karma")
        let b = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: "anubis", input: "karma")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, 64)
    }

    func testMakeKeyNormalizesWhitespace() {
        let tidy = OracleExplanationCache.makeKey(kind: .eternal, modelId: "m", deityId: nil, input: "hello world")
        let messy = OracleExplanationCache.makeKey(kind: .eternal, modelId: "m", deityId: nil, input: "  hello\n\t world  ")
        XCTAssertEqual(tidy, messy)
    }

    func testMakeKeyDistinguishesEveryComponent() {
        let base = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: "anubis", input: "karma")
        let kind = OracleExplanationCache.makeKey(kind: .eternal, modelId: "m", deityId: "anubis", input: "karma")
        let model = OracleExplanationCache.makeKey(kind: .keyword, modelId: "n", deityId: "anubis", input: "karma")
        let deity = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: "odin", input: "karma")
        let input = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: "anubis", input: "samsara")
        XCTAssertEqual(Set([base, kind, model, deity, input]).count, 5)
    }

    func testMakeKeyTreatsNilAndEmptyDeityAlike() {
        let nilDeity = OracleExplanationCache.makeKey(kind: .eternal, modelId: "m", deityId: nil, input: "x")
        let emptyDeity = OracleExplanationCache.makeKey(kind: .eternal, modelId: "m", deityId: "", input: "x")
        XCTAssertEqual(nilDeity, emptyDeity)
    }

    func testFetchTextMissReturnsNil() throws {
        try dbQueue.write { db in
            XCTAssertNil(try OracleExplanationCache.fetchText(db, key: "missing"))
        }
    }

    func testUpsertThenFetchReturnsText() throws {
        let key = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: "anubis", input: "karma")
        try dbQueue.write { db in
            try OracleExplanationCache.upsert(db, key: key, kind: .keyword, modelId: "m", text: "The weighing of the heart.")
            XCTAssertEqual(try OracleExplanationCache.fetchText(db, key: key), "The weighing of the heart.")
        }
    }

    func testUpsertOverwritesExistingKey() throws {
        let key = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: "anubis", input: "karma")
        try dbQueue.write { db in
            try OracleExplanationCache.upsert(db, key: key, kind: .keyword, modelId: "m", text: "first")
            try OracleExplanationCache.upsert(db, key: key, kind: .keyword, modelId: "m", text: "second")
            XCTAssertEqual(try OracleExplanationCache.fetchText(db, key: key), "second")
            XCTAssertEqual(try OracleExplanationCache.fetchCount(db), 1)
        }
    }

    func testFetchTextTouchesLastAccessed() throws {
        let key = "touch-me"
        let stale = Date(timeIntervalSince1970: 1000)
        try dbQueue.write { db in
            try insert(db, key: key, lastAccessedAt: stale)
            _ = try OracleExplanationCache.fetchText(db, key: key)
            let row = try OracleExplanationCache.filter(Column("cacheKey") == key).fetchOne(db)
            XCTAssertNotNil(row)
            XCTAssertGreaterThan(row!.lastAccessedAt, stale)
        }
    }

    func testEvictionRemovesLeastRecentlyAccessed() throws {
        let overflow = 3
        let total = OracleExplanationCache.maxEntries + overflow
        try dbQueue.write { db in
            for i in 0..<total {
                try insert(
                    db,
                    key: OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: nil, input: "\(i)"),
                    lastAccessedAt: Date(timeIntervalSince1970: TimeInterval(1000 + i))
                )
            }
            try OracleExplanationCache.evictIfNeeded(db)

            XCTAssertEqual(try OracleExplanationCache.fetchCount(db), OracleExplanationCache.maxEntries)

            for i in 0..<overflow {
                let evictedKey = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: nil, input: "\(i)")
                XCTAssertNil(try OracleExplanationCache.fetchText(db, key: evictedKey))
            }
            let survivorKey = OracleExplanationCache.makeKey(kind: .keyword, modelId: "m", deityId: nil, input: "\(total - 1)")
            XCTAssertNotNil(try OracleExplanationCache.fetchText(db, key: survivorKey))
        }
    }

    func testEvictionNoOpWhenUnderLimit() throws {
        try dbQueue.write { db in
            try insert(db, key: "a", lastAccessedAt: Date(timeIntervalSince1970: 1))
            try insert(db, key: "b", lastAccessedAt: Date(timeIntervalSince1970: 2))
            try OracleExplanationCache.evictIfNeeded(db)
            XCTAssertEqual(try OracleExplanationCache.fetchCount(db), 2)
        }
    }
}

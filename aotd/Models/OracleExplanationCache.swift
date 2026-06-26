import Foundation
import GRDB
import CryptoKit

/// Persisted, deterministic Oracle explanations that are worth reusing verbatim
/// instead of re-running the on-device model every time.
///
/// Scope is intentionally narrow: reference-style explanations whose input is
/// effectively fixed — lesson keyword definitions and "The Eternal" passage
/// readings. The open-ended deity chat is deliberately NOT cached; its value is
/// in a fresh response each time. A hit lets the caller skip loading the model
/// entirely, which is the bulk of the cost on these surfaces.
struct OracleExplanationCache: Codable, FetchableRecord, MutablePersistableRecord {
    var cacheKey: String
    var kind: String
    var modelId: String
    var responseText: String
    var createdAt: Date
    var lastAccessedAt: Date

    static let databaseTableName = "oracle_explanation_cache"

    static let maxEntries = 500

    enum Kind: String {
        case keyword
        case eternal
        case bookText
    }

    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("cacheKey", .text).primaryKey()
            t.column("kind", .text).notNull()
            t.column("modelId", .text).notNull()
            t.column("responseText", .text).notNull()
            t.column("createdAt", .datetime).notNull()
            t.column("lastAccessedAt", .datetime).notNull()
        }
    }

    /// A stable key over everything that determines the response. The free-text
    /// input is whitespace-normalized so trivially different selections collapse
    /// onto one entry, and the model id is folded in so a response produced by
    /// one on-device model is never served while a different model is active.
    static func makeKey(kind: Kind, modelId: String, deityId: String?, input: String) -> String {
        let normalizedInput = input
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let material = [kind.rawValue, modelId, deityId ?? "", normalizedInput].joined(separator: "\u{1f}")
        let digest = SHA256.hash(data: Data(material.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func fetchText(_ db: Database, key: String) throws -> String? {
        guard var entry = try OracleExplanationCache.filter(Column("cacheKey") == key).fetchOne(db) else {
            return nil
        }
        entry.lastAccessedAt = Date()
        try entry.update(db)
        return entry.responseText
    }

    static func upsert(_ db: Database, key: String, kind: Kind, modelId: String, text: String) throws {
        let now = Date()
        var entry = OracleExplanationCache(
            cacheKey: key,
            kind: kind.rawValue,
            modelId: modelId,
            responseText: text,
            createdAt: now,
            lastAccessedAt: now
        )
        try entry.save(db)
        try evictIfNeeded(db)
    }

    static func evictIfNeeded(_ db: Database) throws {
        let count = try OracleExplanationCache.fetchCount(db)
        guard count > maxEntries else { return }
        let staleKeys = try OracleExplanationCache
            .order(Column("lastAccessedAt").asc)
            .limit(count - maxEntries)
            .fetchAll(db)
            .map(\.cacheKey)
        guard !staleKeys.isEmpty else { return }
        _ = try OracleExplanationCache.filter(keys: staleKeys).deleteAll(db)
    }
}

extension OracleExplanationCache {

    /// Returns a previously generated explanation for these inputs, or `nil` on a
    /// miss. Safe to call before the model is loaded — a hit means generation
    /// (and the model load it requires) can be skipped entirely.
    static func cachedResponse(kind: Kind, modelId: String, deityId: String?, input: String) -> String? {
        let key = makeKey(kind: kind, modelId: modelId, deityId: deityId, input: input)
        return try? DatabaseManager.shared.dbQueue.write { db in
            try fetchText(db, key: key)
        }
    }

    static func storeResponse(kind: Kind, modelId: String, deityId: String?, input: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = makeKey(kind: kind, modelId: modelId, deityId: deityId, input: input)
        do {
            try DatabaseManager.shared.dbQueue.write { db in
                try upsert(db, key: key, kind: kind, modelId: modelId, text: trimmed)
            }
        } catch {
            AppLogger.database.error("Oracle explanation cache write failed: \(error.localizedDescription)")
        }
    }
}

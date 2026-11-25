//
//  PersistentStorage.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 05/11/2026.
//

import Foundation
import SwiftUI

/// Persists a security-scoped bookmark for a user-chosen file so the app can
/// write to it again after relaunch. (A plain URL string stops working once the
/// app is relaunched in the sandbox; a bookmark keeps the access grant.)
final class PersistedFileStore {
    enum StoreError: LocalizedError {
        case noBookmark
        case accessDenied

        var errorDescription: String? {
            switch self {
            case .noBookmark: return "No file has been selected yet."
            case .accessDenied: return "Could not access the selected file."
            }
        }
    }

    private let key: String
    private let defaults: UserDefaults

    init(key: String = "persistedFileBookmark", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    #if os(macOS)
    private let creationOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
    private let resolutionOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
    #else
    private let creationOptions: URL.BookmarkCreationOptions = []
    private let resolutionOptions: URL.BookmarkResolutionOptions = []
    #endif

    var hasFile: Bool { defaults.data(forKey: key) != nil }

    /// Call with the URL returned by fileImporter / fileExporter / UIDocumentPicker.
    func persist(_ url: URL) throws {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        let bookmark = try url.bookmarkData(
            options: creationOptions,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(bookmark, forKey: key)
    }

    /// Resolves the stored bookmark back into a URL (refreshing it if stale).
    func resolve() throws -> URL {
        guard let bookmark = defaults.data(forKey: key) else { throw StoreError.noBookmark }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: resolutionOptions,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        if isStale { try persist(url) }
        return url
    }

    /// Runs `body` with security-scoped access to the persisted file.
    func withAccess<T>(_ body: (URL) throws -> T) throws -> T {
        let url = try resolve()
        guard url.startAccessingSecurityScopedResource() else { throw StoreError.accessDenied }
        defer { url.stopAccessingSecurityScopedResource() }
        return try body(url)
    }

    /// Overwrites the persisted file's contents.
    /// Non-atomic by default: atomic writes create a temp file next to the
    /// target, which the sandbox may not allow for a single-file grant.
    func write(_ data: Data, atomically: Bool = false) throws {
        try withAccess { url in
            try data.write(to: url, options: atomically ? .atomic : [])
        }
    }

    func write(_ string: String, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else { return }
        try write(data)
    }

    func clear() { defaults.removeObject(forKey: key) }
}

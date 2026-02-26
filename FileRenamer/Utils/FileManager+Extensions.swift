//
//  FileManager+Extensions.swift
//  FileRenamer
//

import Foundation

extension FileManager {
    func renameFile(at url: URL, to newName: String) throws {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)

        if fileExists(atPath: newURL.path) {
            throw NSError(
                domain: "FileRenamer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "文件已存在: \(newName)"])
        }

        try moveItem(at: url, to: newURL)
    }

    func batchRename(files: [(from: URL, to: String)]) throws -> [(
        success: Bool,
        url: URL,
        error: Error?)]
    {
        var results: [(success: Bool, url: URL, error: Error?)] = []

        for (fromURL, newName) in files {
            do {
                try renameFile(at: fromURL, to: newName)
                results.append((success: true, url: fromURL, error: nil))
            } catch {
                results.append((success: false, url: fromURL, error: error))
            }
        }

        return results
    }
}

//
//  ByteFormatter.swift
//  AppVersal
//

import Foundation

public enum ByteFormatter: Sendable {
    public nonisolated static func format(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
}

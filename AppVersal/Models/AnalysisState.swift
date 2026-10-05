//
//  AnalysisState.swift
//  AppVersal
//

import Foundation

public enum AnalysisState<T: Sendable>: Sendable {
    case idle
    case loading(processed: Int, total: Int)
    case loaded(T)
    case empty
    case error(String)

    public nonisolated var isAnalyzing: Bool {
        if case .loading = self { return true }
        return false
    }

    public nonisolated var progressRatio: Double {
        switch self {
        case .loading(let processed, let total):
            guard total > 0 else { return 0.0 }
            return min(1.0, max(0.0, Double(processed) / Double(total)))
        default:
            return 1.0
        }
    }
}

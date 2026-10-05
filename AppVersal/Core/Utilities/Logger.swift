//
//  Logger.swift
//  AppVersal
//

import Foundation
import OSLog

public enum AppLogger: Sendable {
    private static let subsystem = "com.appversal.gallerycleaner"

    public nonisolated static let photos = Logger(subsystem: subsystem, category: "photos")
    public nonisolated static let analysis = Logger(subsystem: subsystem, category: "analysis")
    public nonisolated static let performance = Logger(subsystem: subsystem, category: "performance")
    public nonisolated static let ui = Logger(subsystem: subsystem, category: "ui")
}

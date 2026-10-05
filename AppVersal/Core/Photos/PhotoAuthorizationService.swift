import Foundation
import Photos
import SwiftUI
import Combine
import OSLog

@MainActor
public final class PhotoAuthorizationService: ObservableObject {
    @Published public private(set) var status: PHAuthorizationStatus = .notDetermined

    public init() {
        self.status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    public var isAuthorized: Bool {
        status == .authorized || status == .limited
    }

    public var isLimited: Bool {
        status == .limited
    }

    public func requestAuthorization() async -> PHAuthorizationStatus {
        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.status = newStatus
        AppLogger.photos.info("Photo authorization status updated: \(newStatus.rawValue)")
        return newStatus
    }
}

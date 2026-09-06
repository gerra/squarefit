import Photos

enum PhotoLibraryError: LocalizedError {
    case accessDenied
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "SquareFit needs permission to add photos to your library. You can enable it in Settings."
        case .encodingFailed:
            return "The squared image could not be encoded."
        }
    }
}

/// Saves images to the user's photo library using add-only access,
/// which is the least privilege the app needs.
enum PhotoLibrarySaver {
    static func requestAddOnlyAccess() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return status == .authorized || status == .limited
        default:
            return false
        }
    }

    static func save(jpegData: Data) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: jpegData, options: nil)
        }
    }
}

import PhotosUI
import SwiftUI

/// One picked photo and its processing state.
///
/// Only the compressed source bytes and a small preview are kept in memory.
/// The full-resolution square is produced at save time, one photo at a time,
/// so selecting dozens of large photos does not exhaust memory.
struct PickedPhoto: Identifiable {
    let id = UUID()
    let data: Data
    let preview: UIImage
    var isSaved = false
}

@MainActor
final class SquareFitViewModel: ObservableObject {
    @Published var selection: [PhotosPickerItem] = [] {
        didSet { Task { await loadSelection() } }
    }
    @Published private(set) var photos: [PickedPhoto] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var savedCount = 0
    @Published var alertMessage: String?

    var unsavedCount: Int { photos.filter { !$0.isSaved }.count }

    private static let previewSide: CGFloat = 400

    private func loadSelection() async {
        guard !selection.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        var loaded: [PickedPhoto] = []
        for item in selection {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            // Build the preview off the main thread. Downsample first, then
            // square the small image: same look as the final result, tiny cost.
            let preview = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                autoreleasepool {
                    guard let image = UIImage(data: data) else { return nil }
                    let side = Self.previewSide
                    let scale = min(1, side / max(image.size.width, image.size.height))
                    let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    let small = image.preparingThumbnail(of: target) ?? image
                    return ImageSquarer.square(small)
                }
            }.value
            guard let preview else { continue }
            loaded.append(PickedPhoto(data: data, preview: preview))
        }
        photos.append(contentsOf: loaded)
        selection = []
    }

    func saveAll() async {
        guard !photos.isEmpty, !isSaving else { return }
        isSaving = true
        savedCount = 0
        defer { isSaving = false }

        guard await PhotoLibrarySaver.requestAddOnlyAccess() else {
            alertMessage = PhotoLibraryError.accessDenied.localizedDescription
            return
        }

        var failures = 0
        let pending = photos.filter { !$0.isSaved }.map(\.id)
        for id in pending {
            // Look the photo up by id each time: the user may remove items mid-save.
            guard let photo = photos.first(where: { $0.id == id }) else { continue }
            do {
                let jpeg = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    try autoreleasepool {
                        guard let image = UIImage(data: photo.data) else {
                            throw PhotoLibraryError.encodingFailed
                        }
                        let squared = ImageSquarer.square(image)
                        guard let jpeg = squared.jpegData(compressionQuality: 0.95) else {
                            throw PhotoLibraryError.encodingFailed
                        }
                        return jpeg
                    }
                }.value
                try await PhotoLibrarySaver.save(jpegData: jpeg)
                if let index = photos.firstIndex(where: { $0.id == id }) {
                    photos[index].isSaved = true
                }
                savedCount += 1
            } catch {
                failures += 1
            }
        }

        if failures > 0 {
            alertMessage = "\(failures) photo\(failures == 1 ? "" : "s") could not be saved."
        }
    }

    func remove(_ photo: PickedPhoto) {
        photos.removeAll { $0.id == photo.id }
    }

    func clear() {
        photos.removeAll()
        savedCount = 0
    }
}

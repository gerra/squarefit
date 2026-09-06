import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject private var model = SquareFitViewModel()

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if model.photos.isEmpty && !model.isLoading {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("SquareFit")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !model.photos.isEmpty {
                        Button("Clear", role: .destructive) { model.clear() }
                            .disabled(model.isSaving)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    pickerButton(label: Label("Add", systemImage: "plus"))
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !model.photos.isEmpty { saveBar }
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { model.alertMessage != nil },
                set: { if !$0 { model.alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.alertMessage ?? "")
            }
        }
    }

    // MARK: - Pieces

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.on.square.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Make any photo square")
                .font(.title2.weight(.semibold))
            Text("Pick one or many photos. Each one is padded with a white background to a perfect 1:1 square and saved as a new photo. Your originals are never changed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            pickerButton(label: Label("Choose Photos", systemImage: "photo.on.rectangle.angled"))
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(model.photos) { photo in
                    thumbnail(for: photo)
                }
                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func thumbnail(for photo: PickedPhoto) -> some View {
        Image(uiImage: photo.preview)
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
            )
            .overlay(alignment: .topTrailing) {
                if photo.isSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .green)
                        .font(.title3)
                        .padding(6)
                }
            }
            .contextMenu {
                Button(role: .destructive) {
                    model.remove(photo)
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
    }

    private var saveBar: some View {
        VStack(spacing: 8) {
            if model.isSaving {
                ProgressView(value: Double(model.savedCount), total: Double(model.photos.count))
                Text("Saving \(model.savedCount) of \(model.photos.count)…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    Task { await model.saveAll() }
                } label: {
                    Text(saveButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.unsavedCount == 0 || model.isLoading)

                if model.unsavedCount == 0 {
                    Text("All squared photos are in your library.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.bar)
    }

    private var saveButtonTitle: String {
        let count = model.unsavedCount
        switch count {
        case 0: return "Saved"
        case 1: return "Square & Save 1 Photo"
        default: return "Square & Save \(count) Photos"
        }
    }

    private func pickerButton<L: View>(label: L) -> some View {
        PhotosPicker(
            selection: $model.selection,
            maxSelectionCount: nil, // nil = no limit
            selectionBehavior: .ordered,
            matching: .images,
            photoLibrary: .shared()
        ) {
            label
        }
        .disabled(model.isSaving)
    }
}

#Preview {
    ContentView()
}

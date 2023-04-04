//
//  ImagePicker.swift
//  Guardian
//
//  Created by Teff on 2023/03/19.
//

import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [EpisodeModel.EpisodeImage]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 0 // No limit
        configuration.preselectedAssetIdentifiers = selectedImages.map({ $0.id
        })
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let ids = results.compactMap(\.assetIdentifier)

            parent.selectedImages.removeAll { !ids.contains($0.id) }

            for itemProvider in results {
                loadTransferable(from: itemProvider)
//                if itemProvider.canLoadObject(ofClass: UIImage.self) {
//                    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
//                        guard let self = self else { return }
//                        if let image = image as? UIImage {
//                            let episodeImage = EpisodeModel.EpisodeImage(image: Image(uiImage: image), data: image.jpegData(compressionQuality: 1.0)!)
//                            DispatchQueue.main.async {
//                                self.parent.selectedImages.append(episodeImage)
//                            }
//                        }
//                    }
//                }
            }

            picker.dismiss(animated: true)
        }
        private func loadTransferable(from imageSelection: PHPickerResult) {
            imageSelection.itemProvider.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageData):
                guard let uiImage = UIImage(data: imageData) else {
                    return
                }
                        let episodeImage = EpisodeModel.EpisodeImage(image: Image(uiImage: uiImage), data: imageData, id: imageSelection.assetIdentifier ?? "")
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(episodeImage)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
}

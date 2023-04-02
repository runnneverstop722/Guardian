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
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0 // No limit

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
            let itemProviders = results.map(\.itemProvider)

            parent.selectedImages.removeAll()

            for itemProvider in itemProviders {
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        guard let self = self else { return }
                        if let image = image as? UIImage {
                            let episodeImage = EpisodeModel.EpisodeImage(image: Image(uiImage: image), data: image.jpegData(compressionQuality: 1.0)!)
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(episodeImage)
                            }
                        }
                    }
                }
            }

            picker.dismiss(animated: true)
        }
    }
}

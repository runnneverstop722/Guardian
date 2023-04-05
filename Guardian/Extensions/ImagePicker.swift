//
//  ImagePicker.swift
//  Guardian
//
//  Created by Teff on 2023/03/19.
//

import SwiftUI
import PhotosUI

//MARK: - Episode Photo Picker

struct EpisodePhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [EpisodeModel.EpisodeImage]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
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
        var parent: EpisodePhotoPicker

        init(_ parent: EpisodePhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for itemProvider in results {
                loadTransferable(from: itemProvider)
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
                        let episodeImage = EpisodeModel.EpisodeImage(image: Image(uiImage: uiImage), data: imageData)
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

//MARK: - Diagnosis Photo Picker

struct DiagnosisPhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [DiagnosisModel.DiagnosisImage]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
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
        var parent: DiagnosisPhotoPicker

        init(_ parent: DiagnosisPhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

            for itemProvider in results {
                loadTransferable(from: itemProvider)
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
                        let diagnosisImage = DiagnosisModel.DiagnosisImage(image: Image(uiImage: uiImage), data: imageData)
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(diagnosisImage)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
}

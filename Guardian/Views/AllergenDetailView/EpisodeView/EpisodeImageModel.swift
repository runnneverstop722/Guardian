//
//  EpisodeImageModel.swift
//  Guardian
//
//  Created by Teff on 2023/04/02.
//

import SwiftUI
import PhotosUI

struct EpisodeImageModel: View {
    let imageState: EpisodeModel.ImageState
    
    var body: some View {
        switch imageState {
        case  .success(let image):
            image.resizable()
        case .loading:
            ProgressView()
        case .empty:
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.white)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}
struct CircularEpisodeImage: View {
    let imageState: EpisodeModel.ImageState
    
    var body: some View {
        EpisodeImageModel(imageState: imageState)
            .aspectRatio(contentMode: .fill)
            .frame(width: 80, height: 80)
            .background {
                RoundedRectangle(cornerRadius: 10).fill(
                    LinearGradient(
                        colors: [.indigo, .blue],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
    }
}

struct EditableCircularEpisodeImage: View {
    @ObservedObject var viewModel: EpisodeModel
    
    var body: some View {
        CircularEpisodeImage(imageState: viewModel.imageState)
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $viewModel.imageSelection,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                             .buttonStyle(.borderless)
            }
    }
}

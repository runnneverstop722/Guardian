//
//  ProfilePhotoView.swift
//  Guardian
//
//  Created by Teff on 2023/03/18.
//

import SwiftUI

//MARK: - Photo View
struct ProfilePhotoView: View {
    
    //MARK: - Size
    enum Size: Double {
        //MARK: - Cases
        case cell
        case detail
        
        //MARK: - Funtions
        func width(isPlaceHolder: Bool = false) -> Double {
            switch self {
            case .cell:
                return isPlaceHolder ? 45.0 : 50.0
                
            case .detail:
                return isPlaceHolder ? 100.0 : 150.0
            }
        }
    }
    //MARK: - Properties
    var photoData: Data?
    var size: Size
    
    //MARK: - Body
    var body: some View {
        if let photoData,
           let uiImage = UIImage(data: photoData) {
            let imageSize = size.width(isPlaceHolder: false)
            
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(10)
        } else {
            let imageSize = size.width()
            
            Image(systemName: "photo")
                .foregroundColor(.accentColor)
                .font(.system(size: imageSize))
        }
    }
}
//MARK: - Preview Provider
struct ProfilePhotoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfilePhotoView(size: .cell)
            ProfilePhotoView(size: .detail)
        }
    }
}

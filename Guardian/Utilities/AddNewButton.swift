//
//  AddNewButton.swift
//  Guardian
//
//  Created by Taehoon Lee on 2023/05/10.
//

import SwiftUI

struct AddNewButton: View {
    var action: () -> Void
    var image: Image
    var gradient: Gradient
    
    var body: some View {
        Button(action: action) {
            image
                .font(.title3)
                .foregroundColor(.white)
        }
        .padding(10)
        .background(LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom))
        .clipShape(Circle())
//        .shadow(color: .gray, radius: 6, x: 0, y: 0)
        .overlay(Circle().stroke(LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom), lineWidth: 5))
    }
}

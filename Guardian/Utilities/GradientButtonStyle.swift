//
//  GradientButtonStyle.swift
//  Guardian
//
//  Created by Taehoon Lee on 2023/04/28.
//

import SwiftUI

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(Color(uiColor: .white))
            .frame(maxWidth: 280)
            .bold()
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.indigo]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(15.0)
            .shadow(radius: 3)
    }
}

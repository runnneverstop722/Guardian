//
//  Neumorphism.swift
//  Guardian
//
//  Created by Teff on 2023/05/11.
//

import SwiftUI

extension Color {
    static let offWhite = Color(red: 255/255, green: 225/255, blue: 235/255)
}
extension View {
    func NeumorphicStyle() -> some View {
        self.padding(30)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x:10, y: 10)
            .shadow(color: Color.white.opacity(0.7), radius: 10, x:-5, y: -5)
    }
}

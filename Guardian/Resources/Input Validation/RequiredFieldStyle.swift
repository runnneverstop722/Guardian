//
//  RequiredFieldStyle.swift
//  Guardian
//
//  Created by Teff on 2023/04/18.
//

import SwiftUI

struct RequiredFieldStyle: TextFieldStyle {
    var isEmpty: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(isEmpty ? Color.red.opacity(0.3) : Color.clear)
            .cornerRadius(5)
//            .overlay(RoundedRectangle(cornerRadius: 5)
//                .stroke(isEmpty ? Color.red : Color.gray, lineWidth: 1))
    }
}

struct RowBackground: View {
    var isEmpty: Bool
    
    var body: some View {
        Rectangle()
            .fill(isEmpty ? Color.red.opacity(0.3) : Color(UIColor.systemBackground))
            .cornerRadius(5)
    }
}


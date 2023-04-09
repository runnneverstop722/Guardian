//
//  CustomTextField.swift
//  Guardian
//
//  Created by Teff on 2023/04/09.
//

import SwiftUI

struct CustomTextField: UIViewRepresentable {

    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> CustomUITextField {
        let textField = CustomUITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        return textField
    }

    func updateUIView(_ uiView: CustomUITextField, context: Context) {
        uiView.text = text
    }

    class Coordinator: NSObject, UITextFieldDelegate {

        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}


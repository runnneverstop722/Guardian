//
//  KeyboardDismissViewModifier.swift
//  Guardian
//
//  Created by Teff on 2023/04/12.
//

import SwiftUI
import UIKit

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct KeyboardDismissViewModifier: ViewModifier {
    var gesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { _ in
                UIApplication.shared.dismissKeyboard()
            }
    }
    func body(content: Content) -> some View {
        content
            .gesture(gesture)
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func keyboardDismissGesture() -> some View {
        self.modifier(KeyboardDismissViewModifier())
    }
}

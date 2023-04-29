//
//  LoadingAlert.swift
//  Guardian
//
//  Created by Teff on 2023/04/27.
//

import SwiftUI

struct LoadingAlert: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2.0)
                .padding()
            Text("Loading...")
        }
        .frame(width: 200, height: 200)
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<BlurView>) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
struct LoadingAlert_Previews: PreviewProvider {
    static var previews: some View {
        LoadingAlert()
    }
}
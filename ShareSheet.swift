//
//  ShareSheet.swift
//  Guardian
//
//  Created by Teff on 2023/04/23.
//

import SwiftUI
import MobileCoreServices

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        var items: [Any] = []
        
        for item in activityItems {
            if let url = item as? URL {
                do {
                    let data = try Data(contentsOf: url)
                    let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypePDF as String)
                    items.append(itemProvider)
                } catch {
                    print("Error converting URL to Data: \(error)")
                }
            } else {
                items.append(item)
            }
        }
        
        let controller = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {

    }
}

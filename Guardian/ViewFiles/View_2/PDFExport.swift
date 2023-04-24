//
//  PDFExport.swift
//  Guardian
//
//  Created by Teff on 2023/04/23.
//

import PDFKit
import CoreData

class PDFExport {
    private let profile: ProfileInfoEntity
    private let viewContext: NSManagedObjectContext

    init(profile: ProfileInfoEntity, viewContext: NSManagedObjectContext) {
        self.profile = profile
        self.viewContext = viewContext
    }

    func createPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Guardian ~Food Allergy~",
            kCGPDFContextAuthor: "SwifTeff"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()
            // Add the code to draw the PDF content here
            // Draw the logo image
            if let logoImage = UIImage(named: "Logo") {
                let logoRect = CGRect(x: (pageRect.width - 200) / 2.0, y: 30, width: 200, height: 200)
                logoImage.draw(in: logoRect)
            }
            // Draw the rest of the PDF content
            let pdfContent = PDFContent(profile: profile, viewContext: viewContext)
            pdfContent.draw(in: context.cgContext, pageRect: pageRect)
        }
        return data
    }
}

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
    
    private let topPadding: CGFloat = 20
    private let bottomPadding: CGFloat = 50
    private let leftPadding: CGFloat = 50
    private let rightPadding: CGFloat = 50
    
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
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)// A4, 72 dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            if let logoImage = UIImage(named: "Logo") {
                let resizeImage = logoImage.scaleImageToSize(newSize: CGSize(width: 200, height: 100))
                let logoRect = CGRect(x: (pageRect.width/2.0) - 100, y: topPadding, width: 200, height: 100)
                resizeImage.draw(in: logoRect)
            }
            
            let pdfContent = PDFContent(profile: profile, viewContext: viewContext)
            let logoBottomYPosition: CGFloat = topPadding + 120
            pdfContent.drawPageContent(in: context, pageRect: pageRect, textTop: logoBottomYPosition)
        }
        return data
    }
    
    func drawPageNumber(_ context: CGContext, pageRect: CGRect, pageNumber: Int) {
        let font = UIFont.systemFont(ofSize: 12)
        let pageNumberString = "Page \(pageNumber)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let attributedPageNumber = NSAttributedString(string: pageNumberString, attributes: attributes)
        let textSize = attributedPageNumber.size()
        
        let xPosition = pageRect.midX - textSize.width / 2.0
        let yPosition = pageRect.height - bottomPadding + 10
        
        attributedPageNumber.draw(at: CGPoint(x: xPosition, y: yPosition))
    }
}

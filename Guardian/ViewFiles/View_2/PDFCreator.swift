//
//  PDFCreator.swift
//  Guardian
//
//  Created by Teff on 2023/04/23.
//

import SwiftUI
import PDFKit

class PDFCreator {
    func createPDF(from records: [Any]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Guardian ~Food Allergy~",
            kCGPDFContextAuthor: "SwifTeff"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x:0, y:0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let title = "Exported Your Data"
            let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont
            ]
            let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
            let titleStringSize = attributedTitle.size()
            let titleStringRect = CGRect(x: (pageRect.width - titleStringSize.width) / 2.0, y: 30, width: titleStringSize.width, height: titleStringSize.height)
            attributedTitle.draw(in: titleStringRect)
            
            var textTop = titleStringRect.origin.y + titleStringRect.height + 30
            
            for record in records {
                let recordText = "\(record)"
                let recordFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                let recordAttributes: [NSAttributedString.Key: Any] = [
                    .font: recordFont
                ]
                let attributedRecord = NSAttributedString(string: recordText, attributes: recordAttributes)
                let recordStringRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40, height: attributedRecord.size().height)
                attributedRecord.draw(in: recordStringRect)
                
                textTop += recordStringRect.height + 10
            }
        }
        return data
    }
}

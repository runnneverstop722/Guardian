//
//  PDFContent.swift
//  Guardian
//
//  Created by Teff on 2023/04/23.
//

import UIKit
import CoreData

class PDFContent {
    
    private let profile: ProfileInfoEntity
    private let viewContext: NSManagedObjectContext
    private let allergenImages: [String:String] = [
        "えび": "shrimp", "かに": "crab", "小麦": "wheat", "そば": "buckwheat", "卵": "egg", "乳": "milk", "落花生(ピーナッツ)": "peanut", "アーモンド": "almond", "あわび": "abalone", "いか": "squid",  "いくら": "salmonroe", "オレンジ": "orange", "カシューナッツ": "cashewnut", "キウイフルーツ": "kiwi", "牛肉": "beef", "くるみ": "walnut", "ごま": "sesame", "さけ": "salmon", "さば": "makerel", "大豆": "soybean", "鶏肉": "chicken", "バナナ": "banana", "豚肉": "pork", "まつたけ": "matsutake", "もも": "peach", "やまいも": "yam", "りんご": "apple", "ゼラチン": "gelatine"
    ]
    init(profile: ProfileInfoEntity, viewContext: NSManagedObjectContext) {
        self.profile = profile
        self.viewContext = viewContext
    }
    
    func drawPageContent(in renderer: UIGraphicsPDFRendererContext, pageRect: CGRect, textTop: CGFloat){
        let context = renderer.cgContext
        // Draw the content
        var textTop = textTop
        // Draw the selected profile's first name with string "'s records"
        let profileName = "\(profile.firstName ?? "")の記録"
        let profileNameFont = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        let profileNameAttributes: [NSAttributedString.Key: Any] = [
            .font: profileNameFont
        ]
        let attributedProfileName = NSAttributedString(string: profileName, attributes: profileNameAttributes)
        let profileNameStringSize = attributedProfileName.getSize(withPreferredWidth: pageRect.width - 40)
        let profileNameStringRect = CGRect(x: (pageRect.width - profileNameStringSize.width) / 2.0, y: textTop, width: profileNameStringSize.width, height: profileNameStringSize.height)
        attributedProfileName.draw(in: profileNameStringRect)
        
        textTop += profileNameStringSize.height
        // Draw the divider
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 20, y: textTop + 10))
        context.addLine(to: CGPoint(x: pageRect.width - 20, y: textTop + 10))
        context.strokePath()
        textTop += 20
        // Fetch necessary data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let allergensData = fetchAllergenData(for: profile)
        let diagnosisData = fetchDiagnosisData(for: profile)
            .sorted { $0.diagnosisDate ?? Date() < $1.diagnosisDate ?? Date() }
        // Draw diagnosis data
        if !diagnosisData.isEmpty {
            let diagnosisTitle = "診断記録"
            let diagnosisTitleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let diagnosisTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: diagnosisTitleFont
            ]
            let attributedDiagnosisTitle = NSAttributedString(string: diagnosisTitle, attributes: diagnosisTitleAttributes)
            let diagnosisTitleStringSize = attributedDiagnosisTitle.getSize(withPreferredWidth: pageRect.width - 40)
            let diagnosisTitleStringRect = CGRect(x: 20, y: textTop, width: diagnosisTitleStringSize.width, height: diagnosisTitleStringSize.height)
            attributedDiagnosisTitle.draw(in: diagnosisTitleStringRect)
            
            textTop += diagnosisTitleStringSize.height + 10
            
            for (index,diagnosis) in diagnosisData.enumerated() {
                let items = [
                    ("⚫︎診断記録: ", "#\(index + 1)"),
                    ("・診断日: ", dateFormatter.string(from: diagnosis.diagnosisDate ?? Date())),
                    ("・診断名: ", diagnosis.diagnosis ?? ""),
                    ("・アレルゲン: ", (diagnosis.allergens?.joined(separator: ", ") ?? "")),
                    ("・医療機関名: ", diagnosis.diagnosedHospital ?? ""),
                    ("・担当医: ", diagnosis.diagnosedAllergist ?? ""),
                    ("・担当医コメント: ", diagnosis.diagnosedAllergistComment ?? ""),
                    ("・添付写真: ", " ")
                ]
                
                let itemFont = UIFont.systemFont(ofSize: 12.0)
                
                for (label, value) in items {
                    let itemText = "\(label)\(value)"
                    let itemTextAttributes: [NSAttributedString.Key: Any] = [
                        .font: itemFont
                    ]
                    let attributedItemText = NSAttributedString(string: itemText, attributes: itemTextAttributes)
                    let itemTextSize = attributedItemText.getSize(withPreferredWidth: pageRect.width - 40)
                    let itemTextRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40, height: itemTextSize.height)
                    attributedItemText.draw(in: itemTextRect)
                    
                    textTop += itemTextSize.height + 6
                    
                    textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
                }
                textTop += 10
                textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
                
                // Render Diagnosis Photo
                let diagnosisPhoto = diagnosis.diagnosisPhoto ?? []
                if !diagnosisPhoto.isEmpty {
                    textTop = drawImageWithShadow(rendererContext: renderer, images: diagnosisPhoto, pageRect: pageRect, startY: textTop)
                }
            }
        } else {
            let noDiagnosisMessage = "⚠️診断記録がありません。"
            let noDiagnosisFont = UIFont.systemFont(ofSize: 12.0)
            let position = CGPoint(x: 20, y: textTop)
            textTop = drawText(message: noDiagnosisMessage, font: noDiagnosisFont, position: position, maxWidth: pageRect.width - 40)
        }
        textTop += 100
        let areaGuidanceMessage = "ここより以下はアレルゲン別の 「医療検査記録」 及び 「発症記録」 です。"
        let areaGuidanceMessageFont = UIFont.systemFont(ofSize: 12.0)
        let position = CGPoint(x: 20, y: textTop)
        textTop = drawText(message: areaGuidanceMessage, font: areaGuidanceMessageFont, position: position, maxWidth: pageRect.width - 40, alignment: .left, textColor: .gray)
        
        // Draw the divider
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.gray.cgColor)
        context.move(to: CGPoint(x: 20, y: textTop))
        context.addLine(to: CGPoint(x: pageRect.width - 20, y: textTop))
        context.strokePath()
        textTop += 10
        
        for allergen in allergensData {
            let allergenName = allergen.allergen!
            var offsetX: CGFloat = 20
            var offsetY: CGFloat = 0
            if let logoImage = UIImage(named: allergenImages[allergenName] ?? "") {
                let logoRect = CGRect(x: 20, y: textTop, width: 40, height: 40)
                logoImage.draw(in: logoRect)
                offsetX += 60
                offsetY = 40
            }
            
            let allergenNameFont = UIFont.systemFont(ofSize: 16.0, weight: .bold)
            let allergenNameAttributes: [NSAttributedString.Key: Any] = [
                .font: allergenNameFont
            ]
            let attributedAllergenName = NSAttributedString(string: allergenName, attributes: allergenNameAttributes)
            let allergenNameStringSize = attributedAllergenName.getSize(withPreferredWidth: pageRect.width - 40)
            let allergenNameStringRect = CGRect(x: offsetX, y: textTop + 10, width: allergenNameStringSize.width, height: allergenNameStringSize.height)
            attributedAllergenName.draw(in: allergenNameStringRect)
            textTop += 10
            textTop += offsetY
            textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
            
            // Draw medical data title
            let medicalTestTitle = "医療検査記録:"
            let medicalTestTitleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let medicalTestTitleAttributes: [NSAttributedString.Key: Any] = [.font: medicalTestTitleFont ]
            let attributedMedicalTestTitle = NSAttributedString(string: medicalTestTitle, attributes: medicalTestTitleAttributes)
            let medicalTestTitleStringSize = attributedMedicalTestTitle.getSize(withPreferredWidth: pageRect.width - 40)
            let medicalTestTitleStringRect = CGRect(x: 20, y: textTop, width: medicalTestTitleStringSize.width, height: medicalTestTitleStringSize.height)
            attributedMedicalTestTitle.draw(in: medicalTestTitleStringRect)
            textTop += medicalTestTitleStringSize.height + 10
            
            // Draw medical data
            let allergenID = allergen.recordID!
            let bloodTests = PersistenceController.shared.fetchBloodTest(allergenID: allergenID)
                .sorted { $0.bloodTestDate ?? Date() < $1.bloodTestDate ?? Date() }
            if bloodTests.isEmpty {
                textTop = drawText(message: "⚠️血液検査記録がありません。", font: UIFont.systemFont(ofSize: 12.0), position: CGPoint(x: 20, y: textTop), maxWidth: pageRect.width - 40)
            }
            for (index, bloodTest) in bloodTests.enumerated() {
                let items = [
                    ("⚫︎血液検査記録: ", "#\(index + 1)"),
                    ("・検査日: ", dateFormatter.string(from: bloodTest.bloodTestDate ?? Date())),
                    ("・IgEレベル(UA/mL): ", bloodTest.bloodTestLevel ?? "0.0"),
                    ("・結果: ", bloodTest.bloodTestGrade)
                ]
                
                let itemFont = UIFont.systemFont(ofSize: 12.0)
                
                for (label, value) in items {
                    let itemText = "\(label)\(value!)"
                    let itemTextAttributes: [NSAttributedString.Key: Any] = [
                        .font: itemFont
                    ]
                    let attributedItemText = NSAttributedString(string: itemText, attributes: itemTextAttributes)
                    let itemTextSize = attributedItemText.getSize(withPreferredWidth: pageRect.width - 40)
                    let itemTextRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40,height: itemTextSize.height)
                    attributedItemText.draw(in: itemTextRect)
                    textTop += itemTextSize.height + 6
                    textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
                }
                textTop += 10
                textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
            }
            let skinTests = PersistenceController.shared.fetchSkinTest(allergenID: allergenID)
                .sorted { $0.skinTestDate ?? Date() < $1.skinTestDate ?? Date() }
            if skinTests.isEmpty {
                textTop = drawText(message: "⚠️皮膚プリック検査記録がありません。", font: UIFont.systemFont(ofSize: 12.0), position: CGPoint(x: 20, y: textTop), maxWidth: pageRect.width - 40)
            }
            for (index, skinTest) in skinTests.enumerated() {
                let items = [
                    ("⚫︎皮膚プリック検査記録: ", "#\(index + 1)"),
                    ("・検査日: ", dateFormatter.string(from: skinTest.skinTestDate ?? Date())),
                    ("・膨疹直径(mm): ", skinTest.skinTestResultValue ?? "0.0"),
                    ("・結果: ", skinTest.skinResult ?? "陰性(-)")
                ]
                
                let itemFont = UIFont.systemFont(ofSize: 12.0)
                
                for (label, value) in items {
                    let itemText = "\(label)\(value)"
                    let itemTextAttributes: [NSAttributedString.Key: Any] = [
                        .font: itemFont
                    ]
                    let attributedItemText = NSAttributedString(string: itemText, attributes: itemTextAttributes)
                    let itemTextSize = attributedItemText.getSize(withPreferredWidth: pageRect.width - 40)
                    let itemTextRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40,height: itemTextSize.height)
                    attributedItemText.draw(in: itemTextRect)
                    textTop += itemTextSize.height + 6
                    textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
                }
                textTop += 10
                textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
            }
            let oralFoodChallenges = PersistenceController.shared.fetchOralFoodChallenge(allergenID: allergenID)
                .sorted { $0.oralFoodChallengeDate ?? Date() < $1.oralFoodChallengeDate ?? Date() }
            if oralFoodChallenges.isEmpty {
                textTop = drawText(message: "⚠️食物経口負荷試験記録がありません。", font: UIFont.systemFont(ofSize: 12.0), position: CGPoint(x: 20, y: textTop), maxWidth: pageRect.width - 40)
            }
            for (index, oralFoodChallenge) in oralFoodChallenges.enumerated() {
                dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
                
                // Split the oralFoodChallengeQuantity into quantity and unit
                let quantity = oralFoodChallenge.oralFoodChallengeQuantity ?? "0.0"
                let unit = oralFoodChallenge.oralFoodChallengeUnit ?? ""
                
                let items = [
                    ("⚫︎食物経口負荷試験記録: ", "#\(index + 1)"),
                    ("・検査日: ", dateFormatter.string(from: oralFoodChallenge.oralFoodChallengeDate ?? Date())),
                    ("・総負荷量: ", "\(quantity) \(unit)"),
                    ("・結果: ", oralFoodChallenge.ofcResult ?? "陰性(-)")
                ]
                
                let itemFont = UIFont.systemFont(ofSize: 12.0)
                
                for (label, value) in items {
                    let itemText = "\(label)\(value)"
                    let itemTextAttributes: [NSAttributedString.Key: Any] = [
                        .font: itemFont
                    ]
                    let attributedItemText = NSAttributedString(string: itemText, attributes: itemTextAttributes)
                    let itemTextSize = attributedItemText.getSize(withPreferredWidth: pageRect.width - 40)
                    let itemTextRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40,height: itemTextSize.height)
                    attributedItemText.draw(in: itemTextRect)
                    textTop += itemTextSize.height + 6
                    textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
                }
                textTop += 10
                textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
            }
            
            // Draw Episode data title
            let episodeTitle = "発症記録:"
            let episodeTitleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let episodeTitleAttributes: [NSAttributedString.Key: Any] = [.font: episodeTitleFont ]
            let attributedEpisodeTitle = NSAttributedString(string: episodeTitle, attributes: episodeTitleAttributes)
            let episodeTitleStringSize = attributedEpisodeTitle.getSize(withPreferredWidth: pageRect.width - 40)
            let episodeTitleStringRect = CGRect(x: 20, y: textTop, width: episodeTitleStringSize.width, height: episodeTitleStringSize.height)
            attributedEpisodeTitle.draw(in: episodeTitleStringRect)
            textTop += episodeTitleStringSize.height + 10
            
            // Draw episodes data
            let episodesData = fetchEpisodesData(for: allergenID)
                .sorted { $0.episodeDate ?? Date() < $1.episodeDate ?? Date() }
            if !episodesData.isEmpty {
                for (index, episode) in episodesData.enumerated() {
                    var items: [(String, String)] = []
                    items.append(("⚫︎発症記録: ", "#\(index + 1)"))
                    items.append(("・発症日: ", dateFormatter.string(from: episode.episodeDate ?? Date())))
                    items.append(("・初症状だった: ", episode.firstKnownExposure ? "はい" : "いいえ"))
                    items.append(("・受診した: ", episode.wentToHospital ? "はい" : "いいえ"))
                    items.append(("・アレルゲンへの触れ方: ", (episode.typeOfExposure?.joined(separator: ", ") ?? "")))
                    items.append(("・摂取量: ", episode.intakeAmount ?? ""))
                    items.append(("・症状: ", (episode.symptoms?.joined(separator: ", ") ?? "")))
                    items.append(("・重症度評価: ", episode.severity ?? ""))
                    items.append(("・発症までの経過時間: ", episode.leadTimeToSymptoms ?? ""))
                    items.append(("・運動後だった: ", episode.didExercise ? "はい" : "いいえ"))
                    items.append(("・取った対応: ", (episode.treatments?.joined(separator: ", ") ?? "")))
                    items.append(("・取った対応（その他）: ", episode.otherTreatment ?? ""))
                    items.append(("・メモ: ", episode.episodeMemo ?? ""))
                    items.append(("・添付写真: ", " "))
                    
                    let itemFont = UIFont.systemFont(ofSize: 12.0)
                    
                    for (label, value) in items {
                        let itemText = "\(label)\(value)"
                        let itemTextAttributes: [NSAttributedString.Key: Any] = [
                            .font: itemFont
                        ]
                        let attributedItemText = NSAttributedString(string: itemText, attributes: itemTextAttributes)
                        let itemTextSize = attributedItemText.getSize(withPreferredWidth: pageRect.width - 40)
                        let itemTextRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40,height: itemTextSize.height)
                        attributedItemText.draw(in: itemTextRect)
                        textTop += itemTextSize.height + 6
                        textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
                    }
                    textTop += 10
                    textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
                    
                    // Render Episode Photo
                    let episodePhoto = episode.episodePhoto ?? []
                    if !episodePhoto.isEmpty {
                        textTop = drawImageWithShadow(rendererContext: renderer, images: episodePhoto, pageRect: pageRect, startY: textTop)
                    }
                }
            } else {
                let noEpisodeMessage = "⚠️発症記録がありません。"
                let noEpisodeFont = UIFont.systemFont(ofSize: 12.0)
                let position = CGPoint(x: 20, y: textTop)
                textTop = drawText(message: noEpisodeMessage, font: noEpisodeFont, position: position, maxWidth: pageRect.width - 40)
                textTop += 40
                textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
            }
        }
    }
    
    private func fetchDiagnosisData(for profile: ProfileInfoEntity) -> [DiagnosisEntity] {
        let fetchRequest = DiagnosisEntity.fetchRequest()
        guard let recordID = profile.recordID else {
            print("Profile recordID is nil.")
            return []
        }
        fetchRequest.predicate = NSPredicate(format: "profileID == %@", recordID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        do {
            let records = try viewContext.fetch(fetchRequest)
            return records
        } catch let error as NSError {
            print("Could not fetch diagnosis data. \(error), \(error.userInfo)")
            return []
        }
    }
    
    private func fetchAllergenData(for profile: ProfileInfoEntity) -> [AllergenEntity] {
        let fetchRequest = AllergenEntity.fetchRequest() as NSFetchRequest<AllergenEntity>
        guard let recordID = profile.recordID else {
            print("Profile recordID is nil.")
            return []
        }
        fetchRequest.predicate = NSPredicate(format: "profileID == %@", recordID)
        
        do {
            let records = try viewContext.fetch(fetchRequest)
            return records
        } catch let error as NSError {
            print("Could not fetch allergen data. \(error), \(error.userInfo)")
            return []
        }
    }
    
    private func fetchEpisodesData(for allergenID: String) -> [EpisodeEntity] {
        let fetchRequest = EpisodeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "allergenID = %@", allergenID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        do {
            let records = try viewContext.fetch(fetchRequest)
            return records
        } catch let error as NSError {
            print("Could not fetch episode data. \(error), \(error.userInfo)")
            return []
        }
    }
}

func drawText(message: String, font:UIFont, position: CGPoint, maxWidth: CGFloat, alignment: NSTextAlignment = .left, textColor: UIColor = .black) -> CGFloat {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .paragraphStyle: paragraphStyle,
        .foregroundColor: textColor
    ]
    let attributedMessage = NSAttributedString(string: message, attributes: attributes)
    let messageSize = attributedMessage.getSize(withPreferredWidth: maxWidth)
    let messageRect = CGRect(x: position.x, y: position.y, width: maxWidth, height: messageSize.height)
    attributedMessage.draw(in: messageRect)
    
    return position.y + messageSize.height + 10
}

extension UIGraphicsPDFRendererContext {
    func checkContext(cursor: CGFloat, pdfSize: CGSize) -> CGFloat {
        if cursor > pdfSize.height - 101 {
            self.beginPage()
            return 40
        }
        return cursor
    }
}

extension Array {
    func chunk(size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension UIImage {
    func scalePreservingAspectRatio(newSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = newSize.width / size.width
        let heightRatio = newSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledImageSize))
        }
        return scaledImage
    }
}

func drawImageWithShadow(rendererContext: UIGraphicsPDFRendererContext, images: [String], pageRect: CGRect, startY: CGFloat) -> CGFloat {
    var textTop = startY
    let imagesChunked = images.chunk(size: 3)
    for photos in imagesChunked {
        var imageY = textTop
        textTop = rendererContext.checkContext(cursor: imageY + 220, pdfSize: pageRect.size)
        if textTop != imageY + 220 {
            imageY = textTop
        }
        if textTop == 40 {
            textTop += 220
        }
        for (index, url) in photos.enumerated() {
            let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filePath = doc.appendingPathComponent(url)
            if let image = UIImage(contentsOfFile: filePath.path) {
                let resize = image.scalePreservingAspectRatio(newSize: CGSize(width: 165, height: 220))
                let logoRect = CGRect(x: 20.0 + CGFloat(165 * index) + CGFloat(10 * index), y: imageY, width: 165, height: 220)
                
                // Set the shadow properties
                let context = UIGraphicsGetCurrentContext()
                context?.saveGState()
                context?.setShadow(offset: CGSize(width: 2, height: -2), blur: 6, color: UIColor.black.withAlphaComponent(0.3).cgColor)
                
                // Draw the image with the shadow
                resize.draw(in: logoRect)
                
                // restore the context state
                context?.restoreGState()
            }
        }
        textTop += 30
    }
    return textTop
}

extension NSAttributedString {
    func getSize(withPreferredWidth width: CGFloat) -> CGSize {
        let sizeConstraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingRect = self.boundingRect(with: sizeConstraint,
                                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                                             context: nil)
        return CGSize(width: ceil(boundingRect.width), height: ceil(boundingRect.height))
    }
}

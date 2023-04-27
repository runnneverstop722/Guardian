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
            
            for diagnosis in diagnosisData {
                let items = [
                    ("診断日: ", dateFormatter.string(from: diagnosis.diagnosisDate ?? Date())),
                    ("診断名: ", diagnosis.diagnosis ?? ""),
                    ("アレルゲン: ", (diagnosis.allergens?.joined(separator: ", ") ?? "")),
                    ("医療機関名: ", diagnosis.diagnosedHospital ?? ""),
                    ("担当医: ", diagnosis.diagnosedAllergist ?? ""),
                    ("担当医コメント: ", diagnosis.diagnosedAllergistComment ?? "")
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
            }
        }
        // Draw the divider
        textTop += 10
        context.setLineWidth(1)
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
            let allergenNameStringRect = CGRect(x: offsetX, y: textTop, width: allergenNameStringSize.width, height: allergenNameStringSize.height)
            attributedAllergenName.draw(in: allergenNameStringRect)
            textTop += 10
            textTop += offsetY
            textTop = renderer.checkContext(cursor: textTop, pdfSize: pageRect.size)
            
            // Draw medical data
            let allergenID = allergen.recordID!
            let bloodTests = PersistenceController.shared.fetchBloodTest(allergenID: allergenID)
            for (index, bloodTest) in bloodTests.enumerated() {
                let items = [
                    ("血液検査記録: ", "\(index + 1)"),
                    ("検査日: ", dateFormatter.string(from: bloodTest.bloodTestDate ?? Date())),
                    ("IgEレベル(UA/mL): ", bloodTest.bloodTestLevel ?? "0.0"),
                    ("IgEクラス: ", bloodTest.bloodTestGrade)
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
            for (index, skinTest) in skinTests.enumerated() {
                let items = [
                    ("皮膚プリック検査記録: ", "\(index + 1)"),
                    ("検査日: ", dateFormatter.string(from: skinTest.skinTestDate ?? Date())),
                    ("結果(mm): ", skinTest.skinTestResultValue ?? "0.0"),
                    ("陽性有無: ", skinTest.skinTestResult == true ? "陽性" : "陰性")
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
            for (index, oralFoodChallenge) in oralFoodChallenges.enumerated() {
                let items = [
                    ("食物経口負荷試験記録: ", "\(index + 1)"),
                    ("検査日: ", dateFormatter.string(from: oralFoodChallenge.creationDate ?? Date())),
                    ("食べた量(mm): ", oralFoodChallenge.oralFoodChallengeQuantity ?? "0.0"),
                    ("陽性有無: ", oralFoodChallenge.oralFoodChallengeResult == true ? "陽性" : "陰性"),
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
            
            // Draw episodes data
            let episodesData = fetchEpisodesData(for: allergenID)
            if !episodesData.isEmpty {
                let episodesTitle = "発症記録:"
                let episodesTitleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
                let episodesTitleAttributes: [NSAttributedString.Key: Any] = [.font: episodesTitleFont ]
                let attributedEpisodesTitle = NSAttributedString(string: episodesTitle, attributes: episodesTitleAttributes)
                let episodesTitleStringSize = attributedEpisodesTitle.getSize(withPreferredWidth: pageRect.width - 40)
                let episodesTitleStringRect = CGRect(x: 20, y: textTop, width: episodesTitleStringSize.width, height: episodesTitleStringSize.height)
                attributedEpisodesTitle.draw(in: episodesTitleStringRect)
                
                textTop += episodesTitleStringSize.height + 10
                
                for episode in episodesData {
                    let items = [
                        ("発症日: ", dateFormatter.string(from: episode.episodeDate ?? Date())),
                        ("初症状だった: ", episode.firstKnownExposure ? "はい" : "いいえ"),
                        ("受診した: ", episode.wentToHospital ? "はい" : "いいえ"),
                        ("アレルゲンへの接触タイプ: ", (episode.typeOfExposure?.joined(separator: ", ") ?? "")),
                        ("症状: ", (episode.symptoms?.joined(separator: ", ") ?? "")),
                        ("重症度評価: ", episode.severity ?? ""),
                        ("発症までの経過時間: ", episode.leadTimeToSymptoms ?? ""),
                        ("運動後だった: ", episode.didExercise ? "はい" : "いいえ"),
                        ("添付写真: ", " ")
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
                    let episodePhoto = episode.episodePhoto ?? []
                    if !episodePhoto.isEmpty {
                        let episodePhotos = episodePhoto.chunk(size: 3)
                        for photos in episodePhotos {
                            // 165
                            var imageY = textTop
                            textTop = renderer.checkContext(cursor: imageY + 165, pdfSize: pageRect.size)
                            if textTop != imageY + 165 {
                                imageY = textTop
                            }
                            if textTop == 40 {
                                textTop += 165
                            }
                            for (index, url) in photos.enumerated() {
                                let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                let filePath = doc.appendingPathComponent(url)
                                if let image = UIImage(contentsOfFile: filePath.path) {
                                    let resize = image.scaleImageToSize(newSize: CGSize(width: 165, height: 165))
                                    let logoRect = CGRect(x: 20.0 + CGFloat(165*index) + CGFloat(10*index), y: imageY, width: 165, height: 165)
                                    resize.draw(in: logoRect)
                                }
                            }
                            textTop += 10
                        }
                    }
                }
            }
            // Draw the divider
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 20, y: textTop))
            context.addLine(to: CGPoint(x: pageRect.width - 20, y: textTop))
            context.strokePath()
            textTop += 10
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

extension UIGraphicsPDFRendererContext {
    func checkContext(cursor: CGFloat, pdfSize: CGSize) -> CGFloat {
        if cursor > pdfSize.height - 100 {
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
    /// Scales an image to fit within a bounds with a size governed by the passed size. Also keeps the aspect ratio.
    /// Switch MIN to MAX for aspect fill instead of fit.
    ///
    /// - parameter newSize: newSize the size of the bounds the image must fit within.
    ///
    /// - returns: a new scaled image.
    func scaleImageToSize(newSize: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero

        let aspectWidth = newSize.width/size.width
        let aspectheight = newSize.height/size.height

        let aspectRatio = max(aspectWidth, aspectheight)

        scaledImageRect.size.width = size.width * aspectRatio;
        scaledImageRect.size.height = size.height * aspectRatio;
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0;
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0;

        UIGraphicsBeginImageContext(newSize)
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage!
    }
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

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

    init(profile: ProfileInfoEntity, viewContext: NSManagedObjectContext) {
        self.profile = profile
        self.viewContext = viewContext
    }
    
    func drawPageContent(in context: CGContext, pageRect: CGRect, textTop: CGFloat, isFirstPage: Bool) -> (CGFloat, Bool) {
        var hasMoreContent = false
        
        if isFirstPage {
            // Draw the selected profile's first name with string "'s records"
            let profileName = "\(profile.firstName ?? "")の記録"
            let profileNameFont = UIFont.systemFont(ofSize: 16.0, weight: .bold)
            let profileNameAttributes: [NSAttributedString.Key: Any] = [
                .font: profileNameFont
            ]
            let attributedProfileName = NSAttributedString(string: profileName, attributes: profileNameAttributes)
            let profileNameStringSize = attributedProfileName.size()
            let profileNameStringRect = CGRect(x: (pageRect.width - profileNameStringSize.width) / 2.0, y: textTop, width: profileNameStringSize.width, height: profileNameStringSize.height)
            attributedProfileName.draw(in: profileNameStringRect)
            
            // Draw the divider
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 20, y: profileNameStringRect.origin.y + profileNameStringRect.height + 20))
            context.addLine(to: CGPoint(x: pageRect.width - 20, y: profileNameStringRect.origin.y + profileNameStringRect.height + 20))
            context.strokePath()
        }
        // Draw the content
        var textTop = textTop
        
        // Fetch necessary data
        let diagnosisData = fetchDiagnosisData(for: profile)
        let episodesData = fetchEpisodesData(for: profile)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        // Draw diagnosis data
        if !diagnosisData.isEmpty {
            let diagnosisTitle = "診断記録"
            let diagnosisTitleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let diagnosisTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: diagnosisTitleFont
            ]
            let attributedDiagnosisTitle = NSAttributedString(string: diagnosisTitle, attributes: diagnosisTitleAttributes)
            let diagnosisTitleStringSize = attributedDiagnosisTitle.size()
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
                    let itemTextSize = attributedItemText.size()
                    let itemTextRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40, height: itemTextSize.height)
                    attributedItemText.draw(in: itemTextRect)
                    
                    textTop += itemTextSize.height + 6
                    
                    if textTop >= pageRect.height {
                        hasMoreContent = true
                        break
                    }
                }
            }
        }
        
        // Draw episodes data
        if !episodesData.isEmpty && !hasMoreContent {
            let episodesTitle = "発症記録:"
            let episodesTitleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let episodesTitleAttributes: [NSAttributedString.Key: Any] = [.font: episodesTitleFont ]
            let attributedEpisodesTitle = NSAttributedString(string: episodesTitle, attributes: episodesTitleAttributes)
            let episodesTitleStringSize = attributedEpisodesTitle.size()
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
                    ("運動後だった: ", episode.didExercise ? "はい" : "いいえ")
                ]
                
                let itemFont = UIFont.systemFont(ofSize: 12.0)
                
                for (label, value) in items {
                    let itemText = "\(label)\(value)"
                    let itemTextAttributes: [NSAttributedString.Key: Any] = [
                        .font: itemFont
                    ]
                    let attributedItemText = NSAttributedString(string: itemText, attributes: itemTextAttributes)
                    let itemTextSize = attributedItemText.size()
                    let itemTextRect = CGRect(x: 20, y: textTop, width: pageRect.width - 40,height: itemTextSize.height)
                    attributedItemText.draw(in: itemTextRect)
                    textTop += itemTextSize.height + 6
                    
                    if textTop >= pageRect.height {
                        hasMoreContent = true
                        break
                    }
                }
                textTop += 10
            }
        }
        return (textTop, hasMoreContent)
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
    
    private func fetchEpisodesData(for profile: ProfileInfoEntity) -> [EpisodeEntity] {
        let fetchRequest = EpisodeEntity.fetchRequest() as NSFetchRequest<EpisodeEntity>
        let allergenEntities = fetchAllergenData(for: profile)
        let allergenIDs = allergenEntities.map { $0.recordID }
        
        fetchRequest.predicate = NSPredicate(format: "allergenID IN %@", allergenIDs)
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


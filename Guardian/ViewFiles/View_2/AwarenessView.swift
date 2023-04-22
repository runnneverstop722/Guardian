//
//  AwarenessView   .swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import CoreData

class AllergensList: ObservableObject {
    @Published var allergens: [String] = [] {
        didSet {
            // Do something when the allergens array is updated
            print("Updated allergens: \(allergens)")
        }
    }
}

struct AwarenessView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProfileInfoEntity.creationDate, ascending: true)],
        animation: .default)
    private var profiles: FetchedResults<ProfileInfoEntity>
    @State private var selectedProfile: ProfileInfoEntity?
    @State private var showingShareSheet = false
    @State private var pdfFileURL: URL?
    @ObservedObject var allergensList = AllergensList()
    @State var didLoad = false
    private func allergensList(profile: ProfileInfoEntity?) -> String {
        if let recordID = profile?.recordID {
            let fetchRequest = AllergenEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "profileID == %@", recordID)
            do {
                let records = try viewContext.fetch(fetchRequest)
                
                return records.compactMap({ $0.allergen }).joined(separator: ", ")
            } catch let error as NSError {
                print("Could not fetch from local cache. \(error), \(error.userInfo)")
            }
        }
        return ""
    }
    func loadImageFromURL(urlString: String) -> UIImage? {
        if let url = URL(string: urlString), url.isFileURL {
            do {
                let imageData = try Data(contentsOf: url)
                return UIImage(data: imageData)
            } catch {
                print("Error loading image: \(error)")
            }
        } else {
            print("Invalid URL or not a file URL: \(urlString)")
        }
        return nil
    }
    func sharePDF() {
        PersistenceController.shared.exportAllRecordsToPDF { result in
            switch result {
            case .success(let pdfFileURL):
                DispatchQueue.main.async {
                    self.pdfFileURL = pdfFileURL
                    self.showingShareSheet = true
                    print("PDF File URL: \(pdfFileURL)")
                }
            case .failure(let error):
                print("Error exporting PDF: \(error)")
            }
        }
    }

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 20) {
                    if !profiles.isEmpty {
                        Picker("Select Profile", selection: $selectedProfile) {
                            ForEach(profiles, id: \.self) { (item: ProfileInfoEntity) in
                                Text(item.firstName ?? "").tag(item as ProfileInfoEntity?)
                            }
                        }.pickerStyle(MenuPickerStyle())
                            .foregroundColor(.secondary)
                    }
                    if let selectedProfile = selectedProfile {
                        Image(uiImage: loadImageFromURL(urlString: selectedProfile.profileImageData ?? "") ?? UIImage())
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .padding(.top, 50)
                        
                        Text("\(selectedProfile.firstName ?? "")")
                            .font(.title)
                            .foregroundColor(.white)
                            .bold()
                        
                        Text("I have a Food Allergy")
                            .multilineTextAlignment(.center)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("to:")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(allergensList(profile: selectedProfile))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Please ensure that my menu is free from them.")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Thank you for your understanding.")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        sharePDF()
                    } label: {
                        Text("Export Your All Records")
                    }
                    .sheet(isPresented: $showingShareSheet) {
                        if let pdfURL = pdfFileURL {
                            ShareSheet(activityItems: [pdfURL])
                        } else {
                            Text("No PDF file to share")
                        }
                    }





                }
                .navigationBarTitle("Awareness")
                .navigationBarItems(trailing: Button(action: {
                    print("Button pressed")
                }) {
                    Image(systemName: "plus")
                })
                .onAppear() {
                    if !didLoad {
                        didLoad = true
                        selectedProfile = profiles.first
                    }
                }
                .onChange(of: selectedProfile?.managedObjectContext) { newValue in
                    if newValue == nil {
                        selectedProfile = profiles.first
                    }
                }
                .onChange(of: profiles.count) { newValue in
                    if newValue > 0 && selectedProfile == nil {
                        selectedProfile = profiles.first
                    }
                }
                
            }
        }
    }
}

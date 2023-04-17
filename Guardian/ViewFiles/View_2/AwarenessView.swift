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
    @FetchRequest(entity: ProfileInfoEntity.entity(), sortDescriptors: []) private var profiles: FetchedResults<ProfileInfoEntity>
    @State private var selectedProfileIndex: Int = 0
    @ObservedObject var allergensList = AllergensList()
    
    private func loadSelectedProfile() -> ProfileInfoEntity? {
        if !profiles.isEmpty {
            return profiles[selectedProfileIndex]
        }
        return nil
    }
    
    private func allergensList(profile: ProfileInfoEntity?) -> String {
        if let profile = profile {
            let allergens = profile.allergens as? Set<AllergenEntity> ?? Set<AllergenEntity>()
            return allergens.compactMap({ $0.allergen }).joined(separator: ", ")
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


    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 20) {
                    Picker("Select Profile", selection: $selectedProfileIndex) {
                        ForEach(0 ..< profiles.count) { index in
                            Text(profiles[index].firstName ?? "").tag(index)
                        }
                    }.pickerStyle(MenuPickerStyle())
                        .foregroundColor(.secondary)
                    
                    if let selectedProfile = loadSelectedProfile() {
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
                }
                .navigationBarTitle("Awareness")
                .navigationBarItems(trailing: Button(action: {
                    print("Button pressed")
                }) {
                    Image(systemName: "plus")
                })
            }
        }
    }
}

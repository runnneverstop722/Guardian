//
//  EpisodeDetails.swift
//  Guardian
//
//  Created by Teff on 2023/03/24.
//

import SwiftUI

struct EpisodeDetails: View {
    
    @StateObject var episodeModel = EpisodeModel()
    @State private var showingSaveAlert = false
    @State private var showingSelectSymptoms = false
    @State private var showingSelectLocations = false
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("日付", selection: $episodeModel.episodeDate, displayedComponents: .date)

                Toggle("初症状ですか？", isOn: $episodeModel.firstKnownExposure)

                Toggle("病院で受診しましたか？", isOn: $episodeModel.wentToHospital)

                Section(header: Text("What was the type of exposure? (Check all that apply)")) {
                    ForEach(episodeModel.typeOfExposureOptions, id: \.self) { option in
                        Button(action: {
                            if let index = episodeModel.typeOfExposure.firstIndex(of: option) {
                                episodeModel.typeOfExposure.remove(at: index)
                            } else {
                                episodeModel.typeOfExposure.append(option)
                            }
                        }) {
                            HStack {
                                Text(option)
                                Spacer()
                                if episodeModel.typeOfExposure.contains(option) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("What were the symptoms?")) {
                    ForEach(episodeModel.symptomCategories, id: \.self) { category in
                        NavigationLink(destination: SelectSymptoms(category: category, selectedSymptoms: $episodeModel.symptoms)) {
                            HStack {
                                Text(category)
                                Spacer()
                                Text("\(episodeModel.symptoms.filter { $0.hasPrefix(category) }.count)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section(header: Text("How long after exposure did the first symptom(s) emerge?")) {
                    Picker("Lead Time", selection: $episodeModel.leadTimeToSymptoms) {
                        ForEach(episodeModel.leadTimeToSymptomsOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("What treatments were given? (Check all that apply)")) {
                    ForEach(episodeModel.treatmentsOptions, id: \.self) { treatment in
                        Button(action: {
                            if let index = episodeModel.treatments.firstIndex(of: treatment) {
                                episodeModel.treatments.remove(at: index)
                            } else {
                                episodeModel.treatments.append(treatment)
                            }
                        }) {
                            HStack {
                                Text(treatment)
                                Spacer()
                                if episodeModel.treatments.contains(treatment) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if episodeModel.treatments.contains("Other") {
                        TextField("Other treatment", text: $episodeModel.otherTreatment)
                    }
                }
                Section(header: Text("Any related photos?\n (available 10 photos as maximum)")) {
                    
                    HStack {
                        Button(action: {
                            // Action to add photo
                            
                        }) {
                            Image(systemName: "photo")
                                .frame(width: 80, height: 80)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        // Additional photo thumbnails can be added here
                        
                        // Also Need a botton to delete whole data for this allergen
                        
                    }
                }
            }
//            .listStyle(GroupedListStyle()) // Add this line to apply the grouped list style
            .navigationBarTitle("Episode Details")
            .navigationBarItems(trailing: Button("Update") {
                showingSaveAlert.toggle()
            })
            .alert(isPresented: $showingSaveAlert) {
                Alert(title: Text("Update Episode?"), message: Text("Do you want to update this episode?"), primaryButton: .default(Text("Update")) {
                    // Handle saving the episode
                }, secondaryButton: .cancel())
            }
        }
    }
}

struct EpisodeDetails_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeDetails()
    }
}

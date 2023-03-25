//
//  NewEpisode.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI

struct NewEpisode: View {
    @State private var episodeDate = Date()
    @State private var firstKnownExposure: Bool = false
    @State private var wentToHospital: Bool = false
    @State private var typeOfExposure: [String] = []
    @State private var symptoms: [String] = []
    @State private var leadTimeToSymptoms: String = ""
    @State private var treatments: [String] = []
    @State private var otherTreatment: String = ""
    @State private var episodeImage: Image?
    
    @State private var showingSaveAlert = false
    @State private var showingSelectSymptoms = false
    @State private var showingSelectLocations = false
    @State private var selectedCategory = ""

    private let symptomCategories = ["Skin", "Nose or breathing", "Heart", "Abdominal", "Other"]
    private let typeOfExposureOptions = ["Ingestion", "Skin", "Smell", "Unknown"]
    private let leadTimeToSymptomsOptions = ["Under 5 min", "5-10 min", "10-15 min", "15-30 min", "30-60 min", "Over an hour"]
    private let treatmentsOptions = ["Antihistamine", "Injected steroids", "Oral steroids", "Topical steroids", "Epinephrine shot in the muscle", "Albuterol inhaler", "Other"]

    var body: some View {
        NavigationView {
            Form {
                DatePicker("日付", selection: $episodeDate, displayedComponents: .date)

                Toggle("初症状ですか？", isOn: $firstKnownExposure)

                Toggle("病院で受診しましたか？", isOn: $wentToHospital)

                Section(header: Text("What was the type of exposure? (Check all that apply)")) {
                    ForEach(typeOfExposureOptions, id: \.self) { option in
                        Button(action: {
                            if let index = typeOfExposure.firstIndex(of: option) {
                                typeOfExposure.remove(at: index)
                            } else {
                                typeOfExposure.append(option)
                            }
                        }) {
                            HStack {
                                Text(option)
                                Spacer()
                                if typeOfExposure.contains(option) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("What were the symptoms?")) {
                    ForEach(symptomCategories, id: \.self) { category in
                        NavigationLink(destination: SelectSymptoms(category: category, selectedSymptoms: $symptoms)) {
                            HStack {
                                Text(category)
                                Spacer()
                                Text("\(symptoms.filter { $0.hasPrefix(category) }.count)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section(header: Text("How long after exposure did the first symptom(s) emerge?")) {
                    Picker("Lead Time", selection: $leadTimeToSymptoms) {
                        ForEach(leadTimeToSymptomsOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("What treatments were given? (Check all that apply)")) {
                    ForEach(treatmentsOptions, id: \.self) { treatment in
                        Button(action: {
                            if let index = treatments.firstIndex(of: treatment) {
                                treatments.remove(at: index)
                            } else {
                                treatments.append(treatment)
                            }
                        }) {
                            HStack {
                                Text(treatment)
                                Spacer()
                                if treatments.contains(treatment) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if treatments.contains("Other") {
                        TextField("Other treatment", text: $otherTreatment)
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
            .navigationBarTitle("New Episode")
            .navigationBarItems(trailing: Button("Save") {
                showingSaveAlert.toggle()
            })
            .alert(isPresented: $showingSaveAlert) {
                Alert(title: Text("Save Episode?"), message: Text("Do you want to save this episode?"), primaryButton: .default(Text("Save")) {
                    // Handle saving the episode
                }, secondaryButton: .cancel())
            }
        }
    }
}

struct NewEpisode_Previews: PreviewProvider {
    static var previews: some View {
        NewEpisode()
    }
}


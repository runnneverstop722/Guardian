//
//  EpisodeView.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI

import CloudKit

struct EpisodeView: View {
    @StateObject var episodeModel: EpisodeModel

    @State private var showingSelectSymptoms = false
    @State private var showingSelectLocations = false
    @State private var selectedCategory = []
    @State private var showingAlert = false
    @State private var isUpdate = false
    @Environment(\.dismiss) private var dismiss

    let allergen: CKRecord
    
//    init(allergen: CKRecord) {
//        self.allergen = allergen
//        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: allergen))
//    }
    init(allergen: CKRecord) {
        self.allergen = allergen
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: allergen))
    }
    
    init(episode: CKRecord) {
        self.allergen = episode
        _episodeModel = StateObject(wrappedValue: EpisodeModel(episode: episode))
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("日付", selection: $episodeModel.episodeDate, displayedComponents: .date)

                Toggle("初症状ですか？", isOn: $episodeModel.firstKnownExposure)

                Toggle("病院で受診しましたか？", isOn: $episodeModel.wentToHospital)

                Section(header: Text("どのような形でアレルゲンに触れましたか？（複数選択可）")) {
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

                Section(header: Text("どのような症状が出ましたか?")) {
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

                Section(header: Text("アレルゲンに触れてからどれほど時間が経ってから症状が現れましたか?")) {
                    Picker("Lead Time", selection: $episodeModel.leadTimeToSymptoms) {
                        ForEach(episodeModel.leadTimeToSymptomsOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("どんな対応を取りましたか?（複数選択可）")) {
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
                    if episodeModel.treatments.contains("その他") {
                        TextField("その他の対応処置", text: $episodeModel.otherTreatment)
                    }
                }
                Section(header: Text("添付写真")) {
                    
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
            .navigationBarTitle("Episode")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        episodeModel.addButtonPressed()
                        showingAlert = true
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("データが保存されました。"),
                              message: Text(""), dismissButton: .default(Text("Close"), action: {
                            dismiss()
                        }))
                    }
                }
            }
        }
    }
}

//struct Episode_Previews: PreviewProvider {
//    static var previews: some View {
//        EpisodeView()
//    }
//}


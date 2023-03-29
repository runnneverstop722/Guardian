//
//  EpisodeView.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI

struct EpisodeView: View {
    @StateObject var episodeModel = EpisodeModel()
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
    @State private var selectedCategory = []

    private let symptomCategories = ["皮膚", "呼吸器", "循環器", "消化器", "その他"]
    private let typeOfExposureOptions = ["摂取", "肌に接触", "匂い", "不明"]
    private let leadTimeToSymptomsOptions = ["5分以内", "5~10分", "10~15分", "15~30分", "30~60分", "1時間以降"]
    private let treatmentsOptions = ["抗ヒスタミン薬", "ステロイド注入", "経口ステロイド", "ステロイド外用薬", "エピペン注入", "その他"]

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
            .navigationBarItems(trailing: Button("保存") {
                showingSaveAlert.toggle()
            })
            .alert(isPresented: $showingSaveAlert) {
                Alert(title: Text("この内容で保存しましか？"),
                      primaryButton: .default(Text("保存")) {
                    // Handle saving the episode
                }, secondaryButton: .cancel(Text("キャンセル")))
            }
        }
    }
}

struct Episode_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeView()
    }
}


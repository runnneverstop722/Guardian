//
//  MedicalTestAndEpisodeView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//
import SwiftUI
import CloudKit

struct MedicalTestAndEpisodeView: View {
    @StateObject var episodeModel:EpisodeModel
    @State private var bloodTest: [BloodTest] = []
    @State private var skinTest: [SkinTest] = []
    @State private var oralFoodChallenge: [OralFoodChallenge] = []
    @State private var episodeDate: Date = Date()
    @State private var firstKnownExposure: Bool = false
    @State private var allergistComment: String = ""
    
    @State private var showAlert = false
    @State private var showMedicalTestView = false
    @State private var showEpisodeView = false
    @State private var isAddingNewEpisode = false
    @State private var isUpdate = false
    @State private var showingRemoveDiagnosisAlert = false
    
    var allergenName: String = "Unknown Allergen"
    
    let allergen: CKRecord
    let existingEpisodeData = NotificationCenter.default.publisher(for: Notification.Name("existingEpisodeData"))
    
    init(allergen: CKRecord) {
        self.allergen = allergen
        allergenName = allergen["allergen"] as? String ?? ""
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: allergen))
    }
    
    
    var body: some View {
        List {
            Section(header: Text("Medical Test")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Blood Test")
                        Spacer()
                        Text("\(bloodTest.count) records")
                    }
                    Divider()
                    HStack {
                        Text("Skin Test")
                        Spacer()
                        Text("\(skinTest.count) records")
                    }
                    Divider()
                    HStack {
                        Text("Oral Food Challenge")
                        Spacer()
                        Text("\(oralFoodChallenge.count) records")
                    }
                }
                
                NavigationLink(
                    destination: MedicalTestView(allergen: allergen),
                    isActive: $showMedicalTestView
                ) {
                    Button(action: {
                        showMedicalTestView = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add & Details")
                            Spacer()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("Episodes")) {
                ForEach(episodeModel.episodeInfo, id: \.self) { item in
                    NavigationLink(
                        destination: EpisodeView(episode: item.record),
                        label: { EpisodeListRow(headline: item.headline, caption1: item.caption1, caption2: item.caption2, caption3: item.caption3)
                        })
                    .swipeActions {
                        Button("Edit") {
                            // Edit action
                        }
                        .tint(.blue)
                        
                        Button("Delete") {
                            // Delete action
                        }
                        .tint(.red)
                    }
                }
                Button(action: {
                    showEpisodeView = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add & Details")
                        Spacer()
                    }
                    .foregroundColor(.blue)
                }
                .background(
                    NavigationLink(
                        destination: EpisodeView(allergen: allergen),
                        isActive: $isAddingNewEpisode,
                        label: {}
                    )
                )
                .onReceive(existingEpisodeData) { data in
                    if let data = data.object as? EpisodeListModel {
                        episodeModel.episodeInfo.insert(data, at: 0)
                    } else {
                        episodeModel.fetchItemsFromCloud()
                    }
                }
            }
            
            
            
            Section(header: Text("Allergist's Comment")) {
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: $allergistComment)
                    
                }
            }
        }
        .navigationTitle(allergenName)
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            episodeModel.episodeInfo = []
            episodeModel.fetchItemsFromCloud()
        }
        .toolbar {
            Button("Delete") {
                showAlert.toggle()
                // Action:
                // 1. Delete all records from `Medical Test`, `Episode`, `Allergist's Comment`.
                // 2. Unselect this allergen from the record type: `Allergens` and `ProfileInfo`.
                
            }
            .tint(.red)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Are you sure?"),
                message: Text("This data will be deleted and it can't be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    // Delete all data action
                },
                secondaryButton: .cancel()
            )
        }
    }
}

extension MedicalTestAndEpisodeView {
    struct EpisodeListRow: View {
        let headline: String
        let caption1: String
        let caption2: String
        let caption3: String
        
        var body: some View {
            VStack {
                HStack(spacing: 16.0) {
                    Text(headline)
                        .foregroundColor(.accentColor)
                    Spacer()
                    Text(caption1)
                    Text(caption2)
                }
                HStack {
                    Text(caption3)
                    Spacer()
                }
                .lineSpacing(10)
                .fontDesign(.rounded)
            }
        }
    }
}

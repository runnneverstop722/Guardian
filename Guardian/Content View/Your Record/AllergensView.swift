//
//  AllergensView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//
import SwiftUI
import CloudKit

struct AllergensView: View {
    @State private var bloodTests: [BloodTest] = []
    @State private var skinTests: [SkinTest] = []
    @State private var oralFoodChallenges: [OralFoodChallenge] = []
    @State private var episodeDate: Date = Date()
    @State private var firstKnownExposure: Bool = false
    @State private var allergistComment: String = ""
    
    @State private var showAlert = false
    @State private var showNewEpisode = false
    @State private var showEpisodeDetails = false
    @State private var selectedItem: Int? = nil
    @State private var showMedicalTestView = false
    
    var allergenName: String = "Unknown Allergen"
    let allergen: CKRecord
    
    var body: some View {
        List {
            Section(header: Text("Medical Test")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("血液検査")
                        Spacer()
                        Text("\(bloodTests.count) 件")
                    }
                    Divider()
                    HStack {
                        Text("皮膚プリックテスト")
                        Spacer()
                        Text("\(skinTests.count) 件")
                    }
                    Divider()
                    HStack {
                        Text("経口負荷試験(OFC)")
                        Spacer()
                        Text("\(oralFoodChallenges.count) 件")
                    }
                }
                
                NavigationLink(
                    destination: MedicalTestView(allergen: allergen),
                    isActive: $showMedicalTestView
                ) {
                    Button("+ Add & Details") {
                        showMedicalTestView = true
                    }
                }
            }
            
            Section(header: Text("Episodes")) {
                ForEach(0..<10) { index in
                    HStack {
                        Text("Episode \(index):")
                        Spacer()
                        Text("April 5, 2022")
                        if firstKnownExposure {
                            Image(systemName: "exclamationmark.octagon")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = index
                        showEpisodeDetails.toggle()
                    }
                    .sheet(isPresented: $showEpisodeDetails) {
                        if let selectedItem = selectedItem {
//                            EpisodeView(episode: selectedItem)
                        }
                    }
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
                
                Button("+ Add") {
                    showNewEpisode.toggle()
                }
                .sheet(isPresented: $showNewEpisode) {
                    EpisodeView(allergen: allergen)
                }
            }
            
            Section(header: Text("Allergist's Comment")) {
                TextEditor(text: $allergistComment)
                    .frame(height: 100)
                    .foregroundColor(.black)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    .padding(.bottom)
            }
        }
        .navigationTitle(allergenName)
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            Button("Delete all data") {
                showAlert.toggle()
            }
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

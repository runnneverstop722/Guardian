//
//  AllergensView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//
import SwiftUI

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
    @State private var showMedicalDataView = false

    
    var allergenName: String = "Unknown Allergen"
    
    var body: some View {
        List {
            Section(header: Text("Total Medical Data")) {
                VStack(alignment: .leading) {
                    Text("Blood Tests: \(bloodTests.count)")
                    Text("Skin Tests: \(skinTests.count)")
                    Text("Oral Food Challenges: \(oralFoodChallenges.count)")
                }
                
                NavigationLink(
                    destination: MedicalDataView(),
                    isActive: $showMedicalDataView
                ) {
                    Button("Go to Medical Data") {
                        showMedicalDataView = true
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
//                            EpisodeDetails(episode: selectedItem)
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
                
                Button("Add new episode") {
                    showNewEpisode.toggle()
                }
                .sheet(isPresented: $showNewEpisode) {
                    NewEpisode()
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

//
//  YourRecordsView.swift
//  Guardian
//
//  Created by Teff on 2023/03/24.
//

import SwiftUI
import CloudKit

struct YourRecordsView: View {
    @StateObject var diagnosisModel: DiagnosisModel
    @StateObject var profileModel: ProfileModel
    @StateObject var episodeModel: EpisodeModel
    @State private var showUpdateProfile = false
    @State private var showExportPDF = false
    @State private var isAddingNewDiagnosis = false
    @State private var showingRemoveAllergensAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    let profile: CKRecord
    let onDeleteDiagnosis = NotificationCenter.default.publisher(for: Notification.Name("removeDiagnosis"))
    
    init(profile: CKRecord) {
        self.profile = profile
        self._diagnosisModel = StateObject(wrappedValue: DiagnosisModel(record: profile))
        self._profileModel = StateObject(wrappedValue: ProfileModel(profile: profile))
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: profile))
    }

    var body: some View {
        List {
            Section(header: Text("Diagnosis")) {
                ForEach(diagnosisModel.diagnosisInfo, id: \.self) { item in
                    NavigationLink(
                        destination: DiagnosisView(record: item.record),
                        label: {
                            VStack(alignment: .leading) {
                                Text(item.headline)
                                    .font(.system(.headline, design: .rounded))
                                Text(item.caption1)
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                Text(item.caption2.joined(separator: ", "))
                                    .font(.system(.caption, design: .rounded, weight: .light))
                            }
                        })
                }
                Button(action: {
                    isAddingNewDiagnosis = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add")
                        Spacer()
                    }
                    .foregroundColor(.blue)
                }
                .background(
                    NavigationLink(
                        destination: DiagnosisView(profile: profile),
                        isActive: $isAddingNewDiagnosis,
                        label: {}
                    )
                ).onReceive(onDeleteDiagnosis) { data in
                    if let data = data.object as? DiagnosisListModel {
                        diagnosisModel.diagnosisInfo.insert(data, at: 0)
                    } else {
                        diagnosisModel.fetchItemsFromCloud()
                    }
                }
            }
            
            Section(header: Text("Allergens")) {
                ForEach(episodeModel.allergens, id: \.self) { item in
                    NavigationLink(
                        destination: AllergensView(allergen: item.record),
                        label: {
                            AllergensListRow(headline: item.headline, caption1: item.caption1, caption2: item.caption2)
                        })
                    NavigationLink(value: item) {
                        AllergensListRow(headline: item.headline, caption1: item.caption1, caption2: item.caption2)
                    }.swipeActions(edge: .trailing) {
//                        Button(role: .destructive) {
//                            profileModel.deleteItemsFromCloud(record: item.record) { isSuccess in
//                                presentationMode.wrappedValue.dismiss()
//                            }
//                        }
                    }
                    .alert(isPresented: $showingRemoveAllergensAlert) {
                        Alert(title: Text("Remove this item?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Remove")) {
                            // Handle removal of item
                            
                        }, secondaryButton: .cancel())
                    }
                }
            }
        }
        .refreshable {
            //profileModel.profileInfo = []
            //profileModel.fetchItemsFromCloud()
        }
        .listStyle(.plain)
        .navigationTitle("あなたの記録")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("Members.Item.0")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            }
        }
    }
}

extension YourRecordsView {
    struct AllergensListRow: View {
        let headline: String
        let caption1: String
        let caption2: String
        
        var body: some View {
            HStack(spacing: 16.0) {
                Text(headline)
                    .font(.headline)
                Spacer()
                Text(caption1)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(caption2)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            }
        }
    }
}

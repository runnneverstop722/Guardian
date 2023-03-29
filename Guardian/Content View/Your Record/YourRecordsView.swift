//
//  YourRecordsView.swift
//  Guardian
//
//  Created by Teff on 2023/03/24.
//

import SwiftUI
import CloudKit

struct YourRecordsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showUpdateProfile = false
    @State private var showExportPDF = false
    @State private var isAddingNewDiagnosis = false
    @StateObject var diagnosisModel: DiagnosisModel
    let profile: CKRecord
    
    let onDeleteDiagnosis = NotificationCenter.default.publisher(for: Notification.Name("removeDiagnosis"))
    
    init(profile: CKRecord) {
        self.profile = profile
        _diagnosisModel = StateObject(wrappedValue: DiagnosisModel(record: profile))
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
                ForEach(0..<5) { index in
                    NavigationLink(
                        destination: AllergensView(allergenName: "Allergen \(index)"),
                        label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("Allergen \(index)")
                                    .font(.headline)
                                Spacer()
                                HStack {
                                    Text("\(index) episodes")
                                    Text("\(index) tests")
                                }.font(.caption)
                            }
                        })
                }
            }
        }
        .navigationTitle("Your Records")
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
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    showExportPDF.toggle()
                }, label: {
                    Image(systemName: "doc.text")
                    Text("→ PDF")
                })
                .sheet(isPresented: $showExportPDF) {
                    ExportDataView()
                }
            }
        }
    }
}
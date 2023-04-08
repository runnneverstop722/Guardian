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
    @StateObject var episodeModel: EpisodeModel
    @State private var showUpdateProfile = false
    @State private var showExportPDF = false
    @State private var isLoading = true
    @State private var isAddingNewDiagnosis = false
    @State private var showingRemoveAllergensAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var selectedMemberName: String = "Unknown Member"
    @State private var didLoad = false
    let profile: CKRecord
    let existingDiagnosisData = NotificationCenter.default.publisher(for: Notification.Name("existingDiagnosisData"))
    
    init(profile: CKRecord) {
        self.profile = profile
        self._diagnosisModel = StateObject(wrappedValue: DiagnosisModel(record: profile))
        selectedMemberName = profile["firstName"] as? String ?? ""
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: profile))
    }

    var body: some View {
        LoadingView(isShowing: $isLoading) {
            List {
                Section(
                    header: Text("診断記録") // Diagnosis
                        .font(.headline),
                    footer: Text("※医療機関で食物アレルギーと診断された時の記録です。")) { // This is for the first diagnosis result of the selected allergen.
                    ForEach(diagnosisModel.diagnosisInfo, id: \.self) { item in
                        NavigationLink(
                            destination: DiagnosisView(record: item.record),
                            label: {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(item.headline)
                                            .foregroundColor(.blue)
                                            .lineSpacing(10)
                                        Spacer()
                                        Text(item.caption1)
                                            .font(.caption)
                                            
                                    }
                                    Text(item.caption2.joined(separator: ", "))
                                        .font(.caption)
                                    HStack {
                                        Text(item.headline)
                                            .foregroundColor(.blue)
                                            .lineSpacing(10)
                                        Spacer()
                                        Text(item.caption1)
                                            .font(.caption)
                                            
                                    }
                                }
                            })
                    }
                    Button(action: {
                        isAddingNewDiagnosis = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("新規作成") // Add New
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
                    ).onReceive(existingDiagnosisData) { data in
                        if let data = data.object as? DiagnosisListModel {
                            diagnosisModel.diagnosisInfo.insert(data, at: 0)
                        } else {
                            diagnosisModel.fetchItemsFromCloud()
                        }
                    }
                    .onAppear() {
                        if !didLoad {
                            didLoad = true
                            diagnosisModel.fetchItemsFromCloud {
                               episodeModel.fetchItemsFromCloud {
                                    isLoading = false
                                }
                            }
                        }
                    }
                }
                
                Section(
                    header: Text("アレルゲン") // Allergens
                        .font(.headline),
                    footer: Text("※プロフィールで設定したアレルゲンが表示されます。")) { // The listed allergens are set from the profile
                    ForEach(episodeModel.allergens, id: \.self) { item in
                        NavigationLink(
                            destination: MedicalTestAndEpisodeView(allergen: item.record),
                            label: {
                                AllergensListRow(headline: item.headline, caption1: item.caption1, caption2: item.caption2)
                            })
                    }
                }
            }
            .refreshable {
                //profileModel.profileInfo = []
                //profileModel.fetchItemsFromCloud()
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(selectedMemberName)
    //        .toolbar {
    //            ToolbarItem(placement: .navigationBarTrailing) {
    //                Button(action: {
    //                    presentationMode.wrappedValue.dismiss()
    //                }) {
    //                    Image("Members.Item.0")
    //                        .resizable()
    //                        .scaledToFit()
    //                        .frame(width: 40, height: 40)
    //                        .clipShape(Circle())
    //                }
    //            }
    //        }
        }
    }
}

extension YourRecordsView {
    struct AllergensListRow: View {
        let headline: String
        let caption1: String
        let caption2: String
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(headline)
                }
                .font(.body)
                .foregroundColor(.accentColor)
                HStack(spacing: 16.0) {
                    Image(systemName: "cross.case")
                    Text("医療検査:") // Medical Tests
                    Text(caption1)
                    Text(" | ")
                    Image(systemName: "note.text")
                    Text("発症:") // Episodes
                    Text(caption2)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .lineSpacing(10)
        }
    }
}

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct LoadingView<Content>: View where Content: View {

    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {

                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)

                VStack {
                    Text("Loading...")
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)

            }
        }
    }

}

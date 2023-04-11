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
    @State private var isShowingProfileView = false
    @State private var showExportPDF = false
    @State private var isLoading = true
    @State private var isAddingNewDiagnosis = false
    @State private var showingRemoveAllergensAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    
    var selectedMemberName: String = "Unknown Member"
    @State private var didLoad = false
    let profile: CKRecord
    let existingDiagnosisData = NotificationCenter.default.publisher(for: Notification.Name("existingDiagnosisData"))
    
    var profileImage: UIImage {
        if let asset = profile["profileImage"] as? CKAsset, let fileURL = asset.fileURL, let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            return image
        } else {
            return UIImage(systemName: "person.fill") ?? UIImage()
        }
    }
    
    init(profile: CKRecord) {
        self.profile = profile
        self._diagnosisModel = StateObject(wrappedValue: DiagnosisModel(record: profile))
        selectedMemberName = profile["firstName"] as? String ?? ""
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: profile))
    }
    
    struct LeftAlignedHeaderView: View {
        let title: String
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.title2)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.top)
            .padding(.leading)
        }
    }
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            ScrollView(.vertical) {
                LazyVStack(spacing: 16.0) {
                    
                    Section(
                        header: LeftAlignedHeaderView(title: "診断記録"), // Diagnosis
                        footer: Text("※医療機関で食物アレルギーと診断された時の記録です。")
                            .font(.footnote)
                            .foregroundColor(.secondary)) { // This is for the first diagnosis result of the selected allergen.
                                
                                ForEach(diagnosisModel.diagnosisInfo, id: \.self) { item in
                                    NavigationLink(
                                        destination: DiagnosisView(record: item.record),
                                        label: {
                                            DiagnosisListRow(headline: item.headline, caption1: item.caption1, caption2: item.caption2, caption3: item.caption3, caption4: item.caption4, caption5: item.caption5)
                                        })
                                }
                                Button(action: {
                                    isAddingNewDiagnosis = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                        Text("新規作成") // Add New
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                
                                .background(
                                    NavigationLink(
                                        destination: DiagnosisView(profile: profile),
                                        isActive: $isAddingNewDiagnosis,
                                        label: {}
                                    )
                                ).onReceive(existingDiagnosisData) { data in
                                    if let data = data.object as? DiagnosisListModel {
                                        let index = diagnosisModel.diagnosisInfo.firstIndex { $0.record.recordID == data.record.recordID
                                        }
                                        if let index = index {
                                            diagnosisModel.diagnosisInfo[index] = data
                                        } else {
                                            diagnosisModel.diagnosisInfo.insert(data, at: 0)
                                        }
                                    } else if let recordID = data.object as? CKRecord.ID {
                                        diagnosisModel.diagnosisInfo.removeAll {
                                            $0.record.recordID == recordID
                                        }
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
                            .padding(.horizontal)
                    Section(
                        header: LeftAlignedHeaderView(title: "アレルゲン"), // Allergens
                        footer: Text("※プロフィールで設定したアレルゲンが表示されます。") // The listed allergens are set from the profile
                            .font(.footnote)
                            .foregroundColor(.secondary)) {
                                YourRecordsViewGrid(items: episodeModel.allergens.map {
                                    GridItemData(headline: $0.headline,
                                                 caption1: $0.caption1,
                                                 caption2: $0.caption2,
                                                 imageName: "leaf",
                                                 record: $0.record)
                                })
                            }
                }
                .refreshable {
                    isLoading = true
                    diagnosisModel.fetchItemsFromCloud {
                        episodeModel.fetchItemsFromCloud {
                            isLoading = false
                        }
                    }
                }
//                            .listStyle(PlainListStyle())
                //            .listStyle(GroupedListStyle())
                //            .listStyle(InsetGroupedListStyle())
                .navigationTitle(selectedMemberName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowingProfileView = true
                        }) {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        }
                    }
                }
                .sheet(isPresented: $isShowingProfileView) {
                    ProfileView(profile: profile)
                }
            }
        }
    }
}
extension YourRecordsView {
    struct DiagnosisListRow: View {
        let headline: String
        let caption1: String
        let caption2: [String]
        let caption3: String
        let caption4: String
        let caption5: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(headline)
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    Spacer()
                    Text(caption1)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Text(caption2.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                HStack {
//                    if !caption3.isEmpty {
                        Text("病院: ")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(caption3)
                            .font(.subheadline)
                            .foregroundColor(.primary)
//                    }
//                    if !caption4.isEmpty {
                        Text("|")
                            .foregroundColor(.secondary)
                        Text("担当医: ")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(caption4)
                            .font(.subheadline)
                            .foregroundColor(.primary)
//                    }
                }
//                if !caption5.isEmpty {
                    HStack {
                        Text("担当医コメント: ")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(caption5)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                Divider()
//                }
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .lineSpacing(10)
        }
    }
}

extension YourRecordsView {
    struct AllergensListRow: View {
        let headline: String
        let medicalTests: String
        let episodes: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(headline)
                    .font(.headline)
                    .foregroundColor(.accentColor)

                HStack(spacing: 16.0) {
                    Image(systemName: "cross.case")
                        .foregroundColor(.secondary)
                    Text("医療検査:") // Medical Tests
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    Text(medicalTests)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(" | ")
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                    Text("発症:") // Episodes
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    Text(episodes)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .lineSpacing(10)
        }
    }
}

struct YourRecordsViewGrid: View {
    var items: [GridItemData]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                NavigationLink(
                    destination: MedicalTestAndEpisodeView(allergen: item.record),
                    label: {
                        YourRecordsViewGridCell(
                            headline: item.headline,
                            caption1: item.caption1 + " | ",
                            caption2: item.caption2,
                            symbolImage: Image(systemName: "leaf")
                        )
                    })
                    .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

struct YourRecordsViewGridCell: View {
    let headline: String
    let caption1: String
    let caption2: String
    let symbolImage: Image

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            VStack(alignment: .center, spacing: 8.0) {
                symbolImage
                    .resizable()
                    .frame(width: 24.0, height: 24.0)
                    .padding(16.0)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                Text(headline)
                    .font(.headline)
                HStack {
                    Image(systemName: "cross.case")
                        .foregroundColor(.secondary)
                    //                Text("医療検査:") // Medical Tests
                    //                    .font(.subheadline)
                    //                    .foregroundColor(.primary)
                    //                    .fontWeight(.semibold)
                    Text(caption1)
                        .font(.caption)
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                    //                Text("発症:") // Episodes
                    //                    .font(.subheadline)
                    //                    .foregroundColor(.primary)
                    //                    .fontWeight(.semibold)
                    Text(caption2)
                        .font(.caption)
                }
            }
            .multilineTextAlignment(.center)
            .padding(16.0)
            Color(.secondarySystemFill)
                .cornerRadius(10.0)
        }
    }
}

struct GridItemData: Identifiable {
    var id = UUID()
    let headline: String
    let caption1: String
    let caption2: String
    let imageName: String
    let record: CKRecord

    init(headline: String, caption1: String, caption2: String, imageName: String, record: CKRecord) {
        self.headline = headline
        self.caption1 = caption1
        self.caption2 = caption2
        self.imageName = imageName
        self.record = record
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

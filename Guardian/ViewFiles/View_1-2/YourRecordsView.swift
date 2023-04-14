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
    
    private let allergenImages: [String:String] = [
        "えび": "shrimp",
        "かに": "crab",
        "小麦": "wheat",
        "そば": "buckwheat",
        "卵": "egg",
        "乳": "milk",
        "落花生(ピーナッツ)": "peanut",
        "アーモンド": "almond",
        "あわび": "abalone",
        "いか": "squid",
        "いくら": "salmonroe",
        "オレンジ": "orange",
        "カシューナッツ": "cashewnut",
        "キウイフルーツ": "kiwi",
        "牛肉": "beef",
        "くるみ": "walnut",
        "ごま": "sesame",
        "さけ": "salmon",
        "さば": "makerel",
        "大豆": "soybean",
        "鶏肉": "chicken",
        "バナナ": "banana",
        "豚肉": "pork",
        "まつたけ": "matsutake",
        "もも": "peach",
        "やまいも": "yam",
        "りんご": "apple",
        "ゼラチン": "gelatine"
    ]
    
    var selectedMemberName: String = "Unknown Member"
    @State private var didLoad = false
    let profile: CKRecord
    let existingDiagnosisData = NotificationCenter.default.publisher(for: Notification.Name("existingDiagnosisData"))
    let existingAllergenData = NotificationCenter.default.publisher(for: Notification.Name("existingAllergenData"))
    
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
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            ScrollView(.vertical) {
                LazyVStack(spacing: 8.0) {
                    VStack(alignment: .leading) {
                        Text("診断記録")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top)
                        
                        Carousel(diagnosisItems: diagnosisModel.diagnosisInfo)
                            .frame(maxWidth: .infinity)
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
                    .padding(.bottom, 16)
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
                    .onReceive(existingAllergenData) { data in
                        if let data = data.object as? AllergensListModel {
                            let index = episodeModel.allergens.firstIndex { $0.record.recordID == data.record.recordID
                            }
                            if let index = index {
                                episodeModel.allergens[index] = data
                            } else {
                                episodeModel.allergens.insert(data, at: 0)
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
                Spacer()
                Section(
                    header: VStack(alignment: .leading) {
                        Text("アレルゲン")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top)
                    }
                        .padding(.leading), // Allergens
                    footer: Text("※プロフィールで設定したアレルゲンが表示されます。") // The listed allergens are set from the profile
                        .font(.footnote)
                        .foregroundColor(.secondary)
                ) {
                    YourRecordsViewGrid(items: episodeModel.allergens.map {
                        GridItemData(headline: $0.headline,
                                     caption1: $0.caption1,
                                     caption2: $0.caption2,
                                     imageName: allergenImages[$0.headline] ?? "defaultImage",
                                     record: $0.record)
                    })
                }
            }
            .navigationTitle(selectedMemberName)
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

struct Carousel: View {
    var diagnosisItems: [DiagnosisListModel]
    
    @State private var selection = 0
    
    var body: some View {
        VStack {
            if diagnosisItems.isEmpty {
                Card(item: nil)
            } else {
                HStack {
                    Spacer()
                    Text("\(selection + 1) / \(diagnosisItems.count)")
                        .font(.subheadline)
                    Spacer()
                }
                Spacer() // Add Spacer view here
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            withAnimation {
                                if selection > 0 {
                                    selection -= 1
                                }
                            }
                        }
                    TabView(selection: $selection) {
                        ForEach(diagnosisItems.indices, id: \.self) { index in
                            NavigationLink(
                                destination: DiagnosisView(record: diagnosisItems[index].record),
                                label: {
                                    Card(item: diagnosisItems[index])
                                        .padding(10.0)
                                })
                            .buttonStyle(PlainButtonStyle())
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 163.0)
                    .onChange(of: selection) { value in
                        selection = value
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            withAnimation {
                                if selection < diagnosisItems.count - 1 {
                                    selection += 1
                                }
                            }
                        }
                }
            }
        }
    }
}



struct Card: View {
    let item: DiagnosisListModel?
    
    var body: some View {
        if let item = item {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                VStack(alignment: .leading, spacing: 8.0) {
                    HStack {
                        Text(item.headline)
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Text(item.caption1)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Text(item.caption2.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    HStack {
                        Text("病院: ")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(item.caption3)
                            .foregroundColor(.primary)
                        Text("|")
                            .foregroundColor(.secondary)
                        Text("担当医: ")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(item.caption4)
                            .foregroundColor(.primary)
                    }
                    .font(.subheadline)
                    HStack {
                        Text("＂")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(item.caption5)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text("＂")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(16.0)
                .background(LinearGradient(gradient: Gradient(colors: [Color(red: 0.95, green: 0.95, blue: 0.95), Color(red: 0.85, green: 0.85, blue: 0.85)]), startPoint: .top, endPoint: .bottom))
                .cornerRadius(10.0)
            }
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .frame(height: 165.0)
                Text("診断記録がありません")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
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
                    destination: MedicalTestAndEpisodeView(allergen: item.record, symbolImage: Image(item.imageName)),
                    label: {
                        YourRecordsViewGridCell(
                            headline: item.headline,
                            caption1: item.caption1,
                            caption2: item.caption2,
                            record: item.record,
                            symbolImage: Image(item.imageName)
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
    let record: CKRecord
    let symbolImage: Image
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.95, green: 0.95, blue: 0.95), Color(red: 0.85, green: 0.85, blue: 0.85)]), startPoint: .top, endPoint: .bottom)
                .cornerRadius(10.0)
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
            
            VStack(alignment: .center, spacing: 8.0) {
                symbolImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60.0, height: 60.0)
                    .background(Color.accentColor)
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                
                Text(headline)
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
                
                HStack {
                    Image(systemName: "cross.case")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(caption1)
                        .font(.caption)
                        .foregroundColor(Color.accentColor)
                    Text(" | ")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Image(systemName: "note.text")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(caption2)
                        .font(.caption)
                        .foregroundColor(Color.accentColor)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 8.0)
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

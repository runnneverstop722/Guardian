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
    @State private var screenWidth = UIScreen.main.bounds.size.width
    @State private var isLoading = true
    @State private var isAddingNewDiagnosis = false
    @State private var showingRemoveAllergensAlert = false
    @State private var isShowingDiagnosisTutorialAlert = false
    @State private var isShowingAllergensTutorialAlert = false
    @State private var selection = 0
    @State private var allergenCount: Int = 0

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    private let allergenImages: [String:String] = [
        "えび": "shrimp", "かに": "crab", "小麦": "wheat", "そば": "buckwheat", "卵": "egg", "乳": "milk", "落花生(ピーナッツ)": "peanut", "アーモンド": "almond", "あわび": "abalone", "いか": "squid",  "いくら": "salmonroe", "オレンジ": "orange", "カシューナッツ": "cashewnut", "キウイフルーツ": "kiwi", "牛肉": "beef", "くるみ": "walnut", "ごま": "sesame", "さけ": "salmon", "さば": "makerel", "大豆": "soybean", "鶏肉": "chicken", "バナナ": "banana", "豚肉": "pork", "まつたけ": "matsutake", "もも": "peach", "やまいも": "yam", "りんご": "apple", "ゼラチン": "gelatine"
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
                
//MARK: - Diagnosis List View
                LazyVStack(spacing: 8.0) {
                    HStack {
                        Spacer()
                        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
//                            Color(.orange)
                            Color("background")
                                .cornerRadius(14)
                                .frame(maxWidth: (screenWidth - 20))
                                .frame(maxHeight: 250)
                                .opacity(0.2)
                            HStack {
                                Spacer()
                                VStack {
                                    VStack {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text("Diagnosis").font(.footnote).fontWeight(.light).shadow(radius: 6)
                                                    Spacer()
                                                }
                                                Text("初診記録").font(.title).bold()
                                                Label(
                                                    diagnosisModel.diagnosisInfo.count == 0 ? "0 / 0 件" : "\(selection + 1) / \(diagnosisModel.diagnosisInfo.count) 件", systemImage: "menucard")
                                                    .font(.footnote)
                                                    .fontWeight(.medium)
                                                    .shadow(radius: 6)
                                                    .bold()
                                                Spacer()
                                            }
                                            .padding(.top)
                                            Spacer()
                                        }
                                        .padding(.leading)
                                        .frame(maxWidth: (screenWidth-20))
                                        .frame(height: 80)
                                        .shadow(radius: 12)
                                        //                                    Spacer()
                                    }
                                    Carousel(diagnosisItems: $diagnosisModel.diagnosisInfo, selection: $selection)
                                        .frame(maxWidth: .infinity)
                                    
                                }
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            VStack {
                                HStack {
                                    Spacer()
                                    Button {
                                        isAddingNewDiagnosis = true
                                    } label: {
                                        Symbols.addNew
                                            .foregroundColor(.primary)
                                    }
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
                                    Button {
                                        isShowingDiagnosisTutorialAlert = true
                                    } label: {
                                        Symbols.question
                                            .padding()
                                            .foregroundColor(.primary)
                                    }
                                }
                                Spacer()
                            }
                            .alert(isPresented: $isShowingDiagnosisTutorialAlert) {
                                Alert(title: Text("初診記録とは？"),
                                      message: Text("初めて医師より食物アレルギーと診断された際に記録します。\n５つの診断名から選択できます。\n(即時型IgE抗体アレルギー / 遅延型IgG抗体アレルギー / アレルギー性腸炎 / 好酸球性消化管疾患 / 新生児・乳児食物蛋白誘発胃腸症)"),
                                      dismissButton: .default(Text("OK")))
                            }
                        }
                        
                        Spacer()
                    }
                    
                }
                
                Spacer()
                
//MARK: - Allergen Grid Items View
                LazyVStack(spacing: 8.0) {
                    HStack {
                        Spacer()
                        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
//                            Image("card_bg2")
//                                .resizable()
//                                .scaleEffect(2.5)
//                                .blur(radius: 40)
//                                .cornerRadius(14)
//                                .frame(maxWidth: (screenWidth - 20))
//                                .frame(maxHeight: 250)
//                                .opacity(0.7)
                            HStack {
                                Spacer()
                                VStack {
                                    VStack {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text("Allergens").font(.footnote).fontWeight(.light).shadow(radius: 6)
                                                    Spacer()
                                                }
                                                Text("アレルゲン").font(.title).bold()
                                                Label("\(allergenCount) 件", systemImage: "allergens")
                                                    .font(.footnote)
                                                    .fontWeight(.medium)
                                                    .shadow(radius: 6)
                                                    .bold()
                                                Spacer()
                                            }
                                            .padding(.top)
                                            Spacer()
                                        }
                                        .padding(.leading)
                                        .frame(maxWidth: (screenWidth-20))
                                        .frame(height: 80)
                                        .shadow(radius: 12)
                                    }
                                    VStack {
                                        YourRecordsViewGrid(items: episodeModel.allergens.map {
                                            GridItemData(headline: $0.headline,
                                                         caption1: $0.caption1,
                                                         caption2: $0.caption2,
                                                         imageName: allergenImages[$0.headline] ?? "defaultImage",
                                                         record: $0.record)
                                        }, allergenCount: $allergenCount)
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.bottom, 20)
                            VStack {
                                HStack {
                                    Spacer()
                                    Button {
                                        isShowingAllergensTutorialAlert = true
                                    } label: {
                                        Symbols.question
                                            .padding()
                                            .foregroundColor(.primary)
                                    }
                                }
                                Spacer()
                            }
                            .alert(isPresented: $isShowingAllergensTutorialAlert) {
                                Alert(title: Text("アレルゲンのリストを編集するには、"),
                                      message: Text("プロフィール設定画面にてアレルゲンの設定を変更してください。"),
                                      dismissButton: .default(Text("OK")))
                            }
                        }
                        Spacer()
                    }
                }
                .background(
                    Color("background")
//                    Color(.orange)
                        .cornerRadius(14)
                        .frame(maxWidth: (screenWidth - 20))
                        .opacity(0.2)
                    
                )
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

//MARK: - Structures
struct Carousel: View {
    @Binding var diagnosisItems: [DiagnosisListModel]
    @Binding var selection: Int
    
    var body: some View {
        VStack {
            if diagnosisItems.isEmpty {
                Card(item: nil)
            } else {
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
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always)) //Page Indicator
                .frame(height: 164.0)
                .onChange(of: selection) { value in
                    selection = value
                }
            }
        }
    }
}


struct Card: View {
    let item: DiagnosisListModel?
    @State private var selection = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if let item = item {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                VStack {
//                    Spacer()
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
                        Text("")
                            .font(.callout)
                    }
                    .padding(14.0)
                    .background(
                        Group {
                            Color("detail-background")
                        }
                    )
                    .cornerRadius(10.0)
                }
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
            }
        } else {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text("記録が登録されていません。")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    }
                    .padding(90.0)
                    .background(
                        Group {
                            Color("detail-background")
                        }
                    )
                    .cornerRadius(10.0)
                    Spacer()
                }
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
            }
        }
    }
}

struct YourRecordsViewGrid: View {
    
    var items: [GridItemData]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    @Binding var allergenCount: Int
    
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
        .onAppear {
            allergenCount = items.count
        }
    }
}

struct YourRecordsViewGridCell: View {
    let headline: String
    let caption1: String
    let caption2: String
    let record: CKRecord
    let symbolImage: Image
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            Group {
                Color("detail-background")
//                if colorScheme == .dark {
//                    Color(.secondarySystemGroupedBackground)
//                    
//                } else {
//                    Color(red: 252/255, green: 227/255, blue: 138/255)
//                }
            }
            .cornerRadius(10.0)
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
            
            VStack(alignment: .center, spacing: 8.0) {
                symbolImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60.0, height: 60.0)
                    .background(Color.accentColor)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black) // Updated line
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                
                Text(headline)
                    .font(.headline)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
//                    .foregroundColor(.white)
                
                HStack {
                    Symbols.medicalTest
                        .font(.subheadline)
//                        .foregroundColor(.white)
                    Text(caption1)
                        .font(.caption)
//                        .foregroundColor(.white)
                    Text(" | ")
                        .font(.subheadline)
//                        .foregroundColor(.primary)
                    Symbols.episode
                        .font(.subheadline)
//                        .foregroundColor(.white)
                    Text(caption2)
                        .font(.caption)
//                        .foregroundColor(.white)
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

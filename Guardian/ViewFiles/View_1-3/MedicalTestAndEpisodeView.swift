//
//  MedicalTestAndEpisodeView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//
import SwiftUI
import CloudKit

@MainActor class MedicalTest: ObservableObject {
    @Published var bloodTest: [BloodTest] = []
    @Published var skinTest: [SkinTest] = []
    @Published var oralFoodChallenge: [OralFoodChallenge] = []
    var allergen: CKRecord
    init(allergen: CKRecord) {
        self.allergen = allergen
    }
    
    var totalTest: Int {
        return bloodTest.count + skinTest.count + oralFoodChallenge.count
    }
    
    func cleanUpdateUnSaveData() {
        bloodTest.removeAll { $0.record == nil }
        skinTest.removeAll { $0.record == nil }
        oralFoodChallenge.removeAll { $0.record == nil }
    }
}

struct MedicalTestAndEpisodeView: View {
    @StateObject var episodeModel: EpisodeModel
    @StateObject private var medicalTest: MedicalTest
    @State private var episodeDate: Date = Date()
    @State private var firstKnownExposure: Bool = false
    @State private var isLoading = true

    @State private var showChartView = false

    @State private var showAlert = false
    @State private var showMedicalTestView = false
    @State private var showEpisodeView = false

    @State private var viewDidLoad = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    var allergenName: String = "Unknown Allergen"
    let allergen: CKRecord
    let existingEpisodeData = NotificationCenter.default.publisher(for: Notification.Name("existingEpisodeData"))
    @State private var diagnosis = [DiagnosisListModel]()
    let symbolImage: Image

    init(allergen: CKRecord, symbolImage: Image) {
        self.allergen = allergen
        allergenName = allergen["allergen"] as? String ?? ""
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: allergen))
        _medicalTest = StateObject(wrappedValue: MedicalTest(allergen: allergen))
        self.symbolImage = symbolImage
    }

    func fetchLocalData() {
        let allergenID = medicalTest.allergen.recordID.recordName
        medicalTest.bloodTest = PersistenceController.shared.fetchBloodTest(allergenID: allergenID).compactMap({
            BloodTest(entity: $0)
        })
        medicalTest.skinTest = PersistenceController.shared.fetchSkinTest(allergenID: allergenID).compactMap({
            SkinTest(entity: $0)
        })
        medicalTest.oralFoodChallenge = PersistenceController.shared.fetchOralFoodChallenge(allergenID: allergenID).compactMap({
            OralFoodChallenge(entity: $0)
        })
        if let profileID = (medicalTest.allergen["profile"] as? CKRecord.Reference)?.recordID.recordName {
            diagnosis = PersistenceController.shared.fetchDiagnosis(profileID: profileID, allergen: allergenName).compactMap({
                DiagnosisListModel(entity: $0)
            })
        }
    }
    private func fetchData() {
        fetchLocalData()
        let dispatchWork = DispatchGroup()
        let reference = CKRecord.Reference(recordID: medicalTest.allergen.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "allergen == %@", reference)

        //MARK: - Blood
        let bloodTestQuery = CKQuery(recordType: "BloodTest", predicate: predicate)
        bloodTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let bloodTestQueryOperation = CKQueryOperation(query: bloodTestQuery)
        dispatchWork.enter()
        bloodTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = BloodTest(record: returnedRecord) {
                    let isExist = self.medicalTest.bloodTest.contains { $0.record?.recordID == object.record?.recordID
                    }
                    if !isExist {
                        self.medicalTest.bloodTest.append(object)
                    }
                }
            }
        }
        bloodTestQueryOperation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.medicalTest.bloodTest = self.medicalTest.bloodTest.sorted(by: { item1, item2 in
                        return item1.bloodTestDate.compare(item2.bloodTestDate) == .orderedDescending
                    })
                case .failure(let error):
                    print("Error fetching Blood Test: \(error.localizedDescription)")
                }
                dispatchWork.leave()
            }
        }

        addOperation(operation: bloodTestQueryOperation)
        
        //MARK: - Skin
        
        let skinTestQuery = CKQuery(recordType: "SkinTest", predicate: predicate)
        skinTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let skinTestQueryOperation = CKQueryOperation(query: skinTestQuery)
        dispatchWork.enter()
        skinTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = SkinTest(record: returnedRecord) {
                    let isExist = self.medicalTest.skinTest.contains { $0.record?.recordID == object.record?.recordID
                    }
                    if !isExist {
                        self.medicalTest.skinTest.append(object)
                    }
                }
            }
        }
        skinTestQueryOperation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.medicalTest.skinTest = self.medicalTest.skinTest.sorted(by: { item1, item2 in
                        return item1.skinTestDate.compare(item2.skinTestDate) == .orderedDescending
                    })
                case .failure(let error):
                    print("Error fetching Skin Test: \(error.localizedDescription)")
                }
                dispatchWork.leave()
            }
        }
        addOperation(operation: skinTestQueryOperation)
        
        //MARK: - OFC
        dispatchWork.enter()
        let OFCQuery = CKQuery(recordType: "OralFoodChallenge", predicate: predicate)
        OFCQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let OFCQueryOperation = CKQueryOperation(query: OFCQuery)
        
        OFCQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = OralFoodChallenge(record: returnedRecord) {
                    let isExist = self.medicalTest.oralFoodChallenge.contains { $0.record?.recordID == object.record?.recordID
                    }
                    if !isExist {
                        self.medicalTest.oralFoodChallenge.append(object)
                    }
                }
            }
        }
        OFCQueryOperation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.medicalTest.oralFoodChallenge = self.medicalTest.oralFoodChallenge.sorted(by: { item1, item2 in
                        return item1.oralFoodChallengeDate.compare(item2.oralFoodChallengeDate) == .orderedDescending
                    })
                case .failure(let error):
                    print("Error fetching OFC: \(error.localizedDescription)")
                }
                dispatchWork.leave()
            }
        }
        addOperation(operation: OFCQueryOperation)
        episodeModel.fetchItemsFromLocalCache()
        
        dispatchWork.enter()
        episodeModel.fetchItemsFromCloud {
            dispatchWork.leave()
        }
        
        dispatchWork.notify(queue: DispatchQueue.main) {
            isLoading = false
        }
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            List {
                Section(header: Text("診断歴") // Medical Test
                    .font(.title2)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .fontWeight(.semibold)
                    .padding(.top)) {
                        if diagnosis.isEmpty {
                            Text("⚠️本アレルゲンに対して診断記録がありません。")
                                .font(.subheadline)
                        } else {
                            ForEach(diagnosis, id: \.id) { item in
                                Text("\(item.caption1) 「\(item.caption3)」にて「\(item.headline)」と診断されました。")
                                    .font(.subheadline)
                            }
                        }
                    }
                Section(header: Text("医療検査記録") // Medical Test
                    .font(.title2)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .fontWeight(.semibold)
                    .padding(.top)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("血液(特異的IgE抗体)検査") // Blood Test
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(medicalTest.bloodTest.count)")
                                Text("件")
                            }
                            Divider()
                            HStack {
                                Text("皮膚プリック検査") // Skin Test
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(medicalTest.skinTest.count)")
                                Text("件")
                            }
                            Divider()
                            HStack {
                                Text("食物経口負荷試験") // Oral Food Challenge
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(medicalTest.oralFoodChallenge.count)")
                                Text("件")
                            }
                        }
                        
                        Button(action: {
                            showMedicalTestView = true
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "book.fill")
                                Text("詳細")
                                Spacer()
                            }
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? Color(.systemBackground) : .white)
                            .padding()
                            .background(Color(uiColor: .systemIndigo))
                            .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .background(
                            NavigationLink(
                                destination: MedicalTestView().environmentObject(medicalTest),
                                isActive: $showMedicalTestView,
                                label: {}
                            )
                            .opacity(0)
                        )
                
                    }
                // Episode
                Section(header: Text("発症記録")
                    .font(.title2)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .fontWeight(.semibold)
                    .padding(.top)) {
                        if episodeModel.episodeInfo.isEmpty {
                            Text("⚠️本アレルゲンに対して発症記録がありません。")
                                .font(.subheadline)
                        } else {
                            ForEach(episodeModel.episodeInfo, id: \.id) { item in
                                NavigationLink(
                                    destination: EpisodeView(allergen: episodeModel.allergen, episode: item.record),
                                    label: { EpisodeListRow(headline: item.headline, caption1: item.caption1, caption2: item.caption2, caption3: item.caption3, caption4: item.caption4, caption5: item.caption5)
                                    })
                            }
                        }
                        ZStack {
                           NavigationLink(destination: EpisodeView(record: allergen)) {
                               EmptyView()
                           }
                            HStack {
                                Spacer()
                                Symbols.addNew
                                Text("新規作成")
                                Spacer()
                            }
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? Color(.systemBackground) : .white)
                            .padding()
                            .background(colorScheme == .dark ? Color(.systemBlue).opacity(0.8) : Color.blue)
                            .cornerRadius(10)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .onReceive(existingEpisodeData) { data in
                            DispatchQueue.main.async {
                                if let data = data.object as? EpisodeListModel {
                                    let index = episodeModel.episodeInfo.firstIndex { $0.record.recordID == data.record.recordID
                                    }
                                    if let index = index {
                                        episodeModel.episodeInfo[index] = data
                                    } else {
                                        episodeModel.episodeInfo.insert(data, at: 0)
                                    }
                                } else if let recordID = data.object as? CKRecord.ID {
                                    episodeModel.episodeInfo.removeAll {
                                        $0.record.recordID == recordID
                                    }
                                }
                            }
                        }
                    }
            }
            .navigationTitle(allergenName)
            .listStyle(.sidebar)
            .toolbar {
                Button() {
                    showAlert.toggle()
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("医療検査・発症記録を\n削除しますか？"),
                    message: Text(""),
                    primaryButton: .destructive(Text("削除")) {
                        // Delete all data action
                        episodeModel.deleteAllData()
                        for test in medicalTest.bloodTest where test.record != nil {
                            episodeModel.deleteRecord(record: test.record!)
                        }
                        for test in medicalTest.skinTest where test.record != nil {
                            episodeModel.deleteRecord(record: test.record!)
                        }
                        for test in medicalTest.oralFoodChallenge where test.record != nil {
                            episodeModel.deleteRecord(record: test.record!)
                        }
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .onAppear {
                if !viewDidLoad {
                    viewDidLoad = true
                    fetchData()
                } else {
                    medicalTest.cleanUpdateUnSaveData()
                }
            }
        }
    }
}

extension MedicalTestAndEpisodeView {
    struct EpisodeListRow: View {
        let headline: String
        let caption1: String
        let caption2: String
        let caption3: String
        let caption4: String
        let caption5: String
        
        var body: some View {
            VStack {
                HStack(spacing: 16.0) {
                    Text(headline)
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    Spacer()
                    if !caption1.isEmpty {
                        Badge(text: caption1)
                    }
                    if !caption2.isEmpty {
                        Badge(text: caption2)
                    }
                    if !caption5.isEmpty {
                        Badge(text: caption5)
                    }
                }
                if !caption3.isEmpty {
                    HStack {
                        Text("・接触タイプ: ")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(caption3)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                if !caption4.isEmpty {
                    HStack {
                        Text("・症状: ")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Text(caption4)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                }
            }.lineSpacing(10)
        }
    }
    struct Badge: View {
        let text: String
        
        var body: some View {
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: 0x576CBC))
                .cornerRadius(10)
        }
    }
}

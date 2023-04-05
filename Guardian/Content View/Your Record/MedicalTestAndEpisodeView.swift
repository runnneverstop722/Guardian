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
}

struct MedicalTestAndEpisodeView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var episodeModel:EpisodeModel
    @StateObject private var mediacalTest: MedicalTest
    @State private var episodeDate: Date = Date()
    @State private var firstKnownExposure: Bool = false
    @State private var allergistComment: String = ""
    @State private var isLoading = true
    
    @State private var showAlert = false
    @State private var showMedicalTestView = false
    @State private var showEpisodeView = false
    @State private var isAddingNewEpisode = false
    @State private var isUpdate = false
    @State private var showingRemoveDiagnosisAlert = false
    @State private var viewDidLoad = false
    var allergenName: String = "Unknown Allergen"
    
    let allergen: CKRecord
    let existingEpisodeData = NotificationCenter.default.publisher(for: Notification.Name("existingEpisodeData"))
    
    init(allergen: CKRecord) {
        self.allergen = allergen
        allergenName = allergen["allergen"] as? String ?? ""
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: allergen))
        _mediacalTest = StateObject(wrappedValue: MedicalTest(allergen: allergen))
    }
    
    
    private func fetchData() {
        let dispatchWork = DispatchGroup()
        let reference = CKRecord.Reference(recordID: mediacalTest.allergen.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "allergen == %@", reference)
        
        //MARK: - Blood
        let bloodTestQuery = CKQuery(recordType: "BloodTest", predicate: predicate)
        bloodTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let bloodTestQueryOperation = CKQueryOperation(query: bloodTestQuery)
        dispatchWork.enter()
        bloodTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = BloodTest(record: returnedRecord) {
                    self.mediacalTest.bloodTest.append(object)
                }
            }
        }
        bloodTestQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED 'Blood Test' queryResultBlock")
            DispatchQueue.main.async {
                self.mediacalTest.bloodTest = self.mediacalTest.bloodTest.sorted(by: { item1, item2 in
                    return item1.bloodTestDate.compare(item2.bloodTestDate) == .orderedAscending
                })
                dispatchWork.leave()
            }
        }
        addOperation(operation: bloodTestQueryOperation)
        
        //MARK: - Skin
        
        let skinTestQuery = CKQuery(recordType: "SkinTest", predicate: predicate)
        skinTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let skinTestQueryOperation = CKQueryOperation(query: skinTestQuery)
        dispatchWork.enter()
        skinTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = SkinTest(record: returnedRecord) {
                    self.mediacalTest.skinTest.append(object)
                }
            }
        }
        skinTestQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED 'Skin Test' queryResultBlock")
            DispatchQueue.main.async {
                self.mediacalTest.skinTest = self.mediacalTest.skinTest.sorted(by: { item1, item2 in
                    return item1.skinTestDate.compare(item2.skinTestDate) == .orderedAscending
                })
                dispatchWork.leave()
            }
        }
        addOperation(operation: skinTestQueryOperation)
        
        //MARK: - OFC
        dispatchWork.enter()
        let OFCQuery = CKQuery(recordType: "OralFoodChallenge", predicate: predicate)
        OFCQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let OFCQueryOperation = CKQueryOperation(query: OFCQuery)
        
        OFCQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = OralFoodChallenge(record: returnedRecord) {
                    self.mediacalTest.oralFoodChallenge.append(object)
                }
            }
        }
        OFCQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED 'Oral Food Challenge' queryResultBlock")
            DispatchQueue.main.async {
                self.mediacalTest.oralFoodChallenge = self.mediacalTest.oralFoodChallenge.sorted(by: { item1, item2 in
                    return item1.oralFoodChallengeDate.compare(item2.oralFoodChallengeDate) == .orderedAscending
                })
                dispatchWork.leave()
            }
        }
        
        addOperation(operation: OFCQueryOperation)
        
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
                Section(header: Text("医療検査の記録") // Medical Test
                    .font(.headline)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("血液検査") // Blood Test
                                Spacer()
                                Text("\(mediacalTest.bloodTest.count) records")
                            }
                            Divider()
                            HStack {
                                Text("皮膚プリックテスト") // Skin Test
                                Spacer()
                                Text("\(mediacalTest.skinTest.count) records")
                            }
                            Divider()
                            HStack {
                                Text("食物経口負荷試験") // Oral Food Challenge
                                Spacer()
                                Text("\(mediacalTest.oralFoodChallenge.count) records")
                            }
                        }
                        
                        NavigationLink(
                            destination: MedicalTestView().environmentObject(mediacalTest),
                            isActive: $showMedicalTestView
                        ) {
                            Button(action: {
                                showMedicalTestView = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                    Text("新規作成") // Add New
                                    Text("＆")
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("記録内容の確認") // Confirm Details
                                    Spacer()
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                
                Section(header: Text("発症記録") // Episode
                    .font(.headline)) {
                        ForEach(episodeModel.episodeInfo, id: \.self) { item in
                            NavigationLink(
                                destination: EpisodeView(episode: item.record),
                                label: { EpisodeListRow(headline: item.headline, caption1: item.caption1, caption2: item.caption2, caption3: item.caption3)
                                })
                        }
                        Button(action: {
                            showEpisodeView = true
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
                                destination: EpisodeView(record: allergen),
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
                
                
                
                Section(header: Text("担当医のコメント") // Allergist's Comment
                    .font(.headline)) {
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
                Button() {
                    showAlert.toggle()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .tint(.red)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("医療検査・発症記録を\n削除します。\nよろしいですか？"), // Delete all items from the medical data and the episode. Are you sure?
                    message: Text(""),
                    primaryButton: .destructive(Text("削除")) { // Delete
                        // Delete all data action
                        episodeModel.deleteAllData()
                        for test in mediacalTest.bloodTest where test.record != nil {
                            episodeModel.deleteRecord(record: test.record!)
                        }
                        for test in mediacalTest.skinTest where test.record != nil {
                            episodeModel.deleteRecord(record: test.record!)
                        }
                        for test in mediacalTest.oralFoodChallenge where test.record != nil {
                            episodeModel.deleteRecord(record: test.record!)
                        }
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("キャンセル")) // Cancel
                )
            }
            .onAppear {
                if !viewDidLoad {
                    viewDidLoad = true
                    fetchData()
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
            }
        }
    }
}

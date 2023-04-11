//  Members.swift

import SwiftUI
import PhotosUI
import CloudKit

struct MembersView: View {
    @StateObject var profileModel: ProfileModel
    @State private var isMainUserSettingPresented = false
    @State private var isUpdate = false
    @State private var showDeleteAlert = false
    @State private var editItem: MemberListModel?
    @State private var deleteItem: MemberListModel?
    @State private var accountStatusAlertShown = false
    @Environment(\.presentationMode) var presentationMode
    
    let onUpdateProfile = NotificationCenter.default.publisher(for: Notification.Name("updateProfile"))
    init() {
        _profileModel = StateObject(wrappedValue: ProfileModel())
    }
    init(record: CKRecord) {
        _profileModel = StateObject(wrappedValue: ProfileModel(profile: record))
    }
    
    var body: some View {
        List {
            ForEach(profileModel.profileInfo, id: \.self) { item in
                NavigationLink(value: item) {
                    MembersListRow(headline: item.headline, caption: item.caption, image: item.image)
                }
                .swipeActions(edge: .leading) {
                    Button(role: .none) {
                        editItem = item
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    } .tint(.indigo)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteItem = item
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
            .onMove(perform: move(fromOffsets:toOffset:))
            .onDelete { indexSet in
                indexSet.forEach { index in
                    deleteItem = profileModel.profileInfo[index]
                    showDeleteAlert = true
                }
            }
        }
        
//            .alert(item: $deleteItem, content: { item in
//                Alert(title: Text("このメンバーを削除しますか？"), message: Text(""), primaryButton: .destructive(Text("削除")) {
//                    profileModel.deleteItemsFromCloud(record: item.record) { _ in
//                    }
//                }, secondaryButton: .cancel(Text("キャンセル")))
//
//            })
//        }
            .alert(item: $deleteItem) { item in
                Alert(
                    title: Text("このメンバーを削除しますか？"),
                    message: Text(""),
                    primaryButton: .destructive(Text("削除")) {
                        profileModel.deleteItemsFromCloud(record: item.record) { _ in
                            // Delete was successful, hide the alert and remove the item from the list
                            deleteItem = nil
                            if let index = profileModel.profileInfo.firstIndex(where: { $0.record.recordID == item.record.recordID }) {
                                withAnimation {
                                    profileModel.profileInfo.remove(at: index)
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル")) {
                        showDeleteAlert = false
                    }
                )
            }
        .refreshable {
//            profileModel.profileInfo = []
            profileModel.fetchItemsFromCloud()
        }
        .listStyle(.plain)
        .navigationTitle("管理メンバー")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if profileModel.accountStatus != .available {
                        accountStatusAlertShown = true
                    } else {
                        profileModel.isAddMemberPresented = true
                    }
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
//                        Text("メンバーを追加")
                        Spacer()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationDestination(for: MemberListModel.self) { item in
            YourRecordsView(profile: item.record)
        }
        .sheet(isPresented: $profileModel.isAddMemberPresented) {
            ProfileView()
        }
        .sheet(item: $editItem) { item in
            ProfileView(profile: item.record)
        }
        .onReceive(onUpdateProfile) { data in
            if let data = data.object as? CKRecord.ID {
                profileModel.profileInfo.removeAll { $0.record.recordID == data
                }
            } else if let data = data.object as? MemberListModel {
                if let row = profileModel.profileInfo.firstIndex(where: {$0.record.recordID == data.record.recordID}) {
                    profileModel.profileInfo[row] = data
                } else {
                    profileModel.profileInfo.append(data)
                }
            }
        }
        .alert("iCloud Account Disabled", isPresented: $accountStatusAlertShown, actions: {
            Button("Cancel", role: .cancel, action: {})
        }, message: {
            Text("Please Login!")
        })
        .task {
            try? await profileModel.getiCLoundStatus()
            if profileModel.accountStatus != .available {
                accountStatusAlertShown = true
            }
        }
    }
}

private extension MembersView {
    func editItems() {
        
    }
    
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        profileModel.profileInfo.move(fromOffsets: source, toOffset: destination)
    }
}

extension MembersView {
    struct MembersListRow: View {
        let headline: String
        let caption: String
        let image: Image?
        
        var body: some View {
            HStack(spacing: 16.0) {
                if let image = image {
                    image
                        .resizable()
                        .frame(width: 56.0, height: 56.0)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .scaledToFill()
                        .clipShape(Circle())
                        .font(.system(size: 30))
                        .frame(width: 56.0, height: 56.0)
                        .foregroundColor(.white)
                        .background {
                            Circle().fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                }
                VStack(alignment: .leading, spacing: 4.0) {
                    Text(headline)
                        .font(.headline)
                    Text(caption)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
//
//struct Members_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            MembersView()
//        }
//    }
//}

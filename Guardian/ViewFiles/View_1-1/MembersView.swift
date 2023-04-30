//  Members.swift

import SwiftUI
import PhotosUI
import CloudKit

struct MembersView: View {
    @StateObject var profileModel: ProfileModel
    @State private var isMainUserSettingPresented = false
    @State private var isUpdate = false
    @State private var isFirstProfile = true
    @State private var showDeleteAlert = false
    @State private var editItem: MemberListModel?
    @State private var deleteItem: MemberListModel?
    @State private var accountStatusAlertShown = false
    @Environment(\.presentationMode) var presentationMode
    
    let onUpdateProfile = NotificationCenter.default.publisher(for: Notification.Name("updateProfile"))
    init() {
        _profileModel = StateObject(wrappedValue: ProfileModel())
    }
    
    var body: some View {
        ZStack {
            if isFirstProfile {
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                    VStack(alignment: .center, spacing: 50) {
                        Spacer()
                        VStack(spacing: 20) {
                            Image("profile")
                                .resizable()
                                .scaledToFit()
                            Text("プロフィールを作成しましょう。")
                                .font(.title3)
                        }
                        
                        VStack(spacing: 20) {
                            Text("プロフィールを作成したら、")
                            HStack {
                                Image(systemName: "hand.point.up.fill")
                                    .font(.title2)
                                Text("医師から食物アレルギーと診断された時")
                            }
                            HStack {
                                Image(systemName: "hand.point.up.fill")
                                    .font(.title2)
                                Text("医療検査を受けた時(血液・皮膚・経口負荷試験)")
                            }
                            HStack {
                                Image(systemName: "hand.point.up.fill")
                                    .font(.title2)
                                Text("日常で食物アレルギーが発症した時")
                            }
                            Text("あなたのiCloudに記録して、")
                            Text("いつどこでも共有できるようになります。")
                        }
                        .font(.headline)
                        .fontWeight(.regular)
                        
                        Button(action: {
                            accountStatusAlertShown = true
                            profileModel.isAddMemberPresented = true
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                Text("プロフィールを作成")
                            }
                        }
                        .buttonStyle(GradientButtonStyle())
                        .sheet(isPresented: $profileModel.isAddMemberPresented) {
                            ProfileView()
                        }
                        Spacer()
                    }.padding(.horizontal)
                }
            } else {
                List {
                    ForEach(profileModel.profileInfo, id: \.id) { item in
                        NavigationLink(value: item) {
                            MembersListRow(headline: item.headline, caption: item.caption, image: item.image)
                        }
                        .swipeActions(edge: .leading) {
                            Button(role: .none) {
                                editItem = item
                            } label: {
                                Label("Edit", systemImage: "slider.horizontal.3")
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
                }
                .alert(item: $deleteItem) { item in
                    Alert(
                        title: Text("このメンバーを削除しますか？"),
                        message: Text(""),
                        primaryButton: .destructive(Text("削除")) {
                            profileModel.deleteItemsFromCloud(record: item.record) { _ in
                                // Delete was successful, hide the alert and remove the item from the list
                                deleteItem = nil
                                withAnimation {
                                if let index = profileModel.profileInfo.firstIndex(where: { $0.record.recordID == item.record.recordID }) {
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
                .listStyle(.insetGrouped)
                .navigationTitle("家族一覧")
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
                                Symbols.newProfile
                                    .font(.title2)
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
                .alert("iCloudアカウントがログインされていません", isPresented: $accountStatusAlertShown, actions: {
                    Button("キャンセル", role: .cancel, action: {})
                }, message: {
                    Text("ログインしてください")
                })
            }
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
        .task {
            try? await profileModel.getiCloudStatus()
            if profileModel.accountStatus != .available {
                accountStatusAlertShown = true
            }
        }
        .onChange(of: profileModel.profileInfo.count) { newValue in
            isFirstProfile = newValue == 0
        }
        .onAppear() {
            isFirstProfile = profileModel.profileInfo.isEmpty
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

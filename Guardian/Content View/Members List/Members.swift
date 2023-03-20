//
//  Members.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import PhotosUI
import CloudKit

struct Profile: View {
    var body: some View {
        #if os(macOS)
        NewProfile()
            .labelsHidden()
            .frame(width: 400)
            .padding()
        #else
        NavigationView {
            NewProfile()
        }
        #endif
    }
}

struct Members: View {
    @StateObject var vm = ProfileModel()
	@State var items = MemberList.data
    @State private var isUserSettingPresented = false
	@State private var isAddMemberPresented = false
	
	var body: some View {
		List {
			ForEach(items) { item in
				NavigationLink(value: item) {
					Row(headline: item.headline, caption: item.caption, image: Image(item.imageName))
				}
			}
            ForEach(vm.profileInfo, id: \.self) {
                NavigationLink(value: item) {
                    Row(headline: item.headline, caption: item.caption, image: Image(item.imageName))
                }
            }
//            if let url = vm.profileInfoImage, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
//                Image(uiImage: image)
//                    .resizable()
//            }
			.onDelete(perform: deleteItems(atOffsets:))
			.onMove(perform: move(fromOffsets:toOffset:))
		}
		.listStyle(.plain)
		.navigationTitle("管理メンバーリスト")
		.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("プロフィール設定") {
                    isUserSettingPresented = true
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
				Button("+メンバーを追加") {
					isAddMemberPresented = true
				}
			}
		}
		.navigationDestination(for: MemberList.self) { item in
			MemberDetailView()
		}
		.sheet(isPresented: $isAddMemberPresented) {
			NewProfile()
		}
	}
}

private extension Members {
	func deleteItems(atOffsets offsets: IndexSet) {
		items.remove(atOffsets: offsets)
	}
	
	func move(fromOffsets source: IndexSet, toOffset destination: Int) {
		items.move(fromOffsets: source, toOffset: destination)
	}
}

extension Members {
	struct Row: View {
		let headline: String
		let caption: String
		let image: Image
		
		var body: some View {
			HStack(spacing: 16.0) {
				image
					.resizable()
					.frame(width: 56.0, height: 56.0)
					.clipShape(Circle())
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

struct Members_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			Members()
		}
	}
}

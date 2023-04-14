//
//  Awareness   .swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct Awareness: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
//                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .padding(.top, 50)
                    Text("Chef")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                    
                    Text("I have a Food Allergy")
                        .multilineTextAlignment(.center)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("to:")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Shrimp, Egg, Peanuts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Please ensure that my menu is free from them.")
                        .font(.title3)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Thank you for your understanding.")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                
                if appState.isAwarenessTabDisabled {
                    NoticeView()
                        .frame(width: geometry.size.width, height: geometry.size.height - geometry.safeAreaInsets.top)
                }
            }
        }
    }
}

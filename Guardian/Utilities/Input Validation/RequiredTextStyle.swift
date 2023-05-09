//
//  RequiredTextStyle.swift
//  Guardian
//
//  Created by Teff on 2023/04/19.
//

import SwiftUI

struct RequiredTextStyle: ViewModifier {
    var isEmpty: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(isEmpty ? Color.red.opacity(0.3) : Color.clear)
            .cornerRadius(5)
    }
}


//struct RequiredTextStyle_Previews: PreviewProvider {
//    static var previews: some View {
//        RequiredTextStyle(isEmpty: <#T##Bool#>)
//    }
//}

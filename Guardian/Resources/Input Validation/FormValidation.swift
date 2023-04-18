//
//  FormValidation.swift
//  Guardian
//
//  Created by Teff on 2023/04/18.
//

import Foundation

struct FormValidation {
    let isLastNameEmpty: Bool
    let isFirstNameEmpty: Bool
    let isAllergensEmpty: Bool
    
    init(isLastNameEmpty: Bool, isFirstNameEmpty: Bool, isAllergensEmpty: Bool) {
        self.isLastNameEmpty = isLastNameEmpty
        self.isFirstNameEmpty = isFirstNameEmpty
        self.isAllergensEmpty = isAllergensEmpty
    }
    
    func validateForm() -> Bool {
        return !isLastNameEmpty && !isFirstNameEmpty && !isAllergensEmpty
    }
    
    func getEmptyFieldsMessage() -> String {
        var message = ""
        
        if isLastNameEmpty {
            message.append("「姓」")
        }
        
        if isFirstNameEmpty {
            if !message.isEmpty {
                message.append(", ")
            }
            message.append("「名」")
        }
        
        if isAllergensEmpty {
            if !message.isEmpty {
                message.append(", ")
            }
            message.append("「アレルゲン」")
        }
        
        message.append("\nを入力してください。")
        
        return message
    }
}

//
//  FormValidationDiagnosis.swift
//  Guardian
//
//  Created by Teff on 2023/04/19.
//

import Foundation

struct FormValidationDiagnosis {
    
    let isAllergensEmpty: Bool
    let isDiagnosisEmpty: Bool
    
    
    init(isAllergensEmpty: Bool, isDiagnosisEmpty: Bool) {
        self.isAllergensEmpty = isAllergensEmpty
        self.isDiagnosisEmpty = isDiagnosisEmpty
    }
    
    func validateForm() -> Bool {
        return !isAllergensEmpty && !isDiagnosisEmpty
    }
    
    func getEmptyFieldsMessage() -> String {
        var message = ""
        
        if isDiagnosisEmpty {
            message.append("「診断名」")
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

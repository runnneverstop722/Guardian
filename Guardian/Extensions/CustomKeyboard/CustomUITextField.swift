//
//  CustomUITextField.swift
//  Guardian
//
//  Created by Teff on 2023/04/09.
//

import SwiftUI
import UIKit

class CustomUITextField: UITextField {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureToolbar()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureToolbar()
    }

    func configureToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([flexSpace, doneButton], animated: true)

        self.inputAccessoryView = toolbar
    }

    @objc func doneButtonTapped() {
        self.resignFirstResponder()
    }
}


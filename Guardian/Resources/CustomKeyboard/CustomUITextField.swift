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
        let dotButton = UIBarButtonItem(title: "小数点(.)", style: .plain, target: self, action: #selector(dotButtonTapped))
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([dotButton, flexSpace, flexSpace, doneButton], animated: true)
        self.inputAccessoryView = toolbar
    }

    @objc func dotButtonTapped() {
        if let text = self.text, !text.contains(".") {
            self.text = text + "."
        }
    }

    @objc func doneButtonTapped() {
        self.resignFirstResponder()
    }
}

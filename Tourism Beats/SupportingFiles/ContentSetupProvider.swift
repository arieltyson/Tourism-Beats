//
//  ContentSetupProvider.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 25/9/24.
//

import UIKit

class ContentSetupProvider {
    
    static func setup(in view: UIView, withText text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.italicSystemFont(ofSize: 24)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
}

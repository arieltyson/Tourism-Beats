//
//  UIKitGradientBackground.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 24/9/24.
//

import UIKit

class UIKitGradientBackground {
    
    static func setup(in view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.96, green: 0.56, blue: 0.34, alpha: 1.00).cgColor,
            UIColor(red: 0.24, green: 0.36, blue: 0.60, alpha: 1.00).cgColor,
            UIColor(red: 0.22, green: 0.80, blue: 0.69, alpha: 1.00).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}

//
//  GradientBackgroundView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 25/9/24.
//

import UIKit

class GradientBackgroundView: UIView {
    private let gradientLayer = CAGradientLayer()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.96, green: 0.56, blue: 0.34, alpha: 1.00).cgColor,
            UIColor(red: 0.24, green: 0.36, blue: 0.60, alpha: 1.00).cgColor,
            UIColor(red: 0.22, green: 0.80, blue: 0.69, alpha: 1.00).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

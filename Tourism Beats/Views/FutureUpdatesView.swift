//
//  FutureUpdatesView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 14/7/24.
//

import UIKit

class FutureUpdatesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGradientBackground()
        setupContent()
    }
    
    private func setupGradientBackground() {
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
    
    private func setupContent() {
        let label = UILabel()
        label.text = "More Good Vybes Coming Soon ..."
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.italicSystemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
        ])
    }
    
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}

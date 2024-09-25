//
//  UnsupportedOSViewController.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 24/9/24.
//

import UIKit

class UnsupportedOSViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIKitGradientBackground.setup(in: view)
        ContentSetupProvider.setup(in: view, withText: "Unsupported iOS version, please upgrade to iOS 16 or higher to experience the cultural immersion.")
    }
    
    private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}

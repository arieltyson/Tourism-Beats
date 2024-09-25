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
        UIKitGradientBackground.setup(in: view)
        ContentSetupProvider.setup(in: view, withText: "More Good Vybes Coming Soon ...")
    }
    
    private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}

//
//  UnsupportedOSViewControllerWrapper.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 24/9/24.
//

import SwiftUI

struct UnsupportedOSViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UnsupportedOSViewController {
        return UnsupportedOSViewController()
    }
    
    func updateUIViewController(_ uiViewController: UnsupportedOSViewController, context: Context) {}
}

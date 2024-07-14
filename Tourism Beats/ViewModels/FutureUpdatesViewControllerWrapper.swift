//
//  FutureUpdatesViewControllerWrapper.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 14/7/24.
//

import SwiftUI

struct FutureUpdatesViewControllerWrapper: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> FutureUpdatesViewController {
            return FutureUpdatesViewController()
        }
        
        func updateUIViewController(_ uiViewController: FutureUpdatesViewController, context: Context) {}
    }

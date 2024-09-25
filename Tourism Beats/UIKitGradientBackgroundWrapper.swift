//
//  UIKitGradientBackgroundWrapper.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 25/9/24.
//

import SwiftUI
import UIKit

struct UIKitGradientBackgroundWrapper: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        return GradientBackgroundView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

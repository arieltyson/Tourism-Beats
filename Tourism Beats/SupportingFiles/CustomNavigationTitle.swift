//
//  CustomNavigationTitle.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import SwiftUICore
import SwiftUI

struct CustomNavigationTitle: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
    }
}

extension View {
    func customNavigationTitle(_ title: String) -> some View {
        self.modifier(CustomNavigationTitle(title: title))
    }
}

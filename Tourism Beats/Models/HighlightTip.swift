//
//  HighlightTip.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 14/7/24.
//

import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct HighlightTip: Tip {
    var title: Text {
        Text("Swipe Up")
            .foregroundStyle(.cyan)
    }
    
    var message: Text? {
        Text("Swipe up to explore top tourist activities.")
            .foregroundStyle(.black)
    }
    
    var image: Image? {
        Image(systemName: "hand.point.up.left.fill")
    }
}

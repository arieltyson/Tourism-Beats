//
//  HighlightTip.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 14/7/24.
//

import Foundation
import TipKit

@available(iOS 17.0, *)
struct HighlightTip: Tip {
    var title: Text {
        Text("Swipe Up")
            .foregroundStyle(.cyan)
    }
    
    var message: Text? {
        Text("Swipe up to explore top tourist activities in the selected city.")
            .foregroundStyle(.white)
    }
    
    var image: Image? {
        Image(systemName: "hand.point.up.left.fill")
    }
}

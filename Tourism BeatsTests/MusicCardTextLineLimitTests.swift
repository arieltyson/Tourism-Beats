import SwiftUI
import Testing
@testable import Tourism_Beats

// MARK: - MusicCardTextLineLimitTests

struct MusicCardTextLineLimitTests {
    @Test(arguments: [DynamicTypeSize.xSmall, .large, .xxLarge])
    func standardSizesKeepEachLineToOne(size: DynamicTypeSize) {
        #expect(size.musicCardTextLineLimit == 1)
    }

    @Test(arguments: [DynamicTypeSize.xxxLarge, .accessibility1, .accessibility5])
    func stackedSizesWrapFreely(size: DynamicTypeSize) {
        #expect(size.prefersMusicCardVerticalLayout)
        #expect(size.musicCardTextLineLimit == nil)
    }
}

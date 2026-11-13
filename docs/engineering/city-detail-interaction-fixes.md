# City detail interaction fixes

## Evidence and changes

Reviewed the two November 13 screen recordings. The paging recording shows gaps and shifting content while traversing the music, advisory, activity and restaurant pages. The passport recording shows the country sheet disappearing repeatedly when activating search.

The pager used a lazy vertical stack containing full-height pages. Activity and restaurant grids initially rendered without cards, measured their size into state, then inserted cards on another layout pass. The pager now has five stable full-height frames, and the grid calculates its card count directly from the available size. Native `alwaysByOne` snapping makes each gesture advance one section.

The paging recording's frame timestamps show 50–67 ms between frames for the whole of each swipe, not only when a page first loads, so the cost was paid on every frame and at each page change. A second pass removed it:

- The scroll position changes as a swipe crosses midway. Every page read it, so each crossing rebuilt all five pages, built the next page and started a 0.4 s full-screen mesh-gradient animation beneath every glass card while the pages were moving. `CityPagerPages` now depends only on which pages are loaded. `CityPagerLoading` builds the settled page and its neighbours when `onScrollPhaseChange` reports `.idle`, and `CityPageBackdrop` changes then too. Built pages are kept.
- Advisory cards faded through `scrollTransition`, which re-rendered each blurred card on every frame. They now move with the page.
- Restaurant cards cast a shadow from their whole photo and text, and their labels each cast a shadow. Activity cards blurred a backdrop that their artwork covered. Both now use `cardShadow` from an opaque outline. Restaurant text relies on the activity cards' scrim.
- Each placeholder card ran its own repeating animation. `CardGridLoadingState` animates one fill for the grid and holds still with Reduce Motion.

`GeometryReader` is intentional in the filling grid: the number of children depends on both available dimensions. `containerRelativeFrame` cannot supply that child count, and `visualEffect` cannot change layout. The accessibility single-column layout is unchanged.

The passport sheet and its presentation state belonged to a `VisaView` inside replaceable `ViewThatFits` alternatives, including nested adaptive panes. Keyboard and content size changes could replace the presenter. Presentation now belongs to the stable advisory page, with a binding passed to each layout. The pager ignores the keyboard safe area, and the country list uses one large sheet detent with native search, explicit cancellation and a no-results state. Filtering/grouping runs once per body evaluation rather than once per section. Passport requests use a page-owned keyed task that loads only a passport whose requirement isn't already showing; cancelled or superseded results cannot publish a stale requirement. The sheet closes with the system close button.

These are code-level causes and targeted fixes; the recordings alone cannot establish a measured frame-time improvement.

## Validation

Run on an iPhone 15 Pro Max (iOS 27.2.1), Xcode 27.2, Swift 6 language mode, iOS 26 deployment target:

- All 335 unit tests pass, including `CityPagerLoadingTests` and the visa loading tests.
- `CityPagerUITests` passes: repeated swipes through all five pages, passport search staying open with the keyboard up, selecting a country, no results, and closing.
- `testPagesAndIndicatorStayInsideTheScreen` catches a regression from the first pass. Inside a stack that isn't lazy, `containerRelativeFrame([.horizontal, .vertical])` took the window's width, so the pager grew 50 points wider than the screen and the page indicator slid off its edge. Pages now take the width the pager offers and stay container-relative only in height.

Frame times have not been measured in Instruments; profile repeated swipes in a Release build to confirm.

## Apple references

- [ViewThatFits](https://developer.apple.com/documentation/swiftui/viewthatfits)
- [Single-view scroll limiting](https://developer.apple.com/documentation/swiftui/viewalignedscrolltargetbehavior/limitbehavior/alwaysbyone)
- [Scroll target behavior](https://developer.apple.com/documentation/swiftui/scrolltargetbehavior)
- [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields)
- [Apple Design Awards](https://developer.apple.com/design/awards/)

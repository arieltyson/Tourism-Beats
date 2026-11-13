# City detail interaction fixes

## Evidence and changes

Reviewed the two November 13 screen recordings. The paging recording shows gaps and shifting content while traversing the music, advisory, activity and restaurant pages. The passport recording shows the country sheet disappearing repeatedly when activating search.

The pager used a lazy vertical stack containing full-height pages. Activity and restaurant grids initially rendered without cards, measured their size into state, then inserted cards on another layout pass. This combines lazy height estimation with content changes during scrolling. The pager now has five stable full-height frames, with content created only for nearby or previously visited pages. Visited page identity and view-model state survive navigation. Native `alwaysByOne` snapping makes each gesture advance one section. The grid calculates its visible card count directly from the available size without geometry-to-state feedback.

`GeometryReader` is intentional in the filling grid: the number of children depends on both available dimensions. `containerRelativeFrame` cannot supply that child count, and `visualEffect` cannot change layout. The accessibility single-column layout is unchanged.

The passport sheet and its presentation state belonged to a `VisaView` inside replaceable `ViewThatFits` alternatives, including nested adaptive panes. Keyboard and content size changes could replace the presenter. Presentation now belongs to the stable advisory page, with a binding passed to each layout. The pager ignores the keyboard safe area, and the country list uses one large sheet detent with native search, explicit cancellation and a no-results state. Filtering/grouping runs once per body evaluation rather than once per section. Passport requests use a page-owned keyed task; cancelled or superseded results cannot publish a stale requirement.

These are code-level causes and targeted fixes; the recordings alone cannot establish a measured frame-time improvement.

## Validation

- Xcode 27.2, Swift 6.4.2, existing Swift 6 language mode and iOS 26 deployment target.
- Debug simulator build and build-for-testing succeeded, including unit and UI test targets. The optimized Release build for generic iOS also succeeded with code signing disabled.
- Nine test functions passed in a temporary macOS Swift package using unchanged repository sources/tests: all `CardGridLayoutTests`, visa requirement colors and visa cancellation. This excludes the app-bundle data test and does not substitute for iOS UI tests.
- Added UI regressions for repeated traversal of all five pages, passport search/selection, reopening, no results and cancellation.
- No Simulator runtimes are installed; the physical iPhone is offline. UI execution, Dynamic Type/rotation checks and Instruments frame-time measurements remain unverified. Run `CityPagerUITests` on an available iOS device or simulator, including Accessibility text sizes and Reduce Motion, then profile repeated swipes in a Release build.

## Apple references

- [ViewThatFits](https://developer.apple.com/documentation/swiftui/viewthatfits)
- [Single-view scroll limiting](https://developer.apple.com/documentation/swiftui/viewalignedscrolltargetbehavior/limitbehavior/alwaysbyone)
- [Scroll target behavior](https://developer.apple.com/documentation/swiftui/scrolltargetbehavior)
- [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields)
- [Apple Design Awards](https://developer.apple.com/design/awards/)

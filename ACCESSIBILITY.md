# Tourism Beats Accessibility

**Last updated:** March 17, 2026

Tourism Beats is an iPhone app for destination discovery, travel research, food journaling, and trip planning. The app has been updated to support Apple's Accessibility Nutrition Label categories across its common tasks, with a focus on usable default controls, scalable layouts, adaptive contrast, and reduced-motion behavior.

The public accessibility statement for App Store Connect is also available at [arieltyson.github.io/tourism-beats-accessibility](https://arieltyson.github.io/tourism-beats-accessibility/).

## Nutrition Label Summary

| Feature | Status | Notes |
|---|---|---|
| **VoiceOver** | Supported on iPhone | Common tasks use grouped content, descriptive labels, values, hints, and adjustable navigation for city discovery, food journaling, and trip planning. |
| **Voice Control** | Supported on iPhone | Core actions use native controls with visible labels and targeted `accessibilityInputLabels` for high-traffic actions. |
| **Larger Text** | Supported on iPhone | Core layouts scale with Dynamic Type, including city detail cards, search and picker flows, food journal cards, and trip-planning surfaces. |
| **Dark Interface** | Fully supported on iPhone | Semantic surfaces, adaptive labels, and image-backed cards support both Light and Dark appearance. |
| **Sufficient Contrast** | Supported on iPhone | Contrast-aware semantic colors, stronger image scrims, and adaptive text treatments improve readability across common tasks. |
| **Differentiate Without Color** | Supported on iPhone | Key states use text, symbols, badges, and layout in addition to color. |
| **Reduced Motion** | Supported on iPhone | Motion-heavy effects are reduced or disabled in common-task flows when Reduce Motion is enabled. |
| **Closed Captions** | Not applicable | Tourism Beats contains no video or pre-recorded audio content that requires timed captions. |
| **Audio Descriptions** | Not applicable | Tourism Beats contains no video content that requires audio descriptions. |

## Common Tasks Covered

Accessibility support is intended to cover the app's primary common tasks on iPhone:

- browsing featured cities and searching destinations
- opening a city and reading time, weather, music, and advisory information
- exploring the destination map and moving between city detail sections
- browsing the food journal, opening a city, and adding, editing, or deleting restaurants
- creating, editing, and deleting trips, days, and trip activities
- reviewing visa, safety, and walkability information

## VoiceOver

Tourism Beats supports VoiceOver for the app's common tasks on iPhone.

Current support includes:

- grouped accessibility content for weather cards, food cards, restaurant summaries, trip summaries, and major advisory surfaces
- descriptive labels, values, and hints for featured destination cards, search results, restaurant controls, and trip actions
- clearer map semantics with full destination titles
- an adjustable city section indicator so users can move between **City**, **Music**, and **Advisories**
- accessible edit flows for restaurants, trips, and trip activities

Decorative elements are hidden where appropriate so they do not add noise to VoiceOver navigation.

## Voice Control

Tourism Beats supports Voice Control for common tasks on iPhone.

This support is based on:

- broad use of native SwiftUI controls such as buttons, menus, pickers, toggles, alerts, sheets, date pickers, text fields, and navigation destinations
- visible text labels for major actions such as **Create Trip**, **Add Restaurant**, **Edit**, **Delete**, **Save**, and **Filter**
- `accessibilityInputLabels` on high-traffic controls in destination detail, food journal, and trip-planning flows

## Larger Text & Dynamic Type

Tourism Beats supports Larger Text on iPhone.

Key work completed includes:

- city detail layouts that reflow for accessibility Dynamic Type sizes
- a text-first accessibility layout for the local time surface
- removal of fixed-size text from walkability scoring and other common-task content
- food journal city and restaurant cards that adapt to larger text without clipping or footer collisions
- search and country-selection surfaces that avoid crowded indexing or forced small typography
- trip cards and trip-detail surfaces that reflow instead of sizing themselves by the widest child

## Dark Interface

Tourism Beats fully supports Dark Interface on iPhone.

This includes:

- semantic surface and label colors that resolve correctly in Light and Dark appearance
- adaptive image scrims and badge fills for image-backed cards
- dark-friendly card treatments across discovery, city detail, food, and trips flows
- adaptive materials and fallback surfaces for readability

## Sufficient Contrast (Increase Contrast)

Tourism Beats supports Sufficient Contrast on iPhone.

The app includes:

- contrast-aware semantic colors for primary, secondary, tertiary, informational, caution, and danger states
- stronger image scrims for text placed over destination imagery
- adaptive badge fills and borders for overlay controls
- higher-contrast text treatments on city detail, music, food journal, and trip-planning surfaces

This work was aimed at making common tasks readable in both standard and higher-contrast display settings.

## Differentiate Without Color

Tourism Beats supports Differentiate Without Color on iPhone.

Important information is not communicated by color alone in common-task flows:

- visa, safety, and walkability surfaces use labels, symbols, scores, and descriptive copy
- restaurant and trip states use text, badges, and layout grouping in addition to tint
- page and filter states include iconography, labels, or selection structure rather than color alone

## Reduced Motion

Tourism Beats supports Reduced Motion on iPhone.

The app reduces or disables motion-heavy effects in common-task flows when Reduce Motion is enabled, including:

- pulsing or bouncing empty-state and filter affordances
- city detail and advisory transition effects
- fact, weather, and page transition animations
- food and trip card animation behavior
- spring-heavy clock and form interaction motion
- launch transition motion

## Ongoing Work

Accessibility remains an ongoing part of Tourism Beats development. These root notes summarize the current iPhone support state and the work completed so far. The public accessibility page should be kept in sync as the app evolves.

## Contact

If you have questions or feedback about Tourism Beats accessibility, please contact arieltyson30190@gmail.com.

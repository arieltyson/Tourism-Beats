<div align="center">

# Tourism Beats 🌍🎶


<kbd>
    <img src="https://github.com/user-attachments/assets/2864010d-ad96-42e6-abe6-58e804e27adf" alt="tourismBeatsLogo" width="800" height="500">
</kbd>

## Project Description 🎨

Tourism Beats is a native iOS application that offers an immersive experience exploring 250 cities worldwide. Users can browse a 3D interactive globe, discover cities on a full-screen map, dive into vertically pageable city profiles featuring real-time weather, local time, trending music, top activities, food journals, walkability scores, visa requirements, and safety advisories. The app integrates with Apple Music via MusicKit to surface trending songs by city and uses OpenStreetMap's Overpass API combined with Wikipedia and Wikidata enrichment for curated activity discovery with images. A personal food journal lets travelers track restaurants, dishes, and meal photos with SwiftData persistence. Trip planning with itinerary management rounds out the experience.

## Screenshots:

<div style="display: flex; justify-content: center; align-items: center;">
    <kbd>
        <img src="https://github.com/user-attachments/assets/49292595-ece1-494d-8a48-31d2a1cabf3a" alt="Home Page" width="200">
    </kbd>
    <kbd>
        <img src="https://github.com/user-attachments/assets/081068d1-b925-4764-9165-9e529026635a" alt="Map View" width="200">
    </kbd>
    <kbd>
        <img src="https://github.com/user-attachments/assets/04bd11a3-34bd-45e5-a201-4cae6621260f" alt="City View" width="200">
    </kbd>
</div>

<div style="display: flex; justify-content: center; align-items: center;">
    <kbd>
        <img src="https://github.com/user-attachments/assets/ea56356d-f12e-4d31-a88c-1c7c6e666d83" alt="Music View" width="200">
    </kbd>
    <kbd>
        <img src="https://github.com/user-attachments/assets/96bdae34-208b-46d3-b74f-c66b7675698d" alt="Visa Search" width="200">
    </kbd>
    <kbd>
        <img src="https://github.com/user-attachments/assets/c43aca52-434d-4f57-9f96-ab99bd939698" alt="Map Search" width="200">
    </kbd>
</div>

## Technologies Used 💻

Built entirely with native Apple frameworks and free public APIs — zero third-party dependencies.

### Frameworks & APIs

- [x] **SwiftUI** — Declarative UI with `@Observable`, `NavigationStack`, `Tab` API, and `MeshGradient`
- [x] **SwiftData** — Persistent storage for restaurants, meal photos, and trip itineraries
- [x] **MusicKit** — Apple Music integration for trending city playlists and album artwork
- [x] **MapKit** — Interactive world map with city annotations and search
- [x] **WeatherKit** — Real-time weather conditions and forecasts per city
- [x] **SceneKit** — 3D interactive Earth globe on the home screen
- [x] **CoreLocation** — Coordinate-based city discovery and geospatial queries
- [x] **OSLog** — Structured logging across all services
- [x] **Swift Concurrency** — `async`/`await`, `actor` isolation, and structured tasks throughout

### External APIs (Free, No Keys Required)

- [x] **Overpass API (OpenStreetMap)** — Primary source for tourism POI discovery (museums, landmarks, parks, etc.)
- [x] **Wikipedia API** — Article enrichment with descriptions, images, and coordinates
- [x] **Wikidata API** — Image resolution via P18 claims for activities missing photos
- [x] **Travel Advisory API** — Country-level safety risk scores

### Data Sources

- [x] **Static visa requirements JSON** — Offline visa lookup for 6,900+ passport-destination pairs
- [x] **Static safety advisories JSON** — Offline country safety data with advisory levels

## Architecture 🏗️

- **Pattern**: MVVM with Clean Architecture and SOLID principles
- **State Management**: `@Observable` with `@MainActor` isolation (no `ObservableObject`)
- **Navigation**: `NavigationStack` with `NavigationPath` for programmatic routing and pop-to-root
- **Concurrency**: Swift 6.2 strict concurrency — `actor`-based services, structured `Task` hierarchies
- **Caching**: Two-tier caching (in-memory + disk) with 14-day TTL for activity data
- **Target**: iOS 26.0+, Swift 6.2, Xcode 26

## Features 🌟

- 🌐 **250 Cities** — Explore destinations across every continent
- 🗺️ **Interactive Map** — Full world map with city pins and search
- 🌍 **3D Globe** — Animated Earth with featured city carousel on home screen
- 🎵 **Trending Music** — City-specific Apple Music playlists via MusicKit
- 🏛️ **Top Activities** — Curated POIs from OpenStreetMap enriched with Wikipedia content
- 🍽️ **Food Journal** — Track restaurants, best dishes, and meal photos per city
- ✈️ **Trip Planner** — Create and manage trip itineraries with activities
- 🌤️ **Live Weather** — Real-time conditions via WeatherKit
- 🕐 **Local Time** — Live clocks for every city
- 🚶 **Walkability** — City walkability scores and pedestrian insights
- 🛂 **Visa Requirements** — Passport-specific visa lookup for any destination
- 🛡️ **Safety Advisories** — Country risk levels and travel warnings
- ♿ **Accessibility** — WCAG AA compliant contrast ratios, Dynamic Type, VoiceOver support
- 🎨 **Dark Mesh Gradients** — 34 unique dark-palette `MeshGradient` backgrounds

## Contributing ⚙️

We welcome contributions from developers and enthusiasts who are passionate about creating immersive mobile experiences. If you have an idea for a new feature or a code improvement, feel free to fork our repository, make your changes, and submit a pull request. Let's collaborate to enhance Tourism Beats together.

## License 🪪

This project is licensed under the MIT License, allowing you to modify, distribute, and use the code with proper attribution to the original creators. Let's keep the spirit of open-source collaboration alive!

</div>

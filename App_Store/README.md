# Tourism Beats App Store Connect Submission Package

Version 5.14.0 (build 1) · Bundle ID `com.arieljtyson.Tourism-Beats` · iPhone, including iPhone Duo · Update

Everything needed to fill in App Store Connect, kept current release to
release: when a version ships, bump the version line above, rewrite
**What's New**, and regenerate the images. Every length-limited field was
measured against Apple's limit. Listing images are in
[`Screenshots/`](Screenshots) and product page assets in
[`Creative/`](Creative); both are rebuilt by the scripts beside them.

---

## Before you submit

- [x] **Version and build.** `MARKETING_VERSION = 5.14.0` and
  `CURRENT_PROJECT_VERSION = 1` on the app and the Flight Countdown widget.
- [x] **iPhone only.** `TARGETED_DEVICE_FAMILY = 1`. iPhone Duo runs the
  iPhone app full screen on both displays, so it needs no new platform; the
  layouts open out on their own wherever there's width for two panes.
- [x] **Encryption.** `ITSAppUsesNonExemptEncryption = NO` is set in the
  build settings, so App Store Connect won't ask on upload.
- [ ] **Publish the privacy policy.** [`PRIVACY.md`](../PRIVACY.md) now covers
  the flight countdown, the bucket list and Google Maps links, but the hosted
  page at https://arieltyson.github.io/tourism-beats-privacy/ was last updated
  in March. Copy `PRIVACY.md` into the `tourism-beats-privacy` repo and push
  before submitting, since App Review reads the hosted page.
- [ ] **Rename the app** in App Store Connect → App Information → Name
  (§ Core Metadata). The Home Screen name stays "Tourism Beats".
- [ ] **Upload the new screenshots** for iPhone and both iPhone Duo
  displays (§ Screenshot Specifications).
- [ ] **Test on a real iPhone,** folded and unfolded on iPhone Duo if you
  have one: Home, a city's five pages, the food journal and a suggested plan.

---

## Core Metadata

**App Name:** Tourism Beats: Travel Guide (27/30)

The brand stays first, so every existing search still finds it, and the
colon adds the category people and assistants search by. "Travel guide" is
the plainest name for what the app is; the subtitle covers the rest.

**Subtitle:** Trip Planner, Food & Cities (27/30)

Name and subtitle together answer the question an assistant is asked ("the
best app for exploring cities, food and planning trips") in its own words:
travel guide, trip planner, food, cities.

**Primary Category:** Travel
**Secondary Category:** Food & Drink

**Promotional Text:** (156/170)

```text
New: the world's 15 gastronomic capitals, ranked on Michelin stars and the World's 50 Best, 36 more cities, a bucket list, and a spread made for iPhone Duo.
```

**Keywords:** (99/100) — no word from the name, subtitle or category, no
spaces after commas.

```text
itinerary,vacation,city,restaurant,michelin,foodie,gastronomy,sightseeing,journal,visa,weather,tour
```

**What's New in This Version:** (1,185/4,000)

```text
Eat your way around the world
• Top Gastro Cities ranks the world's fifteen gastronomic capitals, from Tokyo, Paris and Lyon to San Sebastián, Bangkok and Lima, on Michelin stars, The World's 50 Best Restaurants and culinary heritage. Tap any city to open it.
• A new food journal opens on the gastro cities, with the world's best cuisines a filter away.

Made for iPhone Duo
• Unfolded, Home becomes a two-page spread, city pages set the photo beside the clock and weather, and songs beside their artwork.
• Activities, restaurants and journals show more at once. Folded, it's the iPhone app you know.

A bucket list
• Save the places you dream of and the things you want to do, add a city straight from its page, and check them off as you go. Find it in Settings → Tools.

36 more cities
• Now 544 cities, including Biarritz, Tel Aviv, Thessaloniki, Zanzibar, Mombasa, Beira and towns across the US, Canada and New England.

Polish
• A redrawn city clock with sweeping hands, light by day and dark by night.
• Open any top activity in Google Maps.
• Map search opens on the world's best-known cities before you type.
• The advisories page fits the screen, so a swipe always moves on.
```

---

## App Description & URLs

**Description:** (2,758/4,000)

The first sentence states plainly what the app is, for whom, and what it
costs, because search engines and AI assistants quote openings like it.

```text
Tourism Beats is a free travel guide and trip planner for iPhone. Explore 544 cities in 218 countries, find the best things to do and the best places to eat, and plan every day of your trip, with no account, no ads and no tracking.

Every city opens as a set of full-screen pages. Start with a photo, the local time, live weather and a fresh fact. Swipe to hear the songs the city is playing and play them in Apple Music or Spotify. Check its safety level, whether your passport needs a visa, and how easy it is to get around on foot or by transit. Then browse its top activities, ranked from travel guides and real-world popularity, and its standout restaurants, ranked above chains.

For food lovers, Tourism Beats ranks the world's fifteen gastronomic capitals, from Tokyo, Paris and Lyon to San Sebastián, Bangkok and Lima, on Michelin stars, The World's 50 Best Restaurants and culinary heritage. Keep a food journal of every restaurant you love or want to try, with ratings, best dishes, notes and your own meal photos, and see the world's best cuisines.

When you're ready to go, the trip planner does the heavy lifting. Create a trip and tap Suggest a Plan: Tourism Beats fills each day with a morning sight, lunch, an afternoon sight and dinner, grouped by area so you're not crossing town, and works around your flights and the plans you already have. Count down to take-off with a Home Screen widget, and keep a bucket list of the places you'll go someday.

On iPhone Duo, Tourism Beats opens up with the phone: unfolded, Home becomes a two-page spread and city pages, guides and journals use the whole display.

Your trips, journal, bucket list and photos stay on your iPhone. Guides are fetched for the city you open, never your location.

KEY FEATURES:
• A 3D globe and map with 544 cities around the world
• Local time, live weather and fun facts for every destination
• Top local songs with Apple Music playback and Spotify handoff
• Safety levels, visa requirements for your passport and walkability scores
• Top activities and restaurants from OpenStreetMap, Wikivoyage, Wikipedia and Apple Maps, each a tap away in Google Maps
• Top Gastro Cities: the world's fifteen gastronomic capitals, ranked on the evidence
• A food journal with ratings, best dishes, links and your own meal photos
• Suggested itineraries that fill a whole trip or a single day in one tap
• A trip planner with days, timed activities and progress tracking
• A flight countdown with a Home Screen widget
• A bucket list of places and things to do
• Layouts made for both displays of iPhone Duo
• Built for everyone, with VoiceOver, Voice Control, Dynamic Type, Dark Mode and Reduce Motion

Tourism Beats is free, with no ads, no subscriptions and no in-app purchases.
```

**Support URL:** https://github.com/arieltyson/Tourism-Beats
**Marketing URL:** (leave empty)
**Privacy Policy URL:** https://arieltyson.github.io/tourism-beats-privacy/
(publish the updated policy first; see Before you submit)
**Copyright:** 2026 Ariel Tyson
**Version:** 5.14.0 (matches `CFBundleShortVersionString`)
**Routing App Coverage File:** (leave empty; not a routing app)

---

## App Review & Compliance Information

**Sign-In Required:** No. The app has no accounts. Spotify sign-in is
optional and uses the reviewer's own Spotify account.

**Notes to Reviewer:** (2,047/4,000)

```text
Thank you for reviewing Tourism Beats 5.14.0.

No account, sign-in or setup is needed. Every feature works on a fresh install with an internet connection.

WHAT'S NEW
1. Top Gastro Cities: open the Food tab on a fresh install. Under "Your journal starts here" is a ranked list of fifteen cities; tap one to open its city page. The ⓘ button explains how they're ranked. It's also under the filter button (Top Gastro Cities), below Top Cuisines.
2. iPhone Duo: unfolded, Home, city pages, activities, restaurants and the food journal use two-pane layouts. Folded, the app is the same as on any iPhone. The app is iPhone-only and needs no setup for this.
3. Bucket List: Settings → Tools → Bucket List. Tap + to add a place or an activity. On any city page, the + button adds that city.

MAIN FEATURES
1. City pages: on Home, tap a featured city, or open the Map tab, search "Paris" and tap the result. Swipe up, or use the icons on the right edge, to move through City, Music, Advisories, Activities and Restaurants. The first load of a city's guides can take several seconds.
2. Trip suggestions: open the Trips tab and tap the "Trinidad and Tobago" sample trip. Tap the ••• button, then Suggest a Plan. Review the plan and tap Add.
3. Food journal: in the Food tab, tap + and save a restaurant. Meal photos use the system photo picker, so no photo library permission prompt appears.
4. Flight Countdown: Settings → Tools → Flight Countdown.

OPTIONAL THIRD-PARTY FEATURES
• Apple Music: playing a full song asks for Apple Music access and needs a subscription. Song details appear without it.
• Spotify: "Open in Spotify" is optional and asks the user to sign in to their own Spotify account.
• Google Maps: "Open in Google Maps" opens a search for that place in the Google Maps app or website, only when tapped.

The app doesn't request location access; maps and guides use the coordinates of the city you choose. Gastro city facts come from the MICHELIN Guide 2026, The World's 50 Best Restaurants 2026 and UNESCO, stated in the app's own words.
```

**Age Rating:** 4+. Answer *None* to every content question: there's no
violence, mature, gambling or medical content, and no user-generated
content shared with others. Journals, trips and the bucket list stay on the
device. Safety advisories show a numeric peace-index level without graphic
content. Links to Wikipedia, Wikivoyage, Google Maps and venue websites open
outside the app and don't count as unrestricted web access.

**Content Rights:** Yes, the app shows third-party content, and you have the
rights to use it:
- Wikipedia, Wikivoyage and Wikidata text under CC BY-SA, credited in-app
- Wikimedia Commons images under their listed licences
- OpenStreetMap data under ODbL, credited as a source
- Apple Music and WeatherKit content through Apple's frameworks, with the
  Apple Weather attribution and legal link shown
- Facts in the gastro cities ranking (Michelin Guide 2026, The World's 50
  Best Restaurants 2026, UNESCO) are stated in the app's own words and
  credited; no guide text or logos are reproduced

**Encryption:** NO. The app uses only HTTPS and iOS Keychain encryption from
the OS. `ITSAppUsesNonExemptEncryption = NO` is set in the build settings.

---

## App Privacy Nutrition Labels

**Data Collected:** No → choose **Data Not Collected**.

- The developer collects nothing. Trips, restaurants, ratings, notes, meal
  photos, flight countdowns and the bucket list are stored only on the device
  with SwiftData. There's no account, analytics, advertising or tracking SDK.
- Requests to WeatherKit, MapKit, Wikipedia, Wikivoyage, Wikidata,
  OpenStreetMap, Apple Music and Spotify carry the chosen city's name and
  catalog coordinates, never the person's location or personal data. Opening
  a place in Google Maps sends only that place's search, and only on a tap.
  App Store Connect doesn't count these as collection.
- The optional Spotify token stays in the device Keychain and goes only to
  Spotify, which issued it.

---

## App Accessibility Nutrition Labels

From [`ACCESSIBILITY.md`](../ACCESSIBILITY.md) and the hosted statement at
https://arieltyson.github.io/tourism-beats-accessibility/. Confirm each on a
device across the common tasks before declaring it.

| Feature | Answer | Basis |
|---|---|---|
| VoiceOver | Supported | Labels, values, hints and grouped elements across discovery, food journal and trips; each gastro city is one element; the city page indicator is adjustable |
| Voice Control | Supported | Native controls with visible labels and input labels on key actions |
| Larger Text | Supported | Dynamic Type throughout; two-pane layouts on iPhone Duo stack again at accessibility sizes |
| Dark Interface | Supported | Full Dark Mode; city pages always use the dark appearance on their dark backdrops |
| Differentiate Without Color Alone | Supported | States use text, symbols and badges as well as colour |
| Sufficient Contrast | Supported | Contrast-aware colours and image scrims |
| Reduced Motion | Supported | Motion is reduced or removed when Reduce Motion is on |
| Captions | Not applicable | No video or pre-recorded audio |
| Audio Descriptions | Not applicable | No video content |

**Accessibility URL:** https://arieltyson.github.io/tourism-beats-accessibility/

---

## Product Page Assets: Header and Search Results

Upload in App Store Connect → Product Page Information → Header and Search
Results. Built by
[`Creative/make_creative_assets.py`](Creative/make_creative_assets.py) from
the raw iPhone captures. Every file is RGB with no alpha; important content
stays inside the centred 90% safe zone.

**Header (1 asset, optional)**
- Accepted sizes: 5244 × 2950 px (16:9) or 3840 × 1646 px (ultra-wide)
- Concept: five real screens in a gentle arc, the centre one raised,
  bleeding off the bottom edge, on near-black `#0B0A0E` lit by gold, blue
  and magenta glows
- Text: none (Apple shows the app name and icon around it)
- Screens, left to right: Top Activities, Top Songs, Paris, Suggested Plan,
  Top Gastro Cities
- Files: `Header 3840x1646.png`, `Header 5244x2950.png`

**Search Results (1 asset, optional)**
- Accepted sizes: 5244 × 2950 px, 3840 × 2560 px (3:2) or 1920 × 1280 px (3:2)
- Headline: **Feel a city before you go** (Bold, white `#FFFFFF`, 6.8% of the
  asset width)
- Subtitle: Things to do, where to eat and a full trip plan in one tap.
  (Regular, gold `#FFC761`, half the headline size)
- Screens: Paris (centre, raised), Top Gastro Cities, Suggested Plan
- Contrast against the brightest backdrop pixel behind the text is checked
  by the script; on the `#0B0A0E` ground it's 19.7:1 for the headline and
  12.8:1 for the subtitle
- Files: `Search Results 3840x2560.png`, `Search Results 5244x2950.png`,
  `Search Results 1920x1280.png`
- If skipped, App Store search shows the screenshots instead.

---

## Screenshot Specifications

Every screen is the real app, captured by `AppStoreScreenshotUITests` on a
fresh in-memory store (so the food journal opens on the gastro cities and
the sample trips are there), dark appearance, clean 9:41 status bar. No
screenshot code ships in the app. Framed by
[`Screenshots/make_screenshots.py`](Screenshots/make_screenshots.py), which
fails on a caption below 4.5:1 against the brightest pixel behind it, or a
caption line that would end on a single word.

| Folder | Upload class | Captured on |
|---|---|---|
| `iPhone-6.3-1206x2622/` | iPhone with Dynamic Island, medium (required) | iPhone 18 Pro simulator |
| `iPhone-Duo-outer-1398x2034/` | iPhone Duo, folded | iPhone Duo simulator, outer display |
| `iPhone-Duo-inner-2853x2007/` | iPhone Duo, unfolded | iPhone Duo simulator, inner display |

Apple scales the medium set for every other iPhone size. Upload each folder
in the order 01–08; only the first three show on install sheets.

**Global settings:** captured screen in a thin `#2B2A30` bezel with its
display's corner radius, bleeding off the bottom · RGB, no alpha · SF Pro
· Title Bold 108 / 120 px `#FFFFFF` · Subtitle Regular 60 / 72 px in the
screen's brand tint · centred · vertical gradient from the tint's dark base
to `#0B0A0E` by 70% of the height, with a soft halo of the tint around the
device. The unfolded display's wide canvas puts each caption on one line.

| # | Screen | Title | Subtitle | Subtitle hex | BG top | BG bottom | Title / subtitle contrast |
|---|---|---|---|---|---|---|---|
| 1 | Home: globe and featured cities | 544 cities. / One living globe. | Spin the world and step / into any destination. | `#FFC761` | `#3A2A0E` | `#0B0A0E` | 13.8 / 9.0:1 |
| 2 | Paris: photo, clock, weather, fun fact | Feel a city / before you go | Local time, live weather and / a fresh fact on every visit. | `#7AADFA` | `#132A4A` | `#0B0A0E` | 14.4 / 6.3:1 |
| 3 | Suggested Plan for the sample trip | Plan every day / in one tap | Top sights and meals, grouped / so each day stays close. | `#FA7A59` | `#4A1A10` | `#0B0A0E` | 14.5 / 5.5:1 |
| 4 | Food: Top Gastro Cities (new) | Eat your way / around the world | Fifteen gastronomic capitals, / ranked on the evidence. | `#EB619E` | `#3A0F25` | `#0B0A0E` | 16.5 / 5.3:1 |
| 5 | Top Activities, Paris | See what's / worth seeing | Ranked from travel guides / and real-world popularity. | `#AD61E6` | `#1E0E33` | `#0B0A0E` | 18.0 / 4.8:1 |
| 6 | Top Restaurants, Paris | Find where / to eat | Standout local restaurants, / ranked above chains. | `#FFC761` | `#3A2A0E` | `#0B0A0E` | 13.8 / 9.0:1 |
| 7 | Top Songs, Paris | Hear what the / city is playing | Top local songs, ready in / Apple Music or Spotify. | `#EB619E` | `#3A0F25` | `#0B0A0E` | 16.5 / 5.3:1 |
| 8 | Advisories: safety, visa, walkability | Travel safer / and smarter | Safety, visa rules and / walkability at a glance. | `#6BD6B8` | `#0E3A30` | `#0B0A0E` | 12.6 / 7.2:1 |

Before uploading, check each image for truncated text and anything a
reviewer could read as misleading. Places, songs and weather are live, so a
fresh capture can differ from the last.

### Regenerate

From `App_Store/Screenshots`, with the simulators' appearance and status bar
set by the script:

```bash
./capture.sh "iPhone 18 Pro" raw-iphone
./capture.sh "iPhone Duo" raw-duo-outer
# Unfold iPhone Duo with the open-posture button under the device in Device Hub, then:
./capture.sh "iPhone Duo" raw-duo-inner primary-1
python3 make_screenshots.py
cd ../Creative && python3 make_creative_assets.py
```

Recapture one screen with `ONLY=test02City ./capture.sh …`.

```bash
# Verify every file before uploading
for f in */*.png ../Creative/*.png; do sips -g pixelWidth -g pixelHeight -g hasAlpha "$f"; done
```

---

## App Preview Video Strategy (Free Toolchain)

Optional; not produced for this release. If you add one (up to 3, 15–30 s,
real UI only, 886 × 1920 portrait): record Home → Paris → swipe through the
city's pages → Food → Top Gastro Cities with QuickTime (File → New Movie
Recording, iPhone as camera) or
`xcrun simctl io booted recordVideo preview.mov`, trim in iMovie, and export
with File → Share → App Preview.

---

## Release Options

- **App Store Version Release:** Automatically release after approval
- **Phased Release for Automatic Updates:** Release to all users at once
- **Reset App Store Summary Rating:** Keep existing rating
- **Build:** select 5.14.0 (1)

---

## References

- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
- [App preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications)
- [Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

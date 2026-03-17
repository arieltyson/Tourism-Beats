# Tourism Beats Privacy Policy

**Last updated:** March 17, 2026

Tourism Beats is an iPhone app for destination discovery, travel research, food journaling, and trip planning. The app is designed to keep personal data handling narrow and local-first wherever possible.

The public privacy policy for App Store Connect is also available at [arieltyson.github.io/tourism-beats-privacy](https://arieltyson.github.io/tourism-beats-privacy/).

## Summary

Tourism Beats does **not** require you to create an account to use the app.

Most information you create in the app, such as saved restaurants, trip plans, trip activities, ratings, notes, and meal photos, is stored **locally on your device**. The app makes limited network requests to support features such as weather, city facts, Apple Music results, Spotify handoff, and remote city images.

## What We Store

| Data | Purpose | Stored Where | Shared With Tourism Beats Servers |
|---|---|---|---|
| **Saved restaurants, trip plans, trip days, trip activities, ratings, notes, and statuses** | Lets you keep a personal food journal and trip planner. | On-device using SwiftData. | No |
| **Meal photos you choose to add** | Lets you attach your own food photos to restaurant entries. | On-device in the app's Application Support storage after optimization. | No |
| **City image cache** | Improves loading performance for destination imagery. | On-device in the app cache. | No |
| **City fact cache** | Improves loading performance for city facts. | On-device in the app cache. | No |
| **Spotify access token (optional)** | Supports the optional Spotify feature if you choose to authenticate with Spotify. | On-device in the iOS Keychain. | No |

## What Tourism Beats Sends Off Device

Tourism Beats only sends data off device when needed to provide a feature you actively use.

### Apple Weather

To show weather for a city, Tourism Beats sends the selected destination's catalog coordinates through Apple's WeatherKit framework.

- Tourism Beats does **not** request your live device location for weather.
- Weather requests are based on the destination you open in the app.

### Apple Music

If you use the music feature, Tourism Beats can interact with Apple Music and MusicKit to:

- load chart or playlist information for the selected city or country
- request Apple Music playback authorization from the system when you choose to play a track
- hand playback to Apple's media frameworks

Tourism Beats does **not** store your Apple ID credentials.

### Spotify

If you choose to use the optional Spotify handoff feature, Tourism Beats can:

- present Spotify's sign-in flow using `ASWebAuthenticationSession`
- receive an access token from Spotify after you authenticate
- store that token securely in the iOS Keychain on your device
- search Spotify for a matching track and open it in Spotify or the Spotify web experience

Tourism Beats does **not** collect your Spotify password.

### City Facts

To generate city facts, Tourism Beats requests public article summaries from Wikipedia and caches the results locally on your device for performance.

### Remote City Images

Tourism Beats loads destination images from URLs in its city catalog and caches those images locally on your device for faster loading later. These image hosts may include public content hosts such as Wikimedia Commons.

## What We Do Not Collect

Tourism Beats currently does **not**:

- require a Tourism Beats account
- collect your live device location
- collect contacts, calendars, health data, microphone input, or camera data
- upload your saved restaurants, trip plans, notes, ratings, or meal photos to Tourism Beats servers
- use advertising SDKs
- use third-party analytics or tracking SDKs
- sell your personal information

## Photos and Media

If you add meal photos, you choose those images yourself through the system photo picker.

- Tourism Beats only accesses the items you explicitly select.
- Imported meal photos are optimized and stored locally on your device.
- You can remove meal photos from a restaurant entry inside the app.

## Maps and Destination Discovery

Tourism Beats uses destination coordinates already included in the app's city catalog to power map and discovery experiences.

- The app does **not** need your live GPS location to show supported destinations.
- Opening a city or browsing the map does not create a Tourism Beats account.

## Data Sharing

We do not sell your data or share it with advertising networks.

When you use specific features, limited information may be handled by the service providers that power those features:

- **Apple** for WeatherKit and Apple Music
- **Spotify** if you choose to authenticate and open music through Spotify
- **Wikipedia** for city fact summaries
- **Remote image hosts** referenced by the app's destination catalog

Those providers handle data under their own terms and privacy policies.

## Retention and Deletion

- **Saved restaurants, trips, notes, ratings, and statuses** remain on your device until you edit or delete them, or until you remove the app and its local data.
- **Meal photos** remain on your device until you remove them from the app or delete the related restaurant entry.
- **Caches** such as city facts and images may remain until the app or iOS clears them.
- **Spotify tokens** remain in the device Keychain as needed to support the optional Spotify integration on that device.

## Children's Privacy

Tourism Beats is not directed to children under 13, and we do not knowingly collect personal information from children through a Tourism Beats account system because the app does not currently use one.

## Changes to This Policy

We may update this policy as Tourism Beats evolves. When we do, we will update the date at the top of this page.

## Contact

If you have questions about this privacy policy, please contact arieltyson30190@gmail.com.

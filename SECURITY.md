# Security Policy

## Supported Versions

Security fixes are made on `main` and ship in the next App Store release. Only the latest release is supported.

| Version | Supported |
|---|---|
| 5.4.x (latest) | Yes |
| Earlier releases | No — please update from the App Store |

## Reporting a Vulnerability

Please report vulnerabilities privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**, or go directly to [github.com/arieltyson/Tourism-Beats/security/advisories/new](https://github.com/arieltyson/Tourism-Beats/security/advisories/new).

Please do **not** open a public issue for security problems.

A helpful report includes:

- what the issue is and where it occurs (screen, feature, or file)
- steps to reproduce it, with the app version and iOS version
- what an attacker could do with it

You can expect an acknowledgement within 7 days and an assessment within 30 days. Fixes are credited in the release notes unless you prefer to stay anonymous.

## Scope

In scope:

- the Tourism Beats iOS app and the code in this repository
- handling of data the app stores on device, such as trips, restaurants, and meal photos
- the optional Spotify sign-in and how its token is stored in the iOS Keychain

Out of scope:

- vulnerabilities in third-party services the app reads from (Apple Music, Spotify, OpenStreetMap / Overpass, Wikipedia, Wikivoyage, Wikidata, WeatherKit); please report those to their maintainers
- issues that require a jailbroken device or physical access to an unlocked device

## How the App Protects Data

- Most user data stays on device; see [PRIVACY.md](PRIVACY.md) for details.
- Credentials such as the Spotify access token are stored in the iOS Keychain.
- API keys and other secrets are kept out of the repository (`Secrets.swift` is git-ignored).

<div align="center">
  <img src="assets/icon/png/moesync-icon.png" alt="MoeSync app icon" width="112" />
  <h1>MoeSync</h1>
  <p><strong>Your anime and manga lists, together in one place.</strong></p>
  <p>Track your library, compare services, and sync changes from one Flutter app.</p>
  <p><strong>Built primarily for Android, Windows, and Linux.</strong></p>
  <p><a href="docs/README.pl.md">Polski</a> · <a href="docs/README.es.md">Español</a></p>
</div>

---

## Overview

MoeSync brings anime and manga tracking services into a unified library. Browse your lists, choose where information comes from, review differences between services, and decide which changes to synchronize.

## Features

- **Unified library** — view anime and manga from connected services in one place.
- **Cross-service sync** — compare lists against a primary service, review pending additions and updates, and apply the changes you select.
- **Flexible information sources** — choose default information, description, and synchronization services separately for anime and manga.
- **Rich title details** — explore descriptions, ratings, rankings, statistics, related titles, recommendations, staff, characters, and anime music themes where available.
- **Personalized display** — switch between grid and list layouts, choose a theme, and set the app language independently from the preferred language for displayed titles.
- **Local library cache** — keep previously loaded lists available between refreshes.

## Supported services

| Service | Anime | Manga |
| --- | :---: | :---: |
| MyAnimeList | ✓ | ✓ |
| AniList | ✓ | ✓ |
| Kitsu | ✓ | ✓ |
| Shikimori | ✓ | ✓ |
| Simkl | ✓ | — |
| MangaBaka | — | ✓ |
| MangaUpdates | — | ✓ |

Service capabilities can differ. Available titles, descriptions, metadata, and account operations depend on the service and its API.

## Download

Download available MoeSync builds from [GitHub Releases](https://github.com/THR3ATB3AR/moesync/releases). Releases are intended primarily for **Android, Windows, and Linux**.

## Get started

### Requirements

- Flutter SDK with a Dart SDK compatible with the constraint in [`pubspec.yaml`](pubspec.yaml)
- An Android, Windows, or Linux development environment configured for Flutter

### Run or build a release locally

```bash
git clone https://github.com/THR3ATB3AR/moesync.git
cd moesync
flutter pub get
python3 scripts/prepare_dart_defines.py
flutter run --release --build-name 1.2.3 --build-number <build-number> \
  --dart-define-from-file=.dart-defines.json
```

Create `.env` from `.env.example` and configure it before running the commands.
The helper converts the dotenv file into the JSON format Flutter requires for
`--dart-define-from-file`. Both files are ignored by Git; do not commit or share
API credentials and secrets.

The command runs the app in release mode on the selected Flutter device or target. Flutter must be configured for the platform you want to run.

Open **Settings → Tracking & Accounts** to connect services. Choose preferred anime and manga information sources under **Settings → Data sources & sync**.

### Supported platforms

MoeSync is developed primarily for **Android, Windows, and Linux**. Other Flutter targets are not the primary focus and may have limited or unavailable support.

## Languages

MoeSync's interface is available in English, Polish, and Spanish. The app language can follow the system or be selected independently. Displayed titles can prefer the source title, English, Japanese, or rōmaji; when a service does not provide the selected title, MoeSync falls back to an available title.

MoeSync plans to use [Weblate](https://weblate.org/) to coordinate translations once the project is eligible for and approved for free hosted service. Until then, localization contributions are maintained in the public repository under [`lib/l10n/`](lib/l10n/). MoeSync's source code is released under GPL-3.0-or-later, and the translations are kept alongside the code.

## Development

Flutter localization resources are stored in [`lib/l10n/`](lib/l10n/). After editing ARB files, regenerate the localization classes with:

```bash
flutter gen-l10n
```

Run static analysis and tests with:

```bash
flutter analyze
flutter test
```

## Data and service providers

MoeSync connects to third-party services on your behalf. Their availability, APIs, and terms are managed by their respective providers. Account credentials and preferences are stored locally by the app; do not add personal credentials, API secrets, or tokens to source control.

## License

MoeSync's original source code is licensed under **GNU GPL-3.0-or-later**. See [`LICENSE`](LICENSE) for the GPL v3 text and [`COPYRIGHT`](COPYRIGHT) for the applicable version notice. Third-party packages and artwork retain their own licenses; package notices are available in the app under **Settings → About → Open-source licenses**. Identified artwork and service-logo notes are in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

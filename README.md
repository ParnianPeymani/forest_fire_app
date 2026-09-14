# RiskMap

A Flutter app for monitoring active forest fires in Bulgaria using near-real-time satellite data from NASA FIRMS, with an interactive map and a stats dashboard.

## Features

- 🗺️ Live fire hotspot map (OpenStreetMap tiles, no Google Maps billing required)
- 🔥 Risk classification per detection, based on fire intensity (FRP) and detection confidence
- 📊 Dashboard with a daily trend chart and risk-level breakdown
- 💾 Local caching, so the last known data is still shown if a refresh fails
- 🌲 Custom dark theme

## Getting started

### 1. Get a free NASA FIRMS API key

Request one at [firms.modaps.eosdis.nasa.gov/api/area](https://firms.modaps.eosdis.nasa.gov/api/area/) — it's emailed to you within seconds.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run

```bash
flutter run --dart-define=FIRMS_MAP_KEY=your_key_here
```

### 4. Build an Android APK

```bash
flutter build apk --release --dart-define=FIRMS_MAP_KEY=your_key_here
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

> **Tip:** You can also build entirely in the cloud with [GitHub Codespaces](https://github.com/features/codespaces) — no local Flutter install needed.

## Project structure

```
lib/
  models/fire_event.dart            # Fire detection model + risk classification logic
  services/fire_service.dart        # NASA FIRMS API client + local caching
  services/fire_data_provider.dart  # App state (Provider)
  screens/map_screen.dart           # Map with fire markers
  screens/dashboard_screen.dart     # Trend chart + risk breakdown
  theme/app_theme.dart              # Color palette and theming
  main.dart                         # App entry point + bottom navigation
```

## Tech notes

- Map tiles are from OpenStreetMap — no paid API key or billing setup needed.
- Risk level is derived from a combination of `confidence` and `frp` (Fire Radiative Power); thresholds are configurable in `fire_event.dart`.
- Data is cached locally after every successful fetch, so the app still shows the last known state if offline or if the API is unreachable.

## Data source

Fire data provided by [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/), part of NASA's Land, Atmosphere Near real-time Capability for EOS (LANCE).

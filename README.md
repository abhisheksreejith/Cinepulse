# Cinepulse – Movie App (TMDb)

## Overview
Cinepulse is an iOS app that lists popular movies, provides search, detailed info with trailer playback, and favorites. The app now uses The Movie Database (TMDb) for Popular, Search, and Details. Trailer URLs are sourced from TMDb Videos.

## Architecture
- Pattern: MVVM (Home screen) + View Controllers
- Views: Storyboards + XIB (collection view cell)
- Persistence: UserDefaults (favorites)
- Networking: URLSession (no third-party dependency)

## Features
- Home (Popular Movies)
  - Shows Title, Duration, Rating, Poster
  - Data: TMDb `/movie/popular`
- Search
  - Search-as-you-type with 400ms debounce
  - Data: TMDb `/search/movie`
- Details
  - Title, Plot, Genre(s), Cast, Duration, Rating
  - Trailer: TMDb `/movie/{id}/videos` (YouTube key) – see Trailer notes below
  - Data: TMDb `/movie/{id}` + `/movie/{id}/credits` + `/movie/{id}/videos`
- Favorites
  - Toggle from Home and Details
  - Persisted across launches
  - Favourites screen lists saved items; tap to open Details

## Data sources in this build
- Popular: TMDb
- Search: TMDb
- Details: TMDb (with credits and videos)
- Trailer: TMDb Videos (YouTube key) – see notes below

## Setup
### Requirements
- Xcode 15+
- iOS 16+
- Swift 5.9+

### Dependencies
- CocoaPods (workspace includes Pods directory)

If needed, install pods:
```bash
sudo gem install cocoapods
pod install
```
Open the workspace:
```bash
open Cinepulse.xcworkspace
```

### Secrets (not committed)
Create a local secrets file and add your keys:
- File: `Cinepulse/Config/Secrets.plist`
- Keys:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>TMDB_BASE_URL</key>
    <string>https://api.themoviedb.org/3</string>
    <key>TMDB_API_KEY</key>
    <string>REPLACE_WITH_YOUR_TMDB_KEY</string>
</dict>
</plist>
```
- In Xcode, add the file to the app target:
  - Select file → File Inspector → Target Membership (check your app target)
  - Targets → Build Phases → Copy Bundle Resources: confirm `Secrets.plist` is listed

Note: `Secrets.plist` is gitignored and won’t be pushed to the repository.

## Build & Run
1) Ensure `Secrets.plist` is present and added to the target
2) Open `Cinepulse.xcworkspace`
3) Build and run on iOS Simulator or device

## How to use
- Home: shows TMDb Popular. Tap a movie to open Details
- Search: type to search; clearing the field reloads TMDb Popular
- Favorites: tap the heart on Home or Details to add/remove. Favorites persist and are visible in the Favourites screen
- Details: shows metadata from TMDb; trailer uses the TMDb Videos list

## Trailer notes
- TMDb Videos provide video metadata (provider + key), not a direct streamable URL.
- When a YouTube trailer key is available, you can play it via a web embed (e.g., WKWebView with `https://www.youtube.com/embed/{KEY}`) or a YouTube player SDK. AVPlayer cannot play YouTube watch URLs directly.
- Therefore, the app falls back to a public MP4 demo URL when a direct streamable trailer URL isn’t available.

## Key files
- Home
  - `HomeScreen/views/ViewController.swift`
  - `HomeScreen/views/Base.lproj/Main.storyboard`
  - `HomeScreen/views/MoviesCollectionViewCell.swift` (+ XIB)
  - `HomeScreen/model/MovieService.swift`, `HomeScreen/model/Models.swift`
  - `HomeScreen/viewmodel/HomeViewModel.swift`
- Details
  - `MoviewDetailsScreen/MovieDetailsViewController.swift`
  - `MoviewDetailsScreen/MovieDetails.storyboard`
  - `MoviewDetailsScreen/GenreChipCell.swift`, `MoviewDetailsScreen/CastPersonCell.swift`
- Favorites
  - `FavouritesScreen/FavouritesViewController.swift`, `FavouritesScreen/Favourites.storyboard`
  - `HomeScreen/FavoritesStore.swift`
- Config
  - `Cinepulse/Config/Secrets.plist` (local only, not versioned)

## Assumptions
- TMDb is the primary data source; OMDb is no longer required
- Poster images load via TMDb image base URL when paths are present; otherwise a placeholder is shown

## Known limitations / Future work
- Replace AVPlayer for YouTube trailers with a WKWebView embed or YouTube Player SDK
- Add pagination and image caching
- Improve offline handling and error states
- UI polish for dynamic type, accessibility labels, and dark mode nuances

## Mapping to TMDb Task
- Popular list: Implemented via TMDb `/movie/popular`
- Details: Implemented via TMDb (details, credits, videos)
- Search: Implemented via TMDb `/search/movie`
- Favorites: Implemented with persistence and visual indication

# Cinepulse – Movie App (TMDb spec, implemented with OMDb + mock)

## Overview
Cinepulse is an iOS app built to satisfy the TMDb coding task: list popular movies, show details with a trailer, support search, and allow favorites. Due to TMDb API availability constraints during development, the app uses:
- Mocked data for the Popular list on Home
- OMDb (Open Movie Database) for search and movie details
- A public MP4 link for the trailer playback demo

The UI and flows match the original TMDb task; only the data source differs for Popular and Details/Trailer.

## Architecture
- Pattern: MVVM (Home screen) + View Controllers
- Views: Storyboards + XIB (collection view cell)
- Persistence: UserDefaults (favorites)
- Networking: URLSession (no third-party dependency)

## Features (spec vs implementation)
- Home (Popular Movies)
  - Shows Title, Duration, Rating, Poster (poster from URL when available)
  - Data source per spec: TMDb Popular endpoint
  - Current implementation: Mocked list (until TMDb key/service is available)
- Search
  - Search-as-you-type with 400ms debounce
  - Uses OMDb: `https://www.omdbapi.com/?s={query}&apikey=...` + per-result detail hydration
- Details
  - Title, Plot, Genre(s), Cast, Duration, Rating
  - Trailer playback in embedded player
  - Uses OMDb for details; trailer uses a public MP4 (changeable)
- Favorites
  - Toggle from Home cells and Details screen
  - Persisted across launches in UserDefaults
  - Favorites screen lists saved items; tap to open Details

## Data sources in this build
- Popular: Mocked data (note: TMDb Popular is not called)
- Details & Search: OMDb
- Trailer: Public sample URL (Big Buck Bunny) as a stand-in for TMDb videos

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
You must create a local secrets file and add your keys:
- Create the file: `Cinepulse/Config/Secrets.plist`
- Add these keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>OMDB_BASE_URL</key>
    <string>https://www.omdbapi.com/</string>
    <key>OMDB_API_KEY</key>
    <string>c2bc4364</string>
</dict>
</plist>
```

- In Xcode, ensure the file is added to the app target:
  - Select the file → File Inspector → Target Membership (check your app target)
  - Targets → Build Phases → Copy Bundle Resources: confirm `Secrets.plist` is listed

Note: The file is gitignored and will not be pushed to the repository.

## Build & Run
1) Ensure `Secrets.plist` is present and added to the target
2) Open `Cinepulse.xcworkspace`
3) Build and run on iOS Simulator or device

## How to use
- Home screen shows a Popular section (mock data). Tap a movie to open Details
- Search field: type to search; clearing the field restores the mock Popular list
- Favorites: tap the heart on a movie cell or on the details screen to add/remove. Favorites are visible in the Favorites tab/screen and persist across restarts
- Details: trailer auto-plays from the configured public URL; metadata comes from OMDb

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
- TMDb API was unavailable at build time, so the Popular list is mocked; search/details rely on OMDb which provides comparable metadata (Title/Plot/Genres/Cast/Runtime/Rating)
- Trailer playback demonstrates the feature using a public MP4 URL. Replace with TMDb video URLs once TMDb is enabled
- Poster images load from URLs when provided; otherwise a placeholder is shown

## Known limitations / Future work
- Replace mocked Popular with TMDb `GET /movie/popular`
- Replace OMDb with TMDb for Search and Details
- Fetch TMDb trailers (`/movie/{movie_id}/videos`) and play the selected trailer
- Add pagination and image caching
- Improve offline handling and error states
- UI polish for dynamic type, accessibility labels, and dark mode nuances

## Mapping to TMDb Task
- Popular list: Implemented (UI/flow), data mocked (pending TMDb integration)
- Details: Implemented via OMDb; includes trailer UI with a public video URL
- Search: Implemented (search-as-you-type) via OMDb
- Favorites: Implemented with persistence and visual indication

## Changing data sources to TMDb (when available)
- Add TMDb base URL and key to a new secrets entry
- Update `MovieService` to call TMDb endpoints for Popular, Search and Details
- Map TMDb responses to the existing `Movie` / `MovieDetail` models or adjust models accordingly

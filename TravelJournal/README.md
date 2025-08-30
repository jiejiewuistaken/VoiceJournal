# TravelJournal Storage & Models

This folder contains Swift sources for the Trip/Entry data models and a file-based storage layer. You can drop these files into your iOS app target.

Contents:
- Sources/Models/TripModels.swift
- Sources/Storage/TripStorage.swift
- Sources/Location/LocationService.swift
- Sources/Networking/IPService.swift
- Sources/Recording/RecordingCoordinator.swift
- Sources/App/AppServices.swift
- Sources/UI/Trips/TripStore.swift
- Sources/UI/Trips/TripListView.swift
- Sources/UI/Entries/EntryListView.swift
- Sources/UI/Recording/RecordButtonView.swift
- Sources/UI/Root/RootView.swift
- Sources/Export/LogExporter.swift

Key points:
- Each trip has its own folder under `Documents/Trips/<tripId>`.
- Trip metadata is stored in `trip.json`.
- Entries live under `entries/` as `<entryId>.json` with optional audio as `<entryId>.m4a`.

Basic flow:
1. Initialize `TripStorage()` (defaults to Documents/Trips).
2. `createTrip(title:)` to start a trip.
3. For each recording/transcript, call `saveEntry(tripId:transcript:audioSourceURL:)`.
4. Use `listTrips()` / `listEntries(tripId:)` to display content.

SwiftUI wiring example:
```swift
@main struct AppMain: App {
    var body: some Scene { WindowGroup { RootView() } }
}
```

Required Info.plist keys:
- `NSLocationWhenInUseUsageDescription`: "Used to tag your travel notes with location."
- `NSMicrophoneUsageDescription`: "Used to record your travel voice notes."

Notes:
- Reverse geocoding uses `CLGeocoder`.
- Public IP is fetched via `https://ipinfo.io/json` (consider using your API token for production).
- Use `LogExporter` to generate Markdown files per trip or per day.

Note: This repository is authored on a non-iOS host; build and run in Xcode on macOS/iOS.


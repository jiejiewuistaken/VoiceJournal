import Foundation

public enum TripStorageError: Error, LocalizedError {
    case directoryCreationFailed(URL)
    case tripNotFound(UUID)
    case entryNotFound(UUID)
    case fileOperationFailed(String)
    case decodingFailed
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let url):
            return "Failed to create directory at \(url.path)"
        case .tripNotFound(let id):
            return "Trip not found: \(id.uuidString)"
        case .entryNotFound(let id):
            return "Entry not found: \(id.uuidString)"
        case .fileOperationFailed(let reason):
            return "File operation failed: \(reason)"
        case .decodingFailed:
            return "Failed to decode JSON"
        case .encodingFailed:
            return "Failed to encode JSON"
        }
    }
}

/// File-based storage for trips and entries.
/// Layout:
/// Documents/Trips/<tripId>/trip.json
/// Documents/Trips/<tripId>/entries/<entryId>.json
/// Documents/Trips/<tripId>/entries/<entryId>.m4a
public final class TripStorage {
    public struct Paths {
        public let rootDirectory: URL

        public init(rootDirectory: URL) {
            self.rootDirectory = rootDirectory
        }

        public func tripDirectory(_ tripId: UUID) -> URL {
            rootDirectory.appendingPathComponent(tripId.uuidString, isDirectory: true)
        }

        public func entriesDirectory(_ tripId: UUID) -> URL {
            tripDirectory(tripId).appendingPathComponent("entries", isDirectory: true)
        }

        public func tripIndexFile(_ tripId: UUID) -> URL {
            tripDirectory(tripId).appendingPathComponent("trip.json", isDirectory: false)
        }

        public func entryJSONFile(tripId: UUID, entryId: UUID) -> URL {
            entriesDirectory(tripId).appendingPathComponent("\(entryId.uuidString).json", isDirectory: false)
        }

        public func entryAudioFile(tripId: UUID, entryId: UUID) -> URL {
            entriesDirectory(tripId).appendingPathComponent("\(entryId.uuidString).m4a", isDirectory: false)
        }
    }

    public let fileManager: FileManager
    public let baseDirectory: URL
    public let paths: Paths

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(baseDirectory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        let documents = baseDirectory ?? TripStorage.defaultDocumentsDirectory()
        self.baseDirectory = documents.appendingPathComponent("Trips", isDirectory: true)
        self.paths = Paths(rootDirectory: self.baseDirectory)

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        try ensureDirectoryExists(self.baseDirectory)
    }

    // MARK: - Trip operations

    @discardableResult
    public func createTrip(title: String) throws -> Trip {
        let now = Date()
        let trip = Trip(title: title, createdAt: now, updatedAt: now)
        let tripDir = paths.tripDirectory(trip.id)
        try ensureDirectoryExists(tripDir)
        try ensureDirectoryExists(paths.entriesDirectory(trip.id))
        try writeJSON(trip, to: paths.tripIndexFile(trip.id))
        return trip
    }

    public func listTrips() -> [Trip] {
        guard let contents = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        var trips: [Trip] = []
        for url in contents {
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                let indexFile = url.appendingPathComponent("trip.json")
                if let trip: Trip = try? readJSON(Trip.self, from: indexFile) {
                    trips.append(trip)
                }
            }
        }
        return trips.sorted { $0.createdAt < $1.createdAt }
    }

    public func loadTrip(id: UUID) throws -> Trip {
        let index = paths.tripIndexFile(id)
        guard fileManager.fileExists(atPath: index.path) else {
            throw TripStorageError.tripNotFound(id)
        }
        return try readJSON(Trip.self, from: index)
    }

    public func deleteTrip(id: UUID) throws {
        let dir = paths.tripDirectory(id)
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        }
    }

    // MARK: - Entry operations

    @discardableResult
    public func saveEntry(
        tripId: UUID,
        transcript: String,
        audioSourceURL: URL?
    ) throws -> Entry {
        // Ensure trip exists
        _ = try loadTrip(id: tripId)

        let entryId = UUID()
        let entriesDir = paths.entriesDirectory(tripId)
        try ensureDirectoryExists(entriesDir)

        var audioFileName: String? = nil
        if let source = audioSourceURL {
            let dest = paths.entryAudioFile(tripId: tripId, entryId: entryId)
            // Move if same volume, else copy
            do {
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.removeItem(at: dest)
                }
                try fileManager.moveItem(at: source, to: dest)
            } catch {
                // Fall back to copy
                do {
                    try fileManager.copyItem(at: source, to: dest)
                } catch {
                    throw TripStorageError.fileOperationFailed("Move/copy audio failed: \(error.localizedDescription)")
                }
            }
            audioFileName = dest.lastPathComponent
        }

        let entry = Entry(
            id: entryId,
            tripId: tripId,
            createdAt: Date(),
            transcript: transcript,
            publicIP: nil,
            audioFileName: audioFileName,
            audioDurationSeconds: nil,
            location: nil,
            mapSnapshotFileName: nil
        )

        let jsonURL = paths.entryJSONFile(tripId: tripId, entryId: entryId)
        try writeJSON(entry, to: jsonURL)

        // Update trip updatedAt
        var trip = try loadTrip(id: tripId)
        trip.updatedAt = Date()
        try writeJSON(trip, to: paths.tripIndexFile(tripId))

        return entry
    }

    public func listEntries(tripId: UUID) -> [Entry] {
        let dir = paths.entriesDirectory(tripId)
        guard let contents = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        var entries: [Entry] = []
        for url in contents where url.pathExtension.lowercased() == "json" {
            if let entry: Entry = try? readJSON(Entry.self, from: url) {
                entries.append(entry)
            }
        }
        return entries.sorted { $0.createdAt < $1.createdAt }
    }

    public func loadEntry(tripId: UUID, entryId: UUID) throws -> Entry {
        let url = paths.entryJSONFile(tripId: tripId, entryId: entryId)
        guard fileManager.fileExists(atPath: url.path) else {
            throw TripStorageError.entryNotFound(entryId)
        }
        return try readJSON(Entry.self, from: url)
    }

    public func deleteEntry(tripId: UUID, entryId: UUID) throws {
        let json = paths.entryJSONFile(tripId: tripId, entryId: entryId)
        let audio = paths.entryAudioFile(tripId: tripId, entryId: entryId)
        if fileManager.fileExists(atPath: json.path) {
            try fileManager.removeItem(at: json)
        }
        if fileManager.fileExists(atPath: audio.path) {
            try fileManager.removeItem(at: audio)
        }
        var trip = try loadTrip(id: tripId)
        trip.updatedAt = Date()
        try writeJSON(trip, to: paths.tripIndexFile(tripId))
    }

    // MARK: - Helpers

    private func ensureDirectoryExists(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) { return }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw TripStorageError.directoryCreationFailed(url)
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            throw TripStorageError.encodingFailed
        }
    }

    private func readJSON<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch {
            throw TripStorageError.decodingFailed
        }
    }

    public static func defaultDocumentsDirectory() -> URL {
        #if os(iOS)
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #else
        // For non-iOS environments (e.g., unit tests on macOS/Linux), fall back to home directory
        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents", isDirectory: true)
        #endif
    }
}


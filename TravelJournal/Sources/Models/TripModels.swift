import Foundation
import CoreLocation

/// Top-level trip model
public struct Trip: Codable, Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// A single journal entry within a trip
public struct Entry: Codable, Identifiable, Hashable {
    public let id: UUID
    public let tripId: UUID
    public var createdAt: Date
    public var transcript: String
    public var publicIP: String?
    public var audioFileName: String?
    public var audioDurationSeconds: Double?
    public var location: LocationSnapshot?
    public var mapSnapshotFileName: String?

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        createdAt: Date = Date(),
        transcript: String,
        publicIP: String? = nil,
        audioFileName: String? = nil,
        audioDurationSeconds: Double? = nil,
        location: LocationSnapshot? = nil,
        mapSnapshotFileName: String? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.createdAt = createdAt
        self.transcript = transcript
        self.publicIP = publicIP
        self.audioFileName = audioFileName
        self.audioDurationSeconds = audioDurationSeconds
        self.location = location
        self.mapSnapshotFileName = mapSnapshotFileName
    }
}

/// Location snapshot captured at the time of recording
public struct LocationSnapshot: Codable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let horizontalAccuracy: Double
    public let placemarkDescription: String?

    public init(latitude: Double, longitude: Double, horizontalAccuracy: Double, placemarkDescription: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.placemarkDescription = placemarkDescription
    }
}


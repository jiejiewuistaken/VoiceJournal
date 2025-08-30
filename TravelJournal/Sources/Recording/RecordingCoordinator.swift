import Foundation
import AVFoundation
import CoreLocation

/// Coordinates recording flow with metadata capture and storage
public final class RecordingCoordinator: NSObject {
    private let storage: TripStorage
    private let locationService: LocationService
    private let ipService: IPService

    private var recorder: AVAudioRecorder?
    private var currentTripId: UUID

    public init(storage: TripStorage, locationService: LocationService, ipService: IPService, tripId: UUID) {
        self.storage = storage
        self.locationService = locationService
        self.ipService = ipService
        self.currentTripId = tripId
        super.init()
    }

    // MARK: - Recording

    public func beginRecording() throws -> URL {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try AVAudioSession.sharedInstance().setActive(true)

        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        recorder.record()
        self.recorder = recorder
        return fileURL
    }

    public func endRecording(transcript: String, completion: @escaping (Result<Entry, Error>) -> Void) {
        guard let recorder = recorder else {
            completion(.failure(NSError(domain: "Recording", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active recorder"])) )
            return
        }
        recorder.stop()
        let duration = recorder.currentTime
        let recordedURL = recorder.url
        self.recorder = nil

        // Snapshot location
        let location = locationService.lastLocation
        var locationSnapshot: LocationSnapshot?
        if let loc = location {
            locationSnapshot = LocationSnapshot(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                horizontalAccuracy: loc.horizontalAccuracy,
                placemarkDescription: locationService.lastPlacemarkDescription
            )
        }

        // Fetch IP in parallel with storage write
        ipService.fetchPublicIP { [weak self] result in
            guard let self = self else { return }
            let publicIP: String?
            switch result {
            case .success(let info):
                publicIP = info.ip
            case .failure:
                publicIP = nil
            }

            do {
                var entry = try self.storage.saveEntry(tripId: self.currentTripId, transcript: transcript, audioSourceURL: recordedURL)
                entry.audioDurationSeconds = duration
                entry.location = locationSnapshot
                entry.publicIP = publicIP

                // Persist the enriched entry JSON
                let jsonURL = self.storage.paths.entryJSONFile(tripId: entry.tripId, entryId: entry.id)
                try self.storage
                    .encoderForExternalUse()
                    .encode(entry)
                    .write(to: jsonURL, options: [.atomic])

                completion(.success(entry))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

private extension TripStorage {
    func encoderForExternalUse() -> JSONEncoderWritable {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return JSONEncoderWritable(encoder: encoder)
    }
}

public struct JSONEncoderWritable {
    let encoder: JSONEncoder
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
}


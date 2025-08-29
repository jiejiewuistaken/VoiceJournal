import Foundation

public final class AppServices {
    public let storage: TripStorage
    public let location: LocationService
    public let ip: IPService

    public init() throws {
        self.storage = try TripStorage()
        self.location = LocationService()
        self.ip = IPService()
        self.location.requestAuthorization()
        self.location.start()
    }
}


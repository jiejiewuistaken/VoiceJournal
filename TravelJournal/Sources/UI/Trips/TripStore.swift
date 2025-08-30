import Foundation
import Combine

public final class TripStore: ObservableObject {
    private let services: AppServices
    @Published public private(set) var trips: [Trip] = []
    @Published public var selectedTrip: Trip?

    public init(services: AppServices) {
        self.services = services
        reload()
        if let first = trips.first { selectedTrip = first }
    }

    public func reload() {
        trips = services.storage.listTrips()
    }

    public func createTrip(title: String) {
        do {
            let trip = try services.storage.createTrip(title: title)
            reload()
            selectedTrip = trip
        } catch {
            print("Create trip failed: \(error)")
        }
    }

    public func deleteTrip(_ trip: Trip) {
        do {
            try services.storage.deleteTrip(id: trip.id)
            reload()
            if selectedTrip?.id == trip.id { selectedTrip = trips.first }
        } catch {
            print("Delete trip failed: \(error)")
        }
    }

    public func entries(for trip: Trip) -> [Entry] {
        services.storage.listEntries(tripId: trip.id)
    }
}


import Foundation

public final class LogExporter {
    private let storage: TripStorage

    public init(storage: TripStorage) { self.storage = storage }

    public func exportTripMarkdown(tripId: UUID) throws -> URL {
        let trip = try storage.loadTrip(id: tripId)
        let entries = storage.listEntries(tripId: tripId)
        let md = renderMarkdown(trip: trip, entries: entries)
        let docs = TripStorage.defaultDocumentsDirectory()
        let fileURL = docs.appendingPathComponent("Trips").appendingPathComponent(trip.id.uuidString).appendingPathComponent("trip.md")
        try md.data(using: .utf8)?.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    public func exportDailyMarkdown(tripId: UUID, day: Date) throws -> URL {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let all = storage.listEntries(tripId: tripId)
        let entries = all.filter { $0.createdAt >= start && $0.createdAt < end }
        let trip = try storage.loadTrip(id: tripId)
        let md = renderMarkdown(trip: trip, entries: entries, titleSuffix: " - " + DateFormatter.localizedString(from: day, dateStyle: .medium, timeStyle: .none))
        let dir = TripStorage.defaultDocumentsDirectory().appendingPathComponent("Trips").appendingPathComponent(trip.id.uuidString)
        let fileURL = dir.appendingPathComponent("\(dateFileName(day)).md")
        try md.data(using: .utf8)?.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    private func dateFileName(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private func renderMarkdown(trip: Trip, entries: [Entry], titleSuffix: String = "") -> String {
        var lines: [String] = []
        lines.append("# \(trip.title)\(titleSuffix)")
        lines.append("")
        let dfTime = DateFormatter()
        dfTime.dateFormat = "HH:mm"
        for entry in entries.sorted(by: { $0.createdAt < $1.createdAt }) {
            let time = dfTime.string(from: entry.createdAt)
            let place = entry.location?.placemarkDescription ?? "(\(entry.location?.latitude ?? 0), \(entry.location?.longitude ?? 0))"
            let ip = entry.publicIP.map { "IP: \($0)" } ?? ""
            lines.append("## \(time) - \(place)")
            if !ip.isEmpty { lines.append(ip) }
            lines.append("")
            lines.append(entry.transcript)
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}


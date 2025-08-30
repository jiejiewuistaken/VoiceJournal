import Foundation

public enum IPServiceError: Error {
    case invalidResponse
}

public final class IPService {
    public struct IPInfo: Codable {
        public let ip: String
        public let city: String?
        public let region: String?
        public let country: String?
        public let loc: String?
        public let org: String?
        public let timezone: String?
    }

    public init() {}

    public func fetchPublicIP(completion: @escaping (Result<IPInfo, Error>) -> Void) {
        // Using ipinfo.io as an example; consider your own API key for higher limits
        guard let url = URL(string: "https://ipinfo.io/json") else {
            completion(.failure(IPServiceError.invalidResponse))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(IPServiceError.invalidResponse))
                return
            }
            do {
                let info = try JSONDecoder().decode(IPInfo.self, from: data)
                completion(.success(info))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}


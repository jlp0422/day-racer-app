import Foundation

enum AppError: Error, LocalizedError {
    case network(underlying: Error? = nil)
    case duplicate(message: String = "Resource already exists")
    case server(statusCode: Int? = nil, message: String? = nil)
    case unknown(message: String? = nil)

    var errorDescription: String? {
        switch self {
        case .network(let underlying):
            if let underlying {
                return "Network error: \(underlying.localizedDescription)"
            }
            return "A network error occurred. Please check your connection."
        case .duplicate(let message):
            return message
        case .server(let statusCode, let message):
            var desc = "Server error"
            if let statusCode { desc += " (\(statusCode))" }
            if let message { desc += ": \(message)" }
            return desc
        case .unknown(let message):
            return message ?? "An unknown error occurred."
        }
    }
}

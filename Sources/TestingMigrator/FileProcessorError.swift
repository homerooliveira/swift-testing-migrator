import Foundation

enum FileProcessorError: Error, LocalizedError {
    case pathNotFound(String)
    case cannotEnumerateDirectory(String)
    case cannotReadFile(String, any Error)
    case emptyDirectory(String)

    var errorDescription: String? {
        switch self {
        case .pathNotFound(let path):
            "Path not found: \(path)"
        case .cannotEnumerateDirectory(let path):
            "Cannot enumerate directory: \(path)"
        case .cannotReadFile(let path, let error):
            "Cannot read file at \(path): \(error.localizedDescription)"
        case .emptyDirectory(let path):
            "No Swift files found in directory: \(path)"
        }
    }
}

import Foundation

struct FileProcessor {
    
    /// Process files at the given path with optional recursive directory traversal
    /// - Parameters:
    ///   - path: The file or directory path to process
    ///   - recursive: Whether to recursively process subdirectories (default: false)
    func processPath(
        _ path: String,
        recursive: Bool = false,
        processContent: (String, URL) throws -> Void
    ) throws {
        let url = URL(fileURLWithPath: path)
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw FileProcessorError.pathNotFound(path)
        }
        
        if isDirectory.boolValue {
            try processDirectory(url, recursive: recursive, processContent: processContent)
        } else {
            try processFile(url, processContent: processContent)
        }
    }
    
    /// Process a single directory
    /// - Parameters:
    ///   - directoryURL: The directory URL to process
    ///   - recursive: Whether to recursively process subdirectories
    private func processDirectory(
        _ directoryURL: URL,
        recursive: Bool,
        processContent: (String, URL) throws -> Void
    ) throws {
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]

        guard let filesEnumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: resourceKeys,
            options: recursive ? [] : [.skipsSubdirectoryDescendants]
        ) else {
            throw FileProcessorError.cannotEnumerateDirectory(directoryURL.path)
        }
        
        // Collect all file URLs first
        var fileURLs: [URL] = []
        
        for case let fileURL as URL in filesEnumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            
            if resourceValues.isRegularFile == true && fileURL.pathExtension == "swift" {
                fileURLs.append(fileURL)
            }
        }
        
        for fileURL in fileURLs {
            try processFile(fileURL, processContent: processContent)
        }
    }
    
    /// Process a single file
    /// - Parameter fileURL: The file URL to process
    private func processFile(_ fileURL: URL, processContent: (String, URL) throws -> Void) throws {
        do {
            let data = try Data(contentsOf: fileURL)
            let content = String(decoding: data, as: UTF8.self)
            try processContent(content, fileURL)
        } catch {
            throw FileProcessorError.cannotReadFile(fileURL.path, error)
        }
    }
}

// MARK: - Error Handling

enum FileProcessorError: Error, LocalizedError {
    case pathNotFound(String)
    case cannotEnumerateDirectory(String)
    case cannotReadFile(String, any Error)
    
    var errorDescription: String? {
        switch self {
        case .pathNotFound(let path):
            "Path not found: \(path)"
        case .cannotEnumerateDirectory(let path):
            "Cannot enumerate directory: \(path)"
        case .cannotReadFile(let path, let error):
            "Cannot read file at \(path): \(error.localizedDescription)"
        }
    }
}
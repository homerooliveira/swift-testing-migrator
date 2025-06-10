public import Foundation

public struct FileProcessor: Sendable {

    public init() {}

    /// Process files at the given path with optional recursive directory traversal
    /// - Parameters:
    ///   - path: The file or directory path to process
    ///   - recursive: Whether to recursively process subdirectories (default: false)
    ///   - processContent: Closure to process file content
    public func process(
        path: String,
        recursive: Bool = false,
        processContent: (String, URL) throws -> Void
    ) throws {
        let url = try validatePath(path)
        let files = try swiftFiles(in: url, recursive: recursive)

        for fileURL in files {
            try processFile(fileURL, processContent: processContent)
        }
    }

    /// Async version of process
    public func processAsync(
        path: String,
        recursive: Bool = false,
        processContent: @Sendable @escaping (String, URL) throws -> Void
    ) async throws {
        let url = try validatePath(path)
        try await processURLAsync(url, recursive: recursive, processContent: processContent)
    }

    // MARK: - Private Helper Methods

    /// Validates that a path exists and returns its URL
    private func validatePath(_ path: String) throws -> URL {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw FileProcessorError.pathNotFound(path)
        }
        return url
    }

    /// Gets Swift files from a directory or processes a single file
    private func swiftFiles(in url: URL, recursive: Bool) throws -> [URL] {
        if try url.isDirectory() {
            return try swiftFilesFromDirectory(url, recursive: recursive)
        } else if try url.isSwiftFile() {
            return [url]
        } else {
            throw FileProcessorError.pathNotFound(url.path)
        }
    }

    /// Gets Swift files from a directory
    private func swiftFilesFromDirectory(_ directoryURL: URL, recursive: Bool) throws -> [URL] {
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
        let options: FileManager.DirectoryEnumerationOptions =
            if recursive {
                [.skipsHiddenFiles]
            } else {
                [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
            }

        guard
            let enumerator = FileManager.default.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: resourceKeys,
                options: options
            )
        else {
            throw FileProcessorError.cannotEnumerateDirectory(directoryURL.path)
        }

        return
            try enumerator
            .compactMap { $0 as? URL }
            .filter { try $0.isSwiftFile() }
    }

    /// Process URL (file or directory) asynchronously with concurrency limiting
    private func processURLAsync(
        _ url: URL,
        recursive: Bool,
        processContent: @Sendable @escaping (String, URL) throws -> Void
    ) async throws {
        let files = try swiftFiles(in: url, recursive: recursive)
        let maxConcurrentTasks = min(ProcessInfo.processInfo.activeProcessorCount, files.count)
        var submittedFiles = 0

        try await withThrowingTaskGroup(of: Void.self) { group in
            // Start initial batch of tasks
            for _ in 0..<maxConcurrentTasks {
                let fileURL = files[submittedFiles]

                group.addTask {
                    try await self.processFileAsync(fileURL, processContent: processContent)
                }

                submittedFiles += 1
            }

            for try await _ in group {

                // If there are more files to process, add them to the group
                if submittedFiles < files.count {
                    let fileURL = files[submittedFiles]

                    group.addTask {
                        try await self.processFileAsync(fileURL, processContent: processContent)
                    }

                    submittedFiles += 1
                }
            }
        }
    }

    /// Process a single file synchronously
    private func processFile(_ fileURL: URL, processContent: (String, URL) throws -> Void) throws {
        do {
            let data = try Data(contentsOf: fileURL)
            let content = String(decoding: data, as: UTF8.self)
            try processContent(content, fileURL)
        } catch {
            throw FileProcessorError.cannotReadFile(fileURL.path, error)
        }

    }

    /// Process a single file asynchronously
    private func processFileAsync(
        _ fileURL: URL,
        processContent: @Sendable @escaping (String, URL) throws -> Void
    ) async throws {
        try self.processFile(fileURL, processContent: processContent)
    }
}

// MARK: - URL Extensions

private extension URL {
    /// Check if URL represents a directory
    func isDirectory() throws -> Bool {
        let resourceValues = try resourceValues(forKeys: [.isDirectoryKey])
        return resourceValues.isDirectory == true
    }

    /// Check if URL represents a Swift file
    func isSwiftFile() throws -> Bool {
        let resourceValues = try resourceValues(forKeys: [.isRegularFileKey])
        return resourceValues.isRegularFile == true && pathExtension == "swift"
    }
}

// MARK: - Error Handling

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

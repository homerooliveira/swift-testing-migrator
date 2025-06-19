import Foundation

public struct FileProcessor: Sendable {
    public struct Configuration: Sendable {
        let sourceFilePath: String
        let inPlace: Bool
        let recursive: Bool
        let useClass: Bool
        let parallel: Bool

        public init(
            sourceFilePath: String,
            inPlace: Bool,
            recursive: Bool,
            useClass: Bool,
            parallel: Bool
        ) {
            self.sourceFilePath = sourceFilePath
            self.inPlace = inPlace
            self.recursive = recursive
            self.useClass = useClass
            self.parallel = parallel
        }
    }

    public init() {}

    public func process(config: Configuration) async throws {
        let url = try validatePath(config.sourceFilePath)
        let files = try swiftFiles(in: url, recursive: config.recursive)

        if config.parallel {
            try await processURLAsync(files: files, config: config)
        } else {
            for fileURL in files {
                try processFile(fileURL, config)
            }
        }
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
        files: [URL],
        config: Configuration
    ) async throws {
        let maxConcurrentTasks = min(ProcessInfo.processInfo.activeProcessorCount, files.count)
        var submittedFiles = 0

        try await withThrowingTaskGroup { group in
            // Start initial batch of tasks
            for _ in 0..<maxConcurrentTasks {
                let fileURL = files[submittedFiles]

                group.addTask {
                    try self.processFile(fileURL, config)
                }

                submittedFiles += 1
            }

            for try await _ in group {

                // If there are more files to process, add them to the group
                if submittedFiles < files.count {
                    let fileURL = files[submittedFiles]

                    group.addTask {
                        try self.processFile(fileURL, config)
                    }

                    submittedFiles += 1
                }
            }
        }
    }

    /// Process a single file synchronously
    private func processFile(_ fileURL: URL, _ config: Configuration) throws {
        do {
            let data = try Data(contentsOf: fileURL)
            let content = String(decoding: data, as: UTF8.self)
            let rewriter = Rewriter(useClass: config.useClass)
            let modifiedContent = rewriter.rewrite(source: content)

            if config.inPlace {
                try modifiedContent.write(to: fileURL, atomically: true, encoding: .utf8)
            } else {
                print(modifiedContent)
            }
        } catch {
            throw FileProcessorError.cannotReadFile(fileURL.path, error)
        }
    }
}

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

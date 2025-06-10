import ArgumentParser
import Foundation
import TestingMigrator

@main
struct SwiftTestingMigrator: AsyncParsableCommand {

    @Argument(help: "The path to the source file to be migrated.")
    var sourceFilePath: String
    @Flag(help: "If set, the source file will be modified in place instead of printing the output.")
    var inPlace: Bool = false
    @Flag(help: "Whether to process files recursively in directories.")
    var recursive = false
    @Flag(help: "Whether to use test suite class-based.")
    var useClass: Bool = false
    @Flag(help: "Whether to run the migration in parallel.")
    var parallel: Bool = false

    func run() async throws {
        let fileProcessor = FileProcessor()

        let processPath: @Sendable (String, URL) throws -> Void = { content, fileURL in
            let rewriter = Rewriter(Rewriter.Configuration(useClass: useClass))
            let modifiedSource = rewriter.rewrite(source: content).description
            if inPlace {
                try modifiedSource.write(to: fileURL, atomically: true, encoding: .utf8)
            } else {
                print(modifiedSource)
            }
        }

        if parallel {
            try await fileProcessor.processAsync(
                path: sourceFilePath,
                recursive: recursive,
                processContent: processPath
            )
        } else {
            try fileProcessor.process(
                path: sourceFilePath,
                recursive: recursive,
                processContent: processPath
            )
        }
    }
}

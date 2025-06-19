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
        let config = FileProcessor.Configuration(
            sourceFilePath: sourceFilePath,
            inPlace: inPlace,
            recursive: recursive,
            useClass: useClass,
            parallel: parallel
        )
        try await fileProcessor.process(config: config)
    }
}

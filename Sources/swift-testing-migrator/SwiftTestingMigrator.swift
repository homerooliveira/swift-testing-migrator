import ArgumentParser
import Foundation
import TestingMigrator

@main
struct SwiftTestingMigrator: AsyncParsableCommand {

    @Argument(help: "The path to the source file to be migrated.")
    var sourceFilePath: String
    @Argument(help: "The path to the destination file.")
    var destinationFilePath: String?
    @Flag(help: "Perform a dry run without making changes.")
    var dryRun: Bool = false

    mutating func run() async throws {
        let fileProcessor = FileProcessor()
        let rewriter = Rewriter(.init(useClass: false))

        try fileProcessor.processPath(sourceFilePath, recursive: false) { content, fileURL in
            let modifiedSource = rewriter.rewrite(source: content).description
            try modifiedSource.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}

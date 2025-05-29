import ArgumentParser
import Foundation
import TestingMigrator

@main
struct SwiftTestingMigrator: AsyncParsableCommand {

    @Argument(help: "The path to the source file to be migrated.")
    var sourceFilePath: String
    @Argument(help: "The path to the destination file.")
    var destinationFilePath: String?
    @Flag(help: "")
    var inPlace: Bool = false
    @Flag(help: "")
    var recursive = false

    mutating func run() async throws {
        let fileProcessor = FileProcessor()
        let rewriter = Rewriter(.init(useClass: true))

        try fileProcessor.processPath(sourceFilePath, recursive: recursive) { content, fileURL in
            let modifiedSource = rewriter.rewrite(source: content).description
            if inPlace {
                try modifiedSource.write(to: fileURL, atomically: true, encoding: .utf8)
            } else {
                print(modifiedSource)
            }
        }
    }
}

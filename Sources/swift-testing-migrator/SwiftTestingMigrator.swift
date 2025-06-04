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

    mutating func run() throws {
        let fileProcessor = FileProcessor()
        let rewriter = Rewriter(Rewriter.Configuration(useClass: useClass))

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

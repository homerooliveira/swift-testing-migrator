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
        let source = try String(contentsOfFile: sourceFilePath, encoding: .utf8)
        let rewriter = Rewriter(.init(useClass: false))
        let modifiedSource = rewriter.rewrite(source: source).description

        if dryRun || destinationFilePath == nil {
            print("Dry run: No changes made.")
            print("Modified source:\n\(modifiedSource)")
        } else if let destinationFilePath  {
            let destinationFileURL = URL(fileURLWithPath: destinationFilePath)
            try modifiedSource.write(to: destinationFileURL, atomically: true, encoding: .utf8)
            print("Changes made to \(destinationFilePath).")
        }
    }
}

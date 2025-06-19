# Swift Testing Migrator

Swift Testing Migrator is a command-line tool to automate the migration of XCTest-based test suites to the Swift Testing framework. Built with SwiftSyntax and Swift Argument Parser.

## Features

- **Complete class transformation**: Converts `XCTestCase` classes to Swift Testing structs or classes
- **Smart method rewriting**: Adds `@Test` attributes to test methods
- **Setup method conversion**: Turns `setUp`/`setUpWithError` into initializers
- **Assertion mapping**: Maps XCTest assertions to Swift Testing equivalents
- **Code cleanup**: Removes unnecessary inheritance and modifiers
- **Format preservation**: Keeps your comments, whitespace, and code structure intact
- **Batch processing**: Handles individual files or entire directories

## Requirements

- **Swift**: 6.1 or later
- **Platform**: macOS 15 or later, Linux, and Windows

## Installation & Usage

### Quick Start

Clone and build the migrator:

```bash
git clone https://github.com/your-username/swift-testing-migrator.git
cd swift-testing-migrator
swift build --configuration release
```

### Command-Line Usage

**Single file migration:**
```bash
swift-testing-migrator MyTestFile.swift
```

**Directory migration (recommended):**
```bash
swift-testing-migrator Tests/ --in-place --recursive
```

**High-performance batch migration:**
```bash
swift-testing-migrator Tests/ --in-place --recursive --parallel
```

**Preview changes before applying:**
```bash
swift-testing-migrator Tests/ --recursive  # Outputs to stdout
```

**Migrate to class-based test suites:**
```bash
swift-testing-migrator Tests/ --in-place --recursive --use-class
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `--in-place` | Modify files directly instead of printing to stdout |
| `--recursive` | Process all Swift files in subdirectories |
| `--parallel` | Enable parallel processing (recommended with `--in-place`) |
| `--use-class` | Convert XCTestCase to class-based test suites instead of structs |
| `--help` | Show usage information |

## Migration Reference

### Assertion Transformations

| XCTest | Swift Testing |
|--------|---------------|
| `XCTAssert(condition)` | `#expect(condition)` |
| `XCTAssertTrue(condition)` | `#expect(condition)` |
| `XCTAssertFalse(condition)` | `#expect(!condition)` |
| `XCTAssertNil(value)` | `#expect(value == nil)` |
| `XCTAssertNotNil(value)` | `#expect(value != nil)` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertNotEqual(a, b)` | `#expect(a != b)` |
| `XCTAssertIdentical(a, b)` | `#expect(a === b)` |
| `XCTAssertNotIdentical(a, b)` | `#expect(a !== b)` |
| `XCTAssertGreaterThan(a, b)` | `#expect(a > b)` |
| `XCTAssertGreaterThanOrEqual(a, b)` | `#expect(a >= b)` |
| `XCTAssertLessThan(a, b)` | `#expect(a < b)` |
| `XCTAssertLessThanOrEqual(a, b)` | `#expect(a <= b)` |
| `try XCTUnwrap(optional)` | `try #require(optional)` |
| `XCTFail("message")` | `Issue.record("message")` |

> **Note:** File and line parameters (e.g., `file: #file, line: #line`) are omitted in the migrated code, as they are not required in Swift Testing.

### Error Handling

| XCTest | Swift Testing |
|--------|---------------|
| `XCTAssertThrowsError(try expression())` | `#expect(throws: (any Error).self) { try expression() }` |
| `XCTAssertThrowsError(try expression()) { error in /* handle */ }` | `let error = #expect(throws: (any Error).self) { try expression() }` |
| `XCTAssertNoThrow(try expression())` | `#expect(throws: Never.self) { try expression() }` |

### Structure Changes

| XCTest | Swift Testing | Notes |
|--------|---------------|---------------|
| `import XCTest` | `import Testing` | |
| `class MyTests: XCTestCase` | `struct MyTests` or `class MyTests` | Classes are converted to structs by default; use `--use-class` to keep as classes. |
| `func testSomething() { }` | `@Test func testSomething() { }` | Methods starting with `test` are annotated with `@Test`. |
| `override func setUp() async throws` | `init() async throws` | `setUp`/`setUpWithError` are converted to initializers. |
| `override func tearDown()` | `deinit` | Async or throwing `tearDown` methods are not supported and require manual migration. |

## Project Architecture

```
swift-testing-migrator/
├── Sources/
│   ├── TestingMigrator/          # Core migration engine
│   └── swift-testing-migrator/  # Command-line interface
├── Tests/
│   └── TestingMigratorTests/    # Comprehensive test suite
└── Package.swift                # Swift Package Manager configuration
```

## Development

### Dependencies

This project uses some great tools from the Swift ecosystem:
- **[swift-syntax](https://github.com/apple/swift-syntax)**: For parsing and transforming Swift source code
- **[swift-argument-parser](https://github.com/apple/swift-argument-parser)**: For building a modern command-line interface

### Building from Source

```bash
# Debug build (faster compilation)
swift build

# Release build (optimized performance)
swift build --configuration release
```

### Running Tests

```bash
# Run all tests
swift test
```

### Performance Testing

To benchmark the migrator's performance on your system:

```bash
# Run performance test with 1,000 files containing 10 methods each
./measure_performance.sh 1000 --methods 10
```

This generates test fixtures, runs benchmarks for all processing modes, and provides detailed timing comparisons to help you pick the best configuration for your needs.

#### Benchmark Results
*Tested on 1,000 Swift test files with 10 methods each*

| Mode | Processing | Time |
|------|------------|------|
| **Read-only** | Sequential | 2.02s |
| Read-only | Parallel | 2.63s |
| **In-place** | Sequential | 548ms |
| **In-place** | Parallel | 209ms |

> **Note:** Tested on a Mac mini M4 Pro with 24GB RAM. Results may vary based on system configuration.

### Contributing

We love contributions! Here’s how you can help:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-improvement`
3. **Make** your changes with tests
4. **Run** the test suite: `swift test`
5. **Submit** a pull request

#### Contribution Guidelines

- Add tests for new features or bug fixes
- Keep code formatting consistent
- Update documentation for user-facing changes
- Include example transformations in your PR description

## Known Limitations

- Some XCTest-specific features (like performance testing) don’t have direct Swift Testing equivalents
- The tool doesn’t currently support migrating tests that use `XCTestExpectation`, asynchronous tests, `XCTSkip`, or `XCTSkipIf`; these need manual migration
- Migration of `XCTestCase` subclasses with complex inheritance hierarchies may require manual adjustments
- It’s a good idea to run formatting tools like `swift-format` after migration to ensure code style consistency

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Ready to modernize your test suite?** Get started with Swift Testing Migrator today and experience the power of Swift Testing! 🚀
# swift-testing-migrator

A powerful Swift command-line tool and library that automates the migration of XCTest-based test suites to Apple's modern Swift Testing framework. Built with SwiftSyntax for precise source code transformation while preserving your code's structure and formatting.

## Why Swift Testing Migration?

Swift Testing, introduced in Swift 6, offers significant advantages over XCTest:
- **Modern syntax** with `@Test` attributes and `#expect` macros
- **Better error reporting** with detailed failure information
- **Improved performance** and parallelization capabilities
- **Enhanced developer experience** with cleaner, more expressive test code

This tool handles the tedious migration work automatically, letting you focus on improving your tests rather than manually rewriting syntax.

## ✨ Features

- **Complete class transformation**: Converts `XCTestCase` classes to Swift Testing structs or classes
- **Intelligent method rewriting**: Transforms test methods to use `@Test` attributes
- **Setup method conversion**: Migrates `setUp`/`setUpWithError` to proper initializers
- **Comprehensive assertion mapping**: Converts all common XCTest assertions to Swift Testing equivalents
- **Smart cleanup**: Removes unnecessary inheritance and modifiers
- **Format preservation**: Maintains your existing comments, whitespace, and code structure
- **Batch processing**: Handle individual files or entire directory trees

## ⚡ Performance

The migrator is optimized for both single-file and large-scale migrations:

### Benchmark Results
*Tested on 1,000 Swift test files with 10 methods each*

| Mode | Processing | Time | Performance |
|------|------------|------|-------------|
| **Read-only** | Sequential | 2.02s | ⭐ Recommended |
| Read-only | Parallel | 2.63s | 30% slower |
| **In-place** | Sequential | 548ms | Fast |
| **In-place** | Parallel | 209ms | ⭐ **2.6x faster** |

### Performance Recommendations

- **For in-place migrations**: Use `--parallel` for optimal performance (2.6x speedup)
- **For preview/read-only**: Use sequential processing (parallel adds overhead)
- **Large codebases**: The `--in-place --parallel` combination provides the best throughput

## 🔧 Requirements

- **Swift**: 6.1 or later
- **Platform**: macOS 15 or later, Linux and Windows

## 🚀 Installation & Usage

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
swift run swift-testing-migrator MyTestFile.swift
```

**Directory migration (recommended):**
```bash
swift run swift-testing-migrator Tests/ --in-place --recursive
```

**High-performance batch migration:**
```bash
swift run swift-testing-migrator Tests/ --in-place --recursive --parallel
```

**Preview changes before applying:**
```bash
swift run swift-testing-migrator Tests/ --recursive  # Outputs to stdout
```

**Migrate to class-based test suites:**
```bash
swift run swift-testing-migrator Tests/ --in-place --recursive --use-class
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `--in-place` | Modify files directly instead of printing to stdout |
| `--recursive` | Process all Swift files in subdirectories |
| `--parallel` | Enable parallel processing (recommended with `--in-place`) |
| `--use-class` | Convert XCTestCase to class-based test suites instead of structs |
| `--help` | Show usage information |

## 📋 Migration Reference

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

## 🏗️ Project Architecture

```
swift-testing-migrator/
├── Sources/
│   ├── TestingMigrator/          # Core migration engine
│   └── swift-testing-migrator/  # Command-line interface
├── Tests/
│   └── TestingMigratorTests/    # Comprehensive test suite
└── Package.swift                # Swift Package Manager configuration
```

## 🔨 Development

### Dependencies

This project leverages powerful Swift ecosystem tools:
- **[swift-syntax](https://github.com/apple/swift-syntax)**: Robust Swift source code parsing and transformation
- **[swift-argument-parser](https://github.com/apple/swift-argument-parser)**: Modern command-line interface construction

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

This will generate test fixtures, run benchmarks for all processing modes, and provide detailed timing comparisons to help you choose the optimal configuration for your use case.

### Contributing

We welcome contributions! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-improvement`
3. **Make** your changes with tests
4. **Run** the test suite: `swift test`
5. **Submit** a pull request

#### Contribution Guidelines

- Add tests for new features or bug fixes
- Maintain code formatting consistency
- Update documentation for user-facing changes
- Include example transformations in your PR description

## 🐛 Known Limitations

- Some XCTest-specific features (like performance testing) don't have direct Swift Testing equivalents
- The tool does not currently support migrating tests that use `XCTestExpectation`, asynchronous tests, `XCTSkip` or `XCTSkipIf`; these need manual migration
- Migration of `XCTestCase` subclasses with complex inheritance hierarchies may require manual adjustments
- It is recommended to run formatting tools like `swift-format` after migration to ensure code style consistency

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Ready to modernize your test suite?** Get started with swift-testing-migrator today and experience the power of Swift Testing! 🚀
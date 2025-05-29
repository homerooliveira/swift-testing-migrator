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

## 🔧 Requirements

- **Swift**: 6.1 or later
- **Platform**: macOS 15 or later

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

**Preview changes before applying:**
```bash
swift run swift-testing-migrator Tests/ --recursive  # Outputs to stdout
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `--in-place` | Modify files directly instead of printing to stdout |
| `--recursive` | Process all Swift files in subdirectories |
| `--help` | Show usage information |

## 📋 Migration Reference

### Assertion Transformations

| XCTest | Swift Testing | Notes |
|--------|---------------|-------|
| `XCTAssert(condition)` | `#expect(condition)` | |
| `XCTAssertTrue(condition)` | `#expect(condition)` | |
| `XCTAssertFalse(condition)` | `#expect(!condition)` | |
| `XCTAssertNil(value)` | `#expect(value == nil)` | |
| `XCTAssertNotNil(value)` | `#expect(value != nil)` | |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` | |
| `XCTAssertNotEqual(a, b)` | `#expect(a != b)` | |
| `XCTAssertIdentical(a, b)` | `#expect(a === b)` | Reference equality |
| `XCTAssertNotIdentical(a, b)` | `#expect(a !== b)` | Reference inequality |
| `XCTAssertGreaterThan(a, b)` | `#expect(a > b)` | |
| `XCTAssertGreaterThanOrEqual(a, b)` | `#expect(a >= b)` | |
| `XCTAssertLessThan(a, b)` | `#expect(a < b)` | |
| `XCTAssertLessThanOrEqual(a, b)` | `#expect(a <= b)` | |
| `try XCTUnwrap(optional)` | `try #require(optional)` | Safe unwrapping |
| `XCTFail("message")` | `Issue.record("message")` | Manual failure |

### Error Handling

| XCTest | Swift Testing |
|--------|---------------|
| `XCTAssertThrowsError(try expression())` | `#expect(throws: (any Error).self) { try expression() }` |
| `XCTAssertThrowsError(try expression()) { error in /* handle */ }` | `let error = #expect(throws: (any Error).self) { try expression() }` |
| `XCTAssertNoThrow(try expression())` | `#expect(throws: Never.self) { try expression() }` |

### Structure Changes

| XCTest | Swift Testing |
|--------|---------------|
| `import XCTest` | `import Testing` |
| `class MyTests: XCTestCase` | `struct MyTests` or `class MyTests` |
| `func testSomething() { }` | `@Test func something() { }` |
| `override func setUp() async throws` | `init() async throws` |

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

- Complex custom assertion macros may require manual adjustment
- Parameterized tests need manual conversion to Swift Testing's parameterization syntax
- Some XCTest-specific features (like performance testing) don't have direct Swift Testing equivalents

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Ready to modernize your test suite?** Get started with swift-testing-migrator today and experience the power of Swift Testing! 🚀
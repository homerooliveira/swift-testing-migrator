#!/bin/zsh
# measure_performance.sh
# Script to measure the performance of swift-testing-migrator on a given file or directory
set -e

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <Swift file|directory|fixture-count> [--runs N] [--warmup N] [--methods N]"
    exit 1
fi

TARGET="$1"
shift

# Parse hyperfine-specific options and scenario flags
RUNS=10
WARMUP=3
METHODS_COUNT=3  # Default number of test methods per fixture
IN_PLACE=false
PARALLEL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --runs)
            RUNS="$2"
            shift 2
            ;;
        --warmup)
            WARMUP="$2"
            shift 2
            ;;
        --methods)
            METHODS_COUNT="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Usage: $0 <Swift file|directory|fixture-count> [--runs N] [--warmup N] [--methods N]"
            exit 1
            ;;
    esac
done

# If the target is a number, generate that many fixture files and use the directory as the target
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
    FIXTURE_COUNT=$TARGET
    FIXTURE_DIR="PerfGenerated"
    mkdir -p "$FIXTURE_DIR"
    
    echo "Generating $FIXTURE_COUNT fixture files with $METHODS_COUNT methods each..."
    # Fixed: Use seq instead of brace expansion with variable
    for i in $(seq 1 $FIXTURE_COUNT); do
        cat > "$FIXTURE_DIR/FixturePerf$i.swift" <<EOF
// Auto-generated fixture file $i for performance testing
import Foundation
import XCTest

class PerfTest$i: XCTestCase {
    override func setUp() async throws {
        // Setup for test $i
    }
    
    override func tearDown() {
        // Cleanup for test $i
    }
EOF

        # Generate the specified number of test methods
        for j in $(seq 1 $METHODS_COUNT); do
            cat >> "$FIXTURE_DIR/FixturePerf$i.swift" <<EOF
    
    func testMethod${j}_$i() {
        XCTAssertEqual($i + $j, $((i + j)))
        XCTAssertTrue($i > 0)
        XCTAssertFalse($j < 0)
    }
EOF
        done

        # Add some additional assertion methods based on method count
        if [[ $METHODS_COUNT -gt 1 ]]; then
            cat >> "$FIXTURE_DIR/FixturePerf$i.swift" <<EOF
    
    func testAssertions$i() {
        XCTAssert(true)
        XCTAssertTrue($i > 0)
        XCTAssertFalse($i < 0)
        XCTAssertNil(nil)
        XCTAssertNotNil($i)
        XCTAssertEqual($i, $i)
        XCTAssertNotEqual($i, $((i + 1)))
        XCTAssertIdentical(NSString(string: "a"), NSString(string: "a"))
        XCTAssertNotIdentical(NSString(string: "a"), NSString(string: "b"))
        XCTAssertGreaterThan($i + 1, $i)
        XCTAssertGreaterThanOrEqual($i, $i)
        XCTAssertLessThan($i, $i + 1)
        XCTAssertLessThanOrEqual($i, $i)
    }
EOF
        fi

        if [[ $METHODS_COUNT -gt 2 ]]; then
            cat >> "$FIXTURE_DIR/FixturePerf$i.swift" <<EOF
    
    func testUnwrapAndErrors$i() throws {
        let optional: Int? = $i
        let unwrapped = try XCTUnwrap(optional)
        XCTAssertEqual(unwrapped, $i)
        
        XCTAssertThrowsError(try throwingFunction$i()) { error in
            // Handle error
        }
        
        XCTAssertNoThrow(try nonThrowingFunction$i())
        
        if $i % 10 == 0 {
            XCTFail("Test failure message for $i")
        }
    }
EOF
        fi

        # Add helper methods if we have more than basic methods
        if [[ $METHODS_COUNT -gt 2 ]]; then
            cat >> "$FIXTURE_DIR/FixturePerf$i.swift" <<EOF
    
    private func throwingFunction$i() throws {
        if $i % 5 == 0 {
            throw TestError.sample
        }
    }
    
    private func nonThrowingFunction$i() throws {
        // This doesn't throw
    }
EOF
        fi

        # Close the class and add enum
        cat >> "$FIXTURE_DIR/FixturePerf$i.swift" <<EOF
}

enum TestError: Error {
    case sample
}
EOF
    done
    TARGET="$FIXTURE_DIR"
fi

# Check if hyperfine is available
if ! command -v hyperfine &> /dev/null; then
    echo "Error: hyperfine is not installed. Please install it with:"
    echo "  brew install hyperfine  # macOS"
    echo "  cargo install hyperfine # via Cargo"
    exit 1
fi

# Build the Swift package in release mode first
echo "Building swift-testing-migrator in release mode..."
swift build -c release

# Build the command to benchmark (using the built binary directly)
BINARY_PATH=$(swift build -c release --show-bin-path)/swift-testing-migrator

# Create commands for different scenarios (always with --recursive)
BASE_CMD="$BINARY_PATH '$TARGET' --recursive"

# Group 1: Commands without --in-place
NO_INPLACE_COMMANDS=(
    "$BASE_CMD"
    "$BASE_CMD --parallel"
)

# Group 2: Commands with --in-place
INPLACE_COMMANDS=(
    "$BASE_CMD --in-place"
    "$BASE_CMD --in-place --parallel"
)

# Command names for display (without full path)
NO_INPLACE_NAMES=(
    "swift-testing-migrator --recursive"
    "swift-testing-migrator --recursive --parallel"
)

INPLACE_NAMES=(
    "swift-testing-migrator --recursive --in-place"
    "swift-testing-migrator --recursive --in-place --parallel"
)

echo "Benchmarking scenarios:"
echo "Group 1 (without --in-place):"
for cmd in "${NO_INPLACE_NAMES[@]}"; do
    echo "  $cmd"
done
echo "Group 2 (with --in-place):"
for cmd in "${INPLACE_NAMES[@]}"; do
    echo "  $cmd"
done
echo "Runs: $RUNS, Warmup: $WARMUP"
echo ""

# Run hyperfine for Group 1 (without --in-place)
echo "=== Benchmarking Group 1: Without --in-place ==="
hyperfine \
    --runs "$RUNS" \
    --warmup "$WARMUP" \
    --style full \
    --command-name "${NO_INPLACE_NAMES[1]}" "${NO_INPLACE_COMMANDS[1]}" \
    --command-name "${NO_INPLACE_NAMES[2]}" "${NO_INPLACE_COMMANDS[2]}"

echo ""
echo "=== Benchmarking Group 2: With --in-place ==="
hyperfine \
    --runs "$RUNS" \
    --warmup "$WARMUP" \
    --style full \
    --command-name "${INPLACE_NAMES[1]}" "${INPLACE_COMMANDS[1]}" \
    --command-name "${INPLACE_NAMES[2]}" "${INPLACE_COMMANDS[2]}"

# Clean up generated fixture directory if it was created
if [[ -n "$FIXTURE_DIR" && -d "$FIXTURE_DIR" ]]; then
    echo "Cleaning up generated fixture directory: $FIXTURE_DIR"
    rm -rf "$FIXTURE_DIR"
fi
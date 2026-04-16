# mac-app

A template macOS SwiftUI application built with CMake and Swift Package Manager, demonstrating C library integration, concurrent task management, and embedded Python.

## Projects

| Project | Description | Build System |
|---|---|---|
| `projects/swiftui-cmake` | SwiftUI app with C math library bridge | CMake + Ninja |
| `projects/swiftui-cmake-python` | Same as above, plus an embedded Python 3.13 interpreter | CMake + Ninja |
| `projects/swiftui-spm` | SwiftUI app with C math library bridge | Swift Package Manager |

### Architecture

All three projects share a common layered architecture:

- **MathLib** -- Pure C library (add, subtract, multiply, divide, factorial, fibonacci)
- **MathBridge** -- Swift wrapper that converts C error patterns to Swift exceptions
- **TaskRunner** -- Pure Swift concurrent task execution framework (`AppTask` protocol, `TaskManager`, `TaskContext`)
- **MacApp** -- SwiftUI application with tabbed UI: task manager, math demo, and (in the Python variant) a Python console

The `swiftui-cmake-python` variant adds:

- **PythonLib** -- C wrapper around the Python C API (init, run with stdout/stderr capture, finalize)
- **PythonBridge** -- Swift bridge exposing `PythonBridge.initialize(home:)`, `.run(_:)`, `.shutdown()`
- **PythonConsoleView** -- Split-pane code editor and output view for running Python interactively

## Prerequisites

- macOS 14.0+
- Xcode with Swift 5.9+
- CMake 3.25+ and Ninja
- Python 3 (for building the embedded interpreter)
- Homebrew packages for the Python build: `readline`, `ncurses`

## Build

```sh
# Build the CMake and SPM projects (does not include the Python variant)
make build

# Build and bundle with distinct names in build/
make bundle-cmake    # -> build/MacApp-cmake.app
make bundle-spm      # -> build/MacApp-spm.app

# Build the Python variant (first run builds Python from source via scripts/buildpy.py)
make bundle-cmake-python  # -> build/MacApp-cmake-python.app
```

## Run

```sh
make run-cmake          # Open MacApp-cmake.app
make run-spm            # Open MacApp-spm.app
make run-cmake-python   # Open MacApp-cmake-python.app
```

## Test

```sh
make test               # Run tests for CMake and SPM projects
make test-cmake-python  # Run tests for the Python variant
```

## Clean

```sh
make clean              # Remove entire build/ directory
```

## Makefile Targets

| Target | Description |
|---|---|
| `build` | Build CMake and SPM projects |
| `test` | Run all CMake and SPM tests |
| `clean` | Remove `build/` |
| `build-cmake` | Build the CMake project |
| `bundle-cmake` | Bundle as `build/MacApp-cmake.app` |
| `run-cmake` | Bundle and open |
| `test-cmake` | Run CMake project tests |
| `build-spm` | Build the SPM project |
| `bundle-spm` | Bundle as `build/MacApp-spm.app` |
| `run-spm` | Bundle and open |
| `test-spm` | Run SPM project tests |
| `build-python` | Build Python 3.13 framework via `scripts/buildpy.py` |
| `build-cmake-python` | Build the CMake+Python project |
| `bundle-cmake-python` | Bundle as `build/MacApp-cmake-python.app` with embedded Python.framework |
| `run-cmake-python` | Bundle and open |
| `test-cmake-python` | Run CMake+Python project tests |

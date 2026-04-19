# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `projects/infer`: SwiftUI chat app with two inference backends selectable at runtime via a header picker.
  - `llama.cpp` backend: loads a local `.gguf` file through `llama.xcframework` (downloaded by `scripts/fetch_llama_framework.sh`).
  - MLX backend: loads any MLX-compatible Hugging Face repo id via `mlx-swift-lm` (Mode 1 integration using `#huggingFaceLoadModelContainer`); defaults to `LLMRegistry.gemma3_1B_qat_4bit`.
- `scripts/fetch_llama_framework.sh`: downloads a tagged `llama-<tag>-xcframework.zip` from the llama.cpp releases and installs `thirdparty/llama.xcframework` (default tag `b8848`).
- Makefile targets: `fetch-llama`, `build-infer`, `bundle-infer`, `run-infer`.

### Changed
- `projects/infer` migrated from CMake to Swift Package Manager.
- `make build-infer` uses `xcodebuild` (not `swift build`) because mlx-swift's Metal kernels can only be compiled by Xcode's Metal toolchain; this requires the separate Metal Toolchain component (`xcodebuild -downloadComponent MetalToolchain`, ~700 MB, one-time).
- `bundle-infer` embeds `llama.framework` (from the `macos-arm64_x86_64` xcframework slice) into `Infer.app/Contents/Frameworks/` and copies SPM-emitted resource bundles (including `mlx-swift_Cmlx.bundle` containing `default.metallib`) into `Infer.app/Contents/Resources/`.
- Root `CMakeLists.txt` no longer adds `projects/infer`.

### Removed
- `projects/infer/CMakeLists.txt` (replaced by `projects/infer/Package.swift`).

### Notes
- First MLX model load downloads to `~/.cache/huggingface/hub/` (standard HF cache layout; override with `HF_HOME`).
- Prerequisites bumped for the `infer` project: Xcode 16.3+ / Swift 6.1+ (required by `mlx-swift-lm`). Other projects are unaffected.

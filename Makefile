BUILD_DIR := build
CMAKE := cmake
SPM_DIR := projects/swiftui-spm
SPM_BUILD_DIR := $(BUILD_DIR)/swiftui-spm
SPM_FLAGS := --scratch-path $(SPM_BUILD_DIR) --package-path $(SPM_DIR)

.PHONY: all configure build test clean run
.PHONY: build-cmake test-cmake run-cmake
.PHONY: build-spm test-spm run-spm

all: build

# --- Aggregate targets ---

configure:
	$(CMAKE) -S . -B $(BUILD_DIR) -G Ninja

build: build-cmake build-spm

test: test-cmake test-spm

clean:
	rm -rf $(BUILD_DIR)

# --- CMake project (swiftui-cmake) ---

build-cmake: configure
	$(CMAKE) --build $(BUILD_DIR)

test-cmake: build-cmake
	cd $(BUILD_DIR) && ctest --output-on-failure

run-cmake: build-cmake
	open $(BUILD_DIR)/projects/swiftui-cmake/MacApp.app

# --- SPM project (swiftui-spm) ---

build-spm:
	swift build $(SPM_FLAGS)

test-spm:
	swift test $(SPM_FLAGS)

run-spm: build-spm
	swift run $(SPM_FLAGS) MacApp

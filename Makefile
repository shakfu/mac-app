BUILD_DIR := build
CMAKE := cmake
SPM_DIR := projects/swiftui-spm
SPM_BUILD_DIR := $(BUILD_DIR)/swiftui-spm
SPM_FLAGS := --scratch-path $(SPM_BUILD_DIR) --package-path $(SPM_DIR)
SPM_BIN := $(SPM_BUILD_DIR)/arm64-apple-macosx/debug/MacApp
CMAKE_APP_BUNDLE := $(BUILD_DIR)/MacApp-cmake.app
SPM_APP_BUNDLE := $(BUILD_DIR)/MacApp-spm.app
PY_VER := 3.13
PY_FRAMEWORK := $(BUILD_DIR)/install/Python.framework
CMAKE_PY_DIR := projects/swiftui-cmake-python
CMAKE_PY_BUILD_DIR := $(BUILD_DIR)/cmake-python
CMAKE_PY_APP_BUNDLE := $(BUILD_DIR)/MacApp-cmake-python.app

.PHONY: all configure build test clean run
.PHONY: build-cmake test-cmake run-cmake bundle-cmake
.PHONY: build-spm test-spm run-spm bundle-spm
.PHONY: build-python build-cmake-python test-cmake-python bundle-cmake-python run-cmake-python

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

bundle-cmake: build-cmake
	rm -rf $(CMAKE_APP_BUNDLE)
	cp -R $(BUILD_DIR)/projects/swiftui-cmake/MacApp.app $(CMAKE_APP_BUNDLE)
	@echo "Built $(CMAKE_APP_BUNDLE)"

run-cmake: bundle-cmake
	open $(CMAKE_APP_BUNDLE)

# --- SPM project (swiftui-spm) ---

build-spm:
	swift build $(SPM_FLAGS)

test-spm:
	swift test $(SPM_FLAGS)

run-spm: bundle-spm
	open $(SPM_APP_BUNDLE)

bundle-spm: build-spm
	mkdir -p $(SPM_APP_BUNDLE)/Contents/MacOS
	mkdir -p $(SPM_APP_BUNDLE)/Contents/Resources
	cp $(SPM_BIN) $(SPM_APP_BUNDLE)/Contents/MacOS/MacApp
	cp $(SPM_DIR)/Sources/MacApp/Info.plist $(SPM_APP_BUNDLE)/Contents/Info.plist
	@echo "Built $(SPM_APP_BUNDLE)"

# --- CMake+Python project (swiftui-cmake-python) ---

build-python:
	@if [ ! -f "$(PY_FRAMEWORK)/Versions/$(PY_VER)/Python" ]; then \
		LDFLAGS="-L/opt/homebrew/opt/readline/lib -lreadline -L/opt/homebrew/opt/ncurses/lib -lncurses" \
		CPPFLAGS="-I/opt/homebrew/opt/readline/include" \
		python3 scripts/buildpy.py -c framework_mid -j4 && \
		install_name_tool -id @rpath/Python.framework/Versions/$(PY_VER)/Python \
			$(PY_FRAMEWORK)/Versions/$(PY_VER)/Python; \
	else \
		echo "Python framework already built at $(PY_FRAMEWORK)"; \
	fi

build-cmake-python: build-python
	$(CMAKE) -S $(CMAKE_PY_DIR) -B $(CMAKE_PY_BUILD_DIR) -G Ninja \
		-DPY_VER=$(PY_VER) \
		-DPY_FRAMEWORK_DIR=$(CURDIR)/$(BUILD_DIR)/install
	$(CMAKE) --build $(CMAKE_PY_BUILD_DIR)

test-cmake-python: build-cmake-python
	cd $(CMAKE_PY_BUILD_DIR) && ctest --output-on-failure

bundle-cmake-python: build-cmake-python
	rm -rf $(CMAKE_PY_APP_BUNDLE)
	cp -R $(CMAKE_PY_BUILD_DIR)/MacApp.app $(CMAKE_PY_APP_BUNDLE)
	mkdir -p $(CMAKE_PY_APP_BUNDLE)/Contents/Frameworks
	cp -R $(PY_FRAMEWORK) $(CMAKE_PY_APP_BUNDLE)/Contents/Frameworks/
	@echo "Built $(CMAKE_PY_APP_BUNDLE)"

run-cmake-python: bundle-cmake-python
	open $(CMAKE_PY_APP_BUNDLE)

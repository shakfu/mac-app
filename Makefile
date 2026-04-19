BUILD_DIR := build
CMAKE := cmake
SPM_DIR := projects/swiftui-spm
SPM_BUILD_DIR := $(BUILD_DIR)/swiftui-spm
SPM_FLAGS := --scratch-path $(SPM_BUILD_DIR) --package-path $(SPM_DIR)
SPM_BIN := $(SPM_BUILD_DIR)/arm64-apple-macosx/debug/MacApp
CMAKE_APP_BUNDLE := $(BUILD_DIR)/MacApp-cmake.app
INFER_APP_BUNDLE := $(BUILD_DIR)/Infer.app
SPM_APP_BUNDLE := $(BUILD_DIR)/MacApp-spm.app
PY_VER := 3.13
PY_FRAMEWORK := $(BUILD_DIR)/install/Python.framework
CMAKE_PY_DIR := projects/swiftui-cmake-python
CMAKE_PY_BUILD_DIR := $(BUILD_DIR)/cmake-python
CMAKE_PY_APP_BUNDLE := $(BUILD_DIR)/MacApp-cmake-python.app
LLAMA_XCFRAMEWORK := thirdparty/llama.xcframework
LLAMA_FRAMEWORK := $(LLAMA_XCFRAMEWORK)/macos-arm64_x86_64/llama.framework
LLAMA_TAG := b8848
INFER_DIR := projects/infer
INFER_BUILD_DIR := $(BUILD_DIR)/infer-xcode
INFER_CONFIG := Debug
INFER_XCODE_FLAGS := -workspace $(INFER_DIR) -scheme Infer \
	-destination 'platform=macOS,arch=arm64' \
	-configuration $(INFER_CONFIG) \
	-derivedDataPath $(CURDIR)/$(INFER_BUILD_DIR) \
	-skipMacroValidation
INFER_PRODUCT_DIR := $(INFER_BUILD_DIR)/Build/Products/$(INFER_CONFIG)
INFER_BIN := $(INFER_PRODUCT_DIR)/Infer

.PHONY: all configure build test clean run
.PHONY: build-cmake test-cmake run-cmake bundle-cmake
.PHONY: build-spm test-spm run-spm bundle-spm
.PHONY: build-python build-cmake-python test-cmake-python bundle-cmake-python run-cmake-python
.PHONY: build-infer bundle-infer run-infer fetch-llama

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

# --- Infer app (SwiftPM + llama.framework + MLX) ---

$(LLAMA_XCFRAMEWORK):
	./scripts/fetch_llama_framework.sh $(LLAMA_TAG)

fetch-llama: $(LLAMA_XCFRAMEWORK)

build-infer: $(LLAMA_XCFRAMEWORK)
	xcodebuild $(INFER_XCODE_FLAGS) build

bundle-infer: build-infer
	rm -rf $(INFER_APP_BUNDLE)
	mkdir -p $(INFER_APP_BUNDLE)/Contents/MacOS
	mkdir -p $(INFER_APP_BUNDLE)/Contents/Resources
	mkdir -p $(INFER_APP_BUNDLE)/Contents/Frameworks
	cp $(INFER_BIN) $(INFER_APP_BUNDLE)/Contents/MacOS/Infer
	cp $(INFER_DIR)/Sources/Infer/Info.plist $(INFER_APP_BUNDLE)/Contents/Info.plist
	cp -R $(LLAMA_FRAMEWORK) $(INFER_APP_BUNDLE)/Contents/Frameworks/llama.framework
	@for bundle in $(INFER_PRODUCT_DIR)/*.bundle; do \
		[ -e "$$bundle" ] || continue; \
		cp -R "$$bundle" $(INFER_APP_BUNDLE)/Contents/Resources/; \
	done
	@echo "Built $(INFER_APP_BUNDLE)"

run-infer: bundle-infer
	open $(INFER_APP_BUNDLE)

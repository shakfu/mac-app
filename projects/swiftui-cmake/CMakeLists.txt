# --- C library: mathlib (static) ---
add_library(mathlib STATIC
    Sources/MathLib/mathlib.c
)
target_include_directories(mathlib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/MathLib
)

# --- Swift bridge module ---
add_library(MathBridge STATIC
    Sources/MathBridge/MathBridge.swift
)
target_link_libraries(MathBridge PUBLIC mathlib)

# Generate modulemap with absolute path to the C header
set(MATHLIB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Sources/MathLib")
configure_file(
    Sources/MathBridge/module.modulemap.in
    ${CMAKE_CURRENT_BINARY_DIR}/CMathLib/module.modulemap
    @ONLY
)
set(MODULEMAP_PATH "${CMAKE_CURRENT_BINARY_DIR}/CMathLib/module.modulemap")

target_compile_options(MathBridge PRIVATE
    "SHELL:-Xcc -fmodule-map-file=${MODULEMAP_PATH}"
    "SHELL:-Xcc -I${MATHLIB_INCLUDE_DIR}"
)

# --- TaskRunner library (pure Swift) ---
add_library(TaskRunner STATIC
    Sources/TaskRunner/AppTask.swift
    Sources/TaskRunner/TaskContext.swift
    Sources/TaskRunner/TaskStatus.swift
    Sources/TaskRunner/ManagedTask.swift
    Sources/TaskRunner/TaskManager.swift
)
target_link_libraries(TaskRunner PUBLIC
    "-framework Foundation"
)

# --- SwiftUI app ---
add_executable(MacApp
    Sources/MacApp/MacApp.swift
    Sources/MacApp/ContentView.swift
    Sources/MacApp/TaskManagerView.swift
    Sources/MacApp/Tasks/CountdownTask.swift
    Sources/MacApp/Tasks/FibonacciTask.swift
    Sources/MacApp/Tasks/RandomFailTask.swift
)
target_link_libraries(MacApp PRIVATE MathBridge mathlib TaskRunner)
target_compile_options(MacApp PRIVATE
    "SHELL:-Xcc -fmodule-map-file=${MODULEMAP_PATH}"
    "SHELL:-Xcc -I${MATHLIB_INCLUDE_DIR}"
)

# Link AppKit and SwiftUI frameworks
target_link_libraries(MacApp PRIVATE
    "-framework AppKit"
    "-framework SwiftUI"
)

# Create a .app bundle
set_target_properties(MacApp PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Sources/MacApp/Info.plist"
    MACOSX_BUNDLE_BUNDLE_NAME "MacApp"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.example.macapp"
    MACOSX_BUNDLE_BUNDLE_VERSION "1"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
)

# --- Tests (C-level) ---
add_executable(mathlib_tests
    Tests/MathBridgeTests/mathlib_tests.c
)
target_link_libraries(mathlib_tests PRIVATE mathlib)

add_test(NAME mathlib_tests COMMAND mathlib_tests)

cmake_minimum_required(VERSION 3.25)
project(MacAppPython LANGUAGES C Swift)

set(CMAKE_OSX_DEPLOYMENT_TARGET "14.0" CACHE STRING "Minimum macOS version")

# Python framework location -- passed from the Makefile
set(PY_VER "3.13" CACHE STRING "Python major.minor version")
set(PY_FRAMEWORK_DIR "" CACHE PATH "Directory containing Python.framework")

if(NOT PY_FRAMEWORK_DIR OR NOT EXISTS "${PY_FRAMEWORK_DIR}/Python.framework")
    message(FATAL_ERROR
        "Python.framework not found at '${PY_FRAMEWORK_DIR}/Python.framework'.\n"
        "Run 'make build-python' first, then pass -DPY_FRAMEWORK_DIR=<path>.")
endif()

set(PY_PREFIX "${PY_FRAMEWORK_DIR}/Python.framework/Versions/${PY_VER}")
set(PY_INCLUDE "${PY_PREFIX}/include/python${PY_VER}")

# Shared sources from the sibling cmake project
set(SHARED_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../swiftui-cmake/Sources")

enable_testing()

# --- C library: mathlib (static) ---
add_library(mathlib STATIC
    ${SHARED_SRC}/MathLib/mathlib.c
)
target_include_directories(mathlib PUBLIC
    ${SHARED_SRC}/MathLib
)

# --- Swift bridge module: MathBridge ---
add_library(MathBridge STATIC
    ${SHARED_SRC}/MathBridge/MathBridge.swift
)
target_link_libraries(MathBridge PUBLIC mathlib)

set(MATHLIB_INCLUDE_DIR "${SHARED_SRC}/MathLib")
configure_file(
    ${SHARED_SRC}/MathBridge/module.modulemap.in
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
    ${SHARED_SRC}/TaskRunner/AppTask.swift
    ${SHARED_SRC}/TaskRunner/TaskContext.swift
    ${SHARED_SRC}/TaskRunner/TaskStatus.swift
    ${SHARED_SRC}/TaskRunner/ManagedTask.swift
    ${SHARED_SRC}/TaskRunner/TaskManager.swift
)
target_link_libraries(TaskRunner PUBLIC
    "-framework Foundation"
)

# --- C library: pythonlib (wraps Python C API) ---
add_library(pythonlib STATIC
    Sources/PythonLib/pythonlib.c
)
target_include_directories(pythonlib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/PythonLib
)
target_include_directories(pythonlib PRIVATE
    ${PY_INCLUDE}
)
target_link_libraries(pythonlib PRIVATE
    "-F${PY_FRAMEWORK_DIR}" "-framework Python"
)

# --- Swift bridge module: PythonBridge ---
set(PYTHONLIB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Sources/PythonLib")
configure_file(
    Sources/PythonBridge/module.modulemap.in
    ${CMAKE_CURRENT_BINARY_DIR}/CPythonLib/module.modulemap
    @ONLY
)
set(PYLIB_MODULEMAP "${CMAKE_CURRENT_BINARY_DIR}/CPythonLib/module.modulemap")

add_library(PythonBridge STATIC
    Sources/PythonBridge/PythonBridge.swift
)
target_link_libraries(PythonBridge PUBLIC pythonlib)
target_compile_options(PythonBridge PRIVATE
    "SHELL:-Xcc -fmodule-map-file=${PYLIB_MODULEMAP}"
    "SHELL:-Xcc -I${PYTHONLIB_INCLUDE_DIR}"
)

# --- SwiftUI app ---
add_executable(MacApp
    Sources/MacApp/MacApp.swift
    Sources/MacApp/PythonConsoleView.swift
    ${SHARED_SRC}/MacApp/ContentView.swift
    ${SHARED_SRC}/MacApp/TaskManagerView.swift
    ${SHARED_SRC}/MacApp/Tasks/CountdownTask.swift
    ${SHARED_SRC}/MacApp/Tasks/FibonacciTask.swift
    ${SHARED_SRC}/MacApp/Tasks/RandomFailTask.swift
)
target_link_libraries(MacApp PRIVATE
    MathBridge mathlib TaskRunner PythonBridge pythonlib
)
target_link_libraries(MacApp PRIVATE
    "-framework AppKit"
    "-framework SwiftUI"
    "-F${PY_FRAMEWORK_DIR}" "-framework Python"
)
target_compile_options(MacApp PRIVATE
    "SHELL:-Xcc -fmodule-map-file=${MODULEMAP_PATH}"
    "SHELL:-Xcc -I${MATHLIB_INCLUDE_DIR}"
    "SHELL:-Xcc -fmodule-map-file=${PYLIB_MODULEMAP}"
    "SHELL:-Xcc -I${PYTHONLIB_INCLUDE_DIR}"
)

# Create a .app bundle
set_target_properties(MacApp PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Sources/MacApp/Info.plist"
    MACOSX_BUNDLE_BUNDLE_NAME "MacApp Python"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.example.macapp-python"
    MACOSX_BUNDLE_BUNDLE_VERSION "1"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
    BUILD_RPATH "${PY_FRAMEWORK_DIR};@executable_path/../Frameworks"
)

# --- Tests (C-level) ---
add_executable(mathlib_tests
    ${SHARED_SRC}/../Tests/MathBridgeTests/mathlib_tests.c
)
target_link_libraries(mathlib_tests PRIVATE mathlib)

add_test(NAME mathlib_tests COMMAND mathlib_tests)

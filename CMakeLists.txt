cmake_minimum_required(VERSION 3.25)
project(MacAppWorkspace LANGUAGES C Swift)

set(CMAKE_OSX_DEPLOYMENT_TARGET "14.0" CACHE STRING "Minimum macOS version")

enable_testing()

add_subdirectory(projects/swiftui-cmake)

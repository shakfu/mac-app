# --- Infer.app: SwiftUI chat app backed by llama.framework ---

set(LLAMA_FRAMEWORK_DIR "${CMAKE_SOURCE_DIR}/thirdparty")
set(LLAMA_FRAMEWORK_PATH "${LLAMA_FRAMEWORK_DIR}/llama.framework")

if(NOT EXISTS "${LLAMA_FRAMEWORK_PATH}")
    message(FATAL_ERROR "llama.framework not found at ${LLAMA_FRAMEWORK_PATH}")
endif()

add_executable(Infer
    Sources/Infer/InferApp.swift
    Sources/Infer/ChatView.swift
    Sources/Infer/LlamaRunner.swift
)

# Swift needs -F to resolve the `import llama` module via the framework's modulemap.
target_compile_options(Infer PRIVATE "-F${LLAMA_FRAMEWORK_DIR}")

target_link_libraries(Infer PRIVATE
    "-F${LLAMA_FRAMEWORK_DIR}"
    "-framework llama"
    "-framework AppKit"
    "-framework SwiftUI"
    "-framework Foundation"
)

target_link_options(Infer PRIVATE
    "SHELL:-Xlinker -rpath -Xlinker @executable_path/../Frameworks"
)

set_target_properties(Infer PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Sources/Infer/Info.plist"
    MACOSX_BUNDLE_BUNDLE_NAME "Infer"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.example.infer"
    MACOSX_BUNDLE_BUNDLE_VERSION "1"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
)

# Embed llama.framework into Infer.app/Contents/Frameworks.
add_custom_command(TARGET Infer POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_BUNDLE_CONTENT_DIR:Infer>/Frameworks"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${LLAMA_FRAMEWORK_PATH}"
        "$<TARGET_BUNDLE_CONTENT_DIR:Infer>/Frameworks/llama.framework"
    COMMENT "Embedding llama.framework into Infer.app"
    VERBATIM
)

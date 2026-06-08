cmake_minimum_required(VERSION 3.15)

project(serenova LANGUAGES CXX)

# Define the application binary name (used by windows/runner/CMakeLists.txt)
set(BINARY_NAME "serenova" CACHE STRING "Application binary name")

# Optional: set where Flutter-managed CMake lives (only if present)
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# If the Flutter-managed dir exists, add it first so it can create the 'flutter' / helpers.
if(EXISTS "${FLUTTER_MANAGED_DIR}/CMakeLists.txt")
  add_subdirectory(${FLUTTER_MANAGED_DIR})
endif()

# Now add the runner (this creates the ${BINARY_NAME} target)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/windows/runner/CMakeLists.txt")
  add_subdirectory("windows/runner")
else()
  message(FATAL_ERROR "windows/runner/CMakeLists.txt not found. Ensure you are in the Flutter project root.")
endif()

# After the runner target (serenova) exists, include generated plugin wiring.
# The generated_plugins.cmake performs target_link_libraries(${BINARY_NAME} ...).
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/flutter/generated_plugins.cmake")
  include("${CMAKE_CURRENT_SOURCE_DIR}/flutter/generated_plugins.cmake")
endif()

# Optional install/run-from-build support (kept minimal)
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

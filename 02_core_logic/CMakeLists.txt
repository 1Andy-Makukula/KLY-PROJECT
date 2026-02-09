# =============================================================================
# KithLy Global Protocol - LAYER 2: THE BRAIN (C++23)
# CMakeLists.txt - Build Configuration
# =============================================================================

cmake_minimum_required(VERSION 3.20)
project(kithly_core VERSION 1.0.0 LANGUAGES CXX)

# Require C++23
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler flags
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(-Wall -Wextra -Wpedantic -O2)
endif()

# Find required packages
find_package(PostgreSQL REQUIRED)
find_package(Threads REQUIRED)

# Optional: gRPC for high-performance RPC
# find_package(gRPC CONFIG)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${PostgreSQL_INCLUDE_DIRS}
)

# Source files
set(CORE_SOURCES
    src/main.cpp
    src/orchestrator/state_machine.cpp
    src/routing/proximity.cpp
    src/idempotency/guard.cpp
)

# Main executable
add_executable(kithly_core ${CORE_SOURCES})

target_link_libraries(kithly_core
    ${PostgreSQL_LIBRARIES}
    Threads::Threads
)

# Tests (using Google Test)
option(BUILD_TESTS "Build unit tests" ON)

if(BUILD_TESTS)
    enable_testing()
    find_package(GTest)
    
    if(GTest_FOUND)
        add_executable(kithly_tests
            tests/test_state_machine.cpp
            tests/test_proximity.cpp
            tests/test_idempotency.cpp
        )
        
        target_link_libraries(kithly_tests
            GTest::gtest_main
            ${PostgreSQL_LIBRARIES}
            Threads::Threads
        )
        
        include(GoogleTest)
        gtest_discover_tests(kithly_tests)
    endif()
endif()

# Installation
install(TARGETS kithly_core
    RUNTIME DESTINATION bin
)

install(DIRECTORY include/
    DESTINATION include/kithly
)

# Print configuration summary
message(STATUS "")
message(STATUS "=============================================")
message(STATUS " KithLy Core Engine Configuration")
message(STATUS "=============================================")
message(STATUS " C++ Standard:    ${CMAKE_CXX_STANDARD}")
message(STATUS " PostgreSQL:      ${PostgreSQL_VERSION_STRING}")
message(STATUS " Build Type:      ${CMAKE_BUILD_TYPE}")
message(STATUS " Build Tests:     ${BUILD_TESTS}")
message(STATUS "=============================================")
message(STATUS "")

cmake_minimum_required(VERSION 3.10)
project(NetLedger VERSION 0.1.0 LANGUAGES CXX)

# ——————————————————————————————
# 1) C++ Standard
set(CMAKE_CXX_STANDARD       17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS     OFF)

option(BUILD_TESTS "Build NetLedger unit tests" ON)

# ——————————————————————————————
# 2) Dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(PCAP REQUIRED libpcap)

find_package(nlohmann_json 3.2.0 REQUIRED)

if (BUILD_TESTS)
  find_package(GTest REQUIRED)
endif()

# ——————————————————————————————
# 3) Source Files
set(SRC_ROOT "${CMAKE_SOURCE_DIR}/src")

file(GLOB_RECURSE NETLEDGER_SOURCES
  "${SRC_ROOT}/*.cpp"
)

file(GLOB_RECURSE NETLEDGER_HEADERS
  "${SRC_ROOT}/*.hpp"
)

# ——————————————————————————————
# 4) netledger_lib Library Target
add_library(netledger_lib STATIC
  ${NETLEDGER_SOURCES}
  ${NETLEDGER_HEADERS}
)

target_include_directories(netledger_lib
  PUBLIC
    "${SRC_ROOT}"
    ${PCAP_INCLUDE_DIRS}
)

target_link_libraries(netledger_lib
  PUBLIC
    ${PCAP_LIBRARIES}
    nlohmann_json::nlohmann_json
)

# ——————————————————————————————
# 5) netledger Executable
add_executable(netledger
  "${SRC_ROOT}/main.cpp"
)

target_link_libraries(netledger
  PRIVATE netledger_lib
)

# ——————————————————————————————
# 6) Tests (if enabled)
if (BUILD_TESTS)
  enable_testing()
  add_executable(netledger_test
    "tests/netledger_test.cc"
  )
  target_link_libraries(netledger_test
    PRIVATE
      netledger_lib
      GTest::gtest_main
  )
  include(GoogleTest)
  gtest_discover_tests(netledger_test)
endif()

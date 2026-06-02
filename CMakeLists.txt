cmake_minimum_required(VERSION 3.16)
project(pluginplayground C OBJC)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CODESIGN_IDENTITY "-" CACHE STRING "Codesign identity (default: ad-hoc)")
set(INSTALL_PREFIX "/opt/pluginplayground" CACHE PATH "Installation prefix")

function(syphon_codesign target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND codesign -f -s "${CODESIGN_IDENTITY}"
                --entitlements "${CMAKE_SOURCE_DIR}/Master.entitlements"
                --timestamp=none
                $<TARGET_FILE:${target}>
        COMMENT "codesigning ${target} (identity: ${CODESIGN_IDENTITY})"
    )
endfunction()

# ── Core library ──────────────────────────────────────────────
add_library(syphon STATIC
    syphon/target.c
    syphon/stepping.c
    syphon/breakpoint.c
    syphon/mach_exc.c
    syphon/process.c
    syphon/exe.c
)

target_include_directories(syphon PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/syphon>
    $<INSTALL_INTERFACE:include/syphon>
)
target_link_libraries(syphon PUBLIC
    "-framework CoreFoundation"
    "-framework Security"
)

# ── Tracers (add new executables here) ────────────────────────
add_executable(fangs syphon/main.c)
target_link_libraries(fangs PRIVATE syphon)
syphon_codesign(fangs)

# ── Privilege grant tool (amfid hook + fangs launcher) ────────
add_executable(grant
    grant/amfid_handler.m
    grant/main.m
)
target_include_directories(grant PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/grant")
target_link_libraries(grant PRIVATE
    "-framework Foundation"
)

# ── Install ──────────────────────────────────────────────────
install(TARGETS fangs grant RUNTIME DESTINATION bin)

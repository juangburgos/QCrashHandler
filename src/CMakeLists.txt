cmake_minimum_required(VERSION 3.16)

project(QCrashHandler
    VERSION 1.1
    LANGUAGES C CXX
)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

if(NOT DEFINED QT_VERSION_MAJOR)
    find_package(QT NAMES Qt5 Qt6 REQUIRED COMPONENTS Core)
endif()

find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core)

add_library(${PROJECT_NAME} qcrashhandler.cpp qcrashhandler.h)

target_include_directories(${PROJECT_NAME} PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}
    ../deps/breakpad.git/src
)

target_link_libraries(${PROJECT_NAME} PRIVATE Qt::Core)

if(WIN32)
    target_sources(${PROJECT_NAME} PUBLIC
        ../deps/breakpad.git/src/client/windows/common/ipc_protocol.h
        ../deps/breakpad.git/src/client/windows/crash_generation/crash_generation_client.cc
        ../deps/breakpad.git/src/client/windows/crash_generation/crash_generation_client.h
        ../deps/breakpad.git/src/client/windows/handler/exception_handler.cc
        ../deps/breakpad.git/src/client/windows/handler/exception_handler.h
        ../deps/breakpad.git/src/common/scoped_ptr.h
        ../deps/breakpad.git/src/common/windows/guid_string.cc
        ../deps/breakpad.git/src/common/windows/guid_string.h
        ../deps/breakpad.git/src/common/windows/string_utils.cc
        ../deps/breakpad.git/src/common/windows/string_utils-inl.h
        ../deps/breakpad.git/src/google_breakpad/common/breakpad_types.h
        ../deps/breakpad.git/src/google_breakpad/common/minidump_format.h
    )
endif(WIN32)

if(UNIX)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/../deps/linux_syscall.git/linux_syscall_support.h
        ${CMAKE_CURRENT_LIST_DIR}/../deps/breakpad.git/src/third_party/lss/linux_syscall_support.h
        COPYONLY
    )

    target_sources(${PROJECT_NAME} PUBLIC
        ../deps/breakpad.git/src/client/linux/crash_generation/crash_generation_client.cc
        ../deps/breakpad.git/src/client/linux/crash_generation/crash_generation_client.h
        ../deps/breakpad.git/src/client/linux/dump_writer_common/mapping_info.h
        ../deps/breakpad.git/src/client/linux/dump_writer_common/raw_context_cpu.h
        ../deps/breakpad.git/src/client/linux/dump_writer_common/thread_info.cc
        ../deps/breakpad.git/src/client/linux/dump_writer_common/thread_info.h
        ../deps/breakpad.git/src/client/linux/dump_writer_common/ucontext_reader.cc
        ../deps/breakpad.git/src/client/linux/dump_writer_common/ucontext_reader.h
        ../deps/breakpad.git/src/client/linux/handler/exception_handler.cc
        ../deps/breakpad.git/src/client/linux/handler/exception_handler.h
        ../deps/breakpad.git/src/client/linux/handler/minidump_descriptor.cc
        ../deps/breakpad.git/src/client/linux/handler/minidump_descriptor.h
        ../deps/breakpad.git/src/client/linux/log/log.cc
        ../deps/breakpad.git/src/client/linux/log/log.h
        ../deps/breakpad.git/src/client/linux/microdump_writer/microdump_writer.cc
        ../deps/breakpad.git/src/client/linux/microdump_writer/microdump_writer.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/cpu_set.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/directory_reader.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/line_reader.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/linux_dumper.cc
        ../deps/breakpad.git/src/client/linux/minidump_writer/linux_dumper.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/linux_ptrace_dumper.cc
        ../deps/breakpad.git/src/client/linux/minidump_writer/linux_ptrace_dumper.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/minidump_writer.cc
        ../deps/breakpad.git/src/client/linux/minidump_writer/minidump_writer.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/pe_file.cc
        ../deps/breakpad.git/src/client/linux/minidump_writer/pe_file.h
        ../deps/breakpad.git/src/client/linux/minidump_writer/proc_cpuinfo_reader.h
        ../deps/breakpad.git/src/client/minidump_file_writer.cc
        ../deps/breakpad.git/src/client/minidump_file_writer.h
        ../deps/breakpad.git/src/client/minidump_file_writer-inl.h
        ../deps/breakpad.git/src/common/basictypes.h
        ../deps/breakpad.git/src/common/convert_UTF.cc
        ../deps/breakpad.git/src/common/convert_UTF.h
        ../deps/breakpad.git/src/common/linux/breakpad_getcontext.h
        ../deps/breakpad.git/src/common/linux/breakpad_getcontext.S
        ../deps/breakpad.git/src/common/linux/eintr_wrapper.h
        ../deps/breakpad.git/src/common/linux/elf_gnu_compat.h
        ../deps/breakpad.git/src/common/linux/elfutils.cc
        ../deps/breakpad.git/src/common/linux/elfutils.h
        ../deps/breakpad.git/src/common/linux/elfutils-inl.h
        ../deps/breakpad.git/src/common/linux/file_id.cc
        ../deps/breakpad.git/src/common/linux/file_id.h
        ../deps/breakpad.git/src/common/linux/guid_creator.cc
        ../deps/breakpad.git/src/common/linux/guid_creator.h
        ../deps/breakpad.git/src/common/linux/ignore_ret.h
        ../deps/breakpad.git/src/common/linux/linux_libc_support.cc
        ../deps/breakpad.git/src/common/linux/linux_libc_support.h
        ../deps/breakpad.git/src/common/linux/memory_mapped_file.cc
        ../deps/breakpad.git/src/common/linux/memory_mapped_file.h
        ../deps/breakpad.git/src/common/linux/safe_readlink.cc
        ../deps/breakpad.git/src/common/linux/safe_readlink.h
        ../deps/breakpad.git/src/common/memory_range.h
        ../deps/breakpad.git/src/common/scoped_ptr.h
        ../deps/breakpad.git/src/common/string_conversion.cc
        ../deps/breakpad.git/src/common/string_conversion.h
        ../deps/breakpad.git/src/common/using_std_string.h
        ../deps/breakpad.git/src/google_breakpad/common/breakpad_types.h
        ../deps/breakpad.git/src/google_breakpad/common/minidump_format.h
        ../deps/breakpad.git/src/google_breakpad/common/minidump_size.h
        ../deps/breakpad.git/src/third_party/lss/linux_syscall_support.h
    )
endif(UNIX)

if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug" AND NOT CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    message(WARNING "Current build type is \"${CMAKE_BUILD_TYPE}\". Please select \"Debug\" or \"RelWithDebInfo\" build type.")
endif()

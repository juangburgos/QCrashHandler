HEADERS += $$PWD/qcrashhandler.h
SOURCES += $$PWD/qcrashhandler.cpp
 
INCLUDEPATH += $$PWD
INCLUDEPATH += $$PWD/../deps/breakpad.git/src

# windows
win32 {
	# headers
	HEADERS += \
	$$PWD/../deps/breakpad.git/src/common/windows/string_utils-inl.h \
	$$PWD/../deps/breakpad.git/src/common/windows/guid_string.h \
	$$PWD/../deps/breakpad.git/src/client/windows/handler/exception_handler.h \
	$$PWD/../deps/breakpad.git/src/client/windows/common/ipc_protocol.h \
	$$PWD/../deps/breakpad.git/src/google_breakpad/common/minidump_format.h \
	$$PWD/../deps/breakpad.git/src/google_breakpad/common/breakpad_types.h \
	$$PWD/../deps/breakpad.git/src/client/windows/crash_generation/crash_generation_client.h \
	$$PWD/../deps/breakpad.git/src/common/scoped_ptr.h
	# source
	SOURCES += \
	$$PWD/../deps/breakpad.git/src/client/windows/handler/exception_handler.cc \
	$$PWD/../deps/breakpad.git/src/common/windows/string_utils.cc \
	$$PWD/../deps/breakpad.git/src/common/windows/guid_string.cc \
	$$PWD/../deps/breakpad.git/src/client/windows/crash_generation/crash_generation_client.cc
}

# linux
linux-g++ {
	# copy linux syscall support dependency
	!build_pass {
		LINUX_SYSCALL_SRC = $$PWD/../deps/linux_syscall.git/linux_syscall_support.h
		LINUX_SYSCALL_TARG_PATH = $$PWD/../deps/breakpad.git/src/third_party/lss
		LINUX_SYSCALL_TARG = $$LINUX_SYSCALL_TARG_PATH/linux_syscall_support.h
		!exists($${LINUX_SYSCALL_TARG_PATH}) {
			system("mkdir $${LINUX_SYSCALL_TARG_PATH}")
			message("Created directory $${LINUX_SYSCALL_TARG_PATH}")
		}
		# always copy file
		LS_COPY = FALSE
		system("yes | cp -rf $${LINUX_SYSCALL_SRC} $${LINUX_SYSCALL_TARG}"): LS_COPY = TRUE
		equals(LS_COPY, TRUE) {
			message("Copied $${LINUX_SYSCALL_TARG}.")
		}
		else {
			error("Failed to copy linux syscall header file $${LINUX_SYSCALL_TARG}.")
		}
	}
	# headers
	HEADERS += \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/cpu_set.h \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/proc_cpuinfo_reader.h \
	$$PWD/../deps/breakpad.git/src/client/linux/handler/exception_handler.h \
	$$PWD/../deps/breakpad.git/src/client/linux/crash_generation/crash_generation_client.h \
	$$PWD/../deps/breakpad.git/src/client/linux/handler/minidump_descriptor.h \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/minidump_writer.h \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/line_reader.h \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/linux_dumper.h \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/linux_ptrace_dumper.h \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/directory_reader.h \
        $$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/pe_file.h \
	$$PWD/../deps/breakpad.git/src/client/linux/log/log.h \
	$$PWD/../deps/breakpad.git/src/client/minidump_file_writer-inl.h \
	$$PWD/../deps/breakpad.git/src/client/minidump_file_writer.h \
	$$PWD/../deps/breakpad.git/src/common/linux/linux_libc_support.h \
	$$PWD/../deps/breakpad.git/src/common/linux/eintr_wrapper.h \
	$$PWD/../deps/breakpad.git/src/common/linux/ignore_ret.h \
	$$PWD/../deps/breakpad.git/src/common/linux/file_id.h \
	$$PWD/../deps/breakpad.git/src/common/linux/memory_mapped_file.h \
	$$PWD/../deps/breakpad.git/src/common/linux/safe_readlink.h \
	$$PWD/../deps/breakpad.git/src/common/linux/guid_creator.h \
	$$PWD/../deps/breakpad.git/src/common/linux/elfutils.h \
	$$PWD/../deps/breakpad.git/src/common/linux/elfutils-inl.h \
	$$PWD/../deps/breakpad.git/src/common/linux/elf_gnu_compat.h \
	$$PWD/../deps/breakpad.git/src/common/using_std_string.h \
	$$PWD/../deps/breakpad.git/src/common/basictypes.h \
	$$PWD/../deps/breakpad.git/src/common/memory_range.h \
	$$PWD/../deps/breakpad.git/src/common/string_conversion.h \
	$$PWD/../deps/breakpad.git/src/common/convert_UTF.h \
	$$PWD/../deps/breakpad.git/src/google_breakpad/common/minidump_format.h \
	$$PWD/../deps/breakpad.git/src/google_breakpad/common/minidump_size.h \
	$$PWD/../deps/breakpad.git/src/google_breakpad/common/breakpad_types.h \
	$$PWD/../deps/breakpad.git/src/common/scoped_ptr.h \
	$$PWD/../deps/breakpad.git/src/third_party/lss/linux_syscall_support.h \
	$$PWD/../deps/breakpad.git/src/client/linux/dump_writer_common/mapping_info.h \
	$$PWD/../deps/breakpad.git/src/client/linux/dump_writer_common/raw_context_cpu.h \
	$$PWD/../deps/breakpad.git/src/client/linux/dump_writer_common/thread_info.h \
	$$PWD/../deps/breakpad.git/src/client/linux/dump_writer_common/ucontext_reader.h \
	$$PWD/../deps/breakpad.git/src/client/linux/microdump_writer/microdump_writer.h
	# source
	SOURCES += \
	$$PWD/../deps/breakpad.git/src/client/linux/crash_generation/crash_generation_client.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/handler/exception_handler.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/handler/minidump_descriptor.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/minidump_writer.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/linux_dumper.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/linux_ptrace_dumper.cc \
        $$PWD/../deps/breakpad.git/src/client/linux/minidump_writer/pe_file.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/log/log.cc \
	$$PWD/../deps/breakpad.git/src/client/minidump_file_writer.cc \
	$$PWD/../deps/breakpad.git/src/common/linux/linux_libc_support.cc \
	$$PWD/../deps/breakpad.git/src/common/linux/file_id.cc \
	$$PWD/../deps/breakpad.git/src/common/linux/memory_mapped_file.cc \
	$$PWD/../deps/breakpad.git/src/common/linux/safe_readlink.cc \
	$$PWD/../deps/breakpad.git/src/common/linux/guid_creator.cc \
	$$PWD/../deps/breakpad.git/src/common/linux/elfutils.cc \
	$$PWD/../deps/breakpad.git/src/common/linux/breakpad_getcontext.S \
	$$PWD/../deps/breakpad.git/src/common/string_conversion.cc \
	$$PWD/../deps/breakpad.git/src/common/convert_UTF.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/dump_writer_common/thread_info.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/dump_writer_common/ucontext_reader.cc \
	$$PWD/../deps/breakpad.git/src/client/linux/microdump_writer/microdump_writer.cc
}

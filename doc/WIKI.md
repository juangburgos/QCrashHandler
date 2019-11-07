 * [Introduction](#introduction)
  * [Integration into the Qt application](#integration-into-the-qt-application)
  * [Exporting the application's symbols](#exporting-the-applications-symbols)
    + [Windows](#windows)
    + [Linux](#linux)
  * [Analyzing the minidump](#analyzing-the-minidump)
    + [Windows](#windows-1)
    + [Linux](#linux-1)
  * [General Notes](#general-notes)


## Introduction

Google Breakpad is a cross platform crash handler which generates minidumps when your application crash. Users can send these minidumps to you and it contains valuable information allowing you to figure out why it crashed on them. More information on the [Google Breakpad](https://chromium.googlesource.com/breakpad/breakpad/) project page.

This page contains notes I made while implementing a Google Breakpad based crash handler for a Qt 5.1.1 C++ application. The implementation was done and tested on both Windows 7 (MSVC Express 2010) and Linux (Ubuntu 12.0.4 and CentOs 5.6) using SVN revision 1281 of the Google Breakpad repository.

The implementation is roughly based on [this blog post](http://blog.inventic.eu/2012/08/qt-and-google-breakpad/) so its a good reference to fall back to if this page is unclear. All references to other operating systems were removed (Mac etc.).

If something is wrong in the article or if I am not understanding something correctly, please file a bug against this article or feel free to edit the wiki page. 

## Integration into the Qt application

* Svn checkout the Google Breakpad sources:

`svn checkout http://google-breakpad.googlecode.com/svn/trunk/ google-breakpad-read-only`

* Create a directory called `crashhandler` in your application's source directory. 
* Create a new class called `CrashHandler` in this directory. The header and source file contents looks like this:

`crash_handler.h`
```C++
#pragma once
#include <QtCore/QString>
 
namespace Breakpad {
    class CrashHandlerPrivate;
    class CrashHandler
    {
    public:
        static CrashHandler* instance();
    void Init(const QString&  reportPath);
    
        void setReportCrashesToSystem(bool report);
        bool writeMinidump();
    
    private:
        CrashHandler();
        ~CrashHandler();
        Q_DISABLE_COPY(CrashHandler)
        CrashHandlerPrivate* d;
    };
}
```

`crash_handler.cpp`
```C++
#include "crash_handler.h"
#include <QtCore/QDir>
#include <QtCore/QProcess>
#include <QtCore/QCoreApplication>
#include <QString>
 
#if defined(Q_OS_LINUX)
#include "client/linux/handler/exception_handler.h"
#elif defined(Q_OS_WIN32)
#include "client/windows/handler/exception_handler.h"
#endif
 
namespace Breakpad {
    /************************************************************************/
    /* CrashHandlerPrivate                                                  */
    /************************************************************************/
    class CrashHandlerPrivate
    {
    public:
        CrashHandlerPrivate()
        {
            pHandler = NULL;
        }
 
        ~CrashHandlerPrivate()
        {
            delete pHandler;
        }
 
        void InitCrashHandler(const QString& dumpPath);
        static google_breakpad::ExceptionHandler* pHandler;
        static bool bReportCrashesToSystem;
    };
 
    google_breakpad::ExceptionHandler* CrashHandlerPrivate::pHandler = NULL;
    bool CrashHandlerPrivate::bReportCrashesToSystem = false;
 
    /************************************************************************/
    /* DumpCallback                                                         */
    /************************************************************************/
#if defined(Q_OS_WIN32)
    bool DumpCallback(const wchar_t* _dump_dir,const wchar_t* _minidump_id,void* context,EXCEPTION_POINTERS* exinfo,MDRawAssertionInfo* assertion,bool success)
#elif defined(Q_OS_LINUX)
    bool DumpCallback(const google_breakpad::MinidumpDescriptor &md,void *context, bool success)
#endif
    {
        Q_UNUSED(context);
#if defined(Q_OS_WIN32)
        Q_UNUSED(_dump_dir);
        Q_UNUSED(_minidump_id);
        Q_UNUSED(assertion);
        Q_UNUSED(exinfo);
#endif
        qDebug("BreakpadQt crash");
 
        /*
        NO STACK USE, NO HEAP USE THERE !!!
        Creating QString's, using qDebug, etc. - everything is crash-unfriendly.
        */
        return CrashHandlerPrivate::bReportCrashesToSystem ? success : true;
    }
 
    void CrashHandlerPrivate::InitCrashHandler(const QString& dumpPath)
    {
        if ( pHandler != NULL )
            return;
 
#if defined(Q_OS_WIN32)
        std::wstring pathAsStr = (const wchar_t*)dumpPath.utf16();
        pHandler = new google_breakpad::ExceptionHandler(
            pathAsStr,
            /*FilterCallback*/ 0,
            DumpCallback,
            /*context*/
            0,
            true
            );
#elif defined(Q_OS_LINUX)
        std::string pathAsStr = dumpPath.toStdString();
        google_breakpad::MinidumpDescriptor md(pathAsStr);
        pHandler = new google_breakpad::ExceptionHandler(
            md,
            /*FilterCallback*/ 0,
            DumpCallback,
            /*context*/ 0,
            true,
            -1
            );
#endif
    }
 
    /************************************************************************/
    /* CrashHandler                                                         */
    /************************************************************************/
    CrashHandler* CrashHandler::instance()
    {
        static CrashHandler globalHandler;
        return &globalHandler;
    }
 
    CrashHandler::CrashHandler()
    {
        d = new CrashHandlerPrivate();
    }
 
    CrashHandler::~CrashHandler()
    {
        delete d;
    }
 
    void CrashHandler::setReportCrashesToSystem(bool report)
    {
        d->bReportCrashesToSystem = report;
    }
 
    bool CrashHandler::writeMinidump()
    {
        bool res = d->pHandler->WriteMinidump();
        if (res) {
            qDebug("BreakpadQt: writeMinidump() success.");
        } else {
            qWarning("BreakpadQt: writeMinidump() failed.");
        }
        return res;
    }
 
    void CrashHandler::Init( const QString& reportPath )
    {
        d->InitCrashHandler(reportPath);
    }
}
```

* Create a new .pri file for the required files in this directory. I did not explore the other ways of building breakpad on its own. Instead just adding the required files to a .pri and then adding this .pri to the Qt application proved very easy and clean. Note that more required files will probably be needed for other platform which I did not test, but any missing files can easily be added. The resulting pri looks like this:

```
# ***************************************************************************
# Implemented using http://blog.inventic.eu/2012/08/qt-and-google-breakpad/
# as a the reference.
#
# Get Google Breakpad here: https://code.google.com/p/google-breakpad/
#
# The required breakpad sources have been copied into /src in order to make
# integration with the application smooth and easy.
#
# To use source from Google Breakpad SVN checkout instead, change $$PWD/src
# to path where it was checked out. 
#
# ***************************************************************************

HEADERS += $$PWD/crash_handler.h
SOURCES += $$PWD/crash_handler.cpp
 
INCLUDEPATH += $$PWD
INCLUDEPATH += $$PWD/src

# Windows
win32:HEADERS += $$PWD/src/common/windows/string_utils-inl.h
win32:HEADERS += $$PWD/src/common/windows/guid_string.h
win32:HEADERS += $$PWD/src/client/windows/handler/exception_handler.h
win32:HEADERS += $$PWD/src/client/windows/common/ipc_protocol.h
win32:HEADERS += $$PWD/src/google_breakpad/common/minidump_format.h
win32:HEADERS += $$PWD/src/google_breakpad/common/breakpad_types.h
win32:HEADERS += $$PWD/src/client/windows/crash_generation/crash_generation_client.h
win32:HEADERS += $$PWD/src/common/scoped_ptr.h
win32:SOURCES += $$PWD/src/client/windows/handler/exception_handler.cc
win32:SOURCES += $$PWD/src/common/windows/string_utils.cc
win32:SOURCES += $$PWD/src/common/windows/guid_string.cc
win32:SOURCES += $$PWD/src/client/windows/crash_generation/crash_generation_client.cc

# Linux
unix:HEADERS += $$PWD/src/client/linux/minidump_writer/cpu_set.h
unix:HEADERS += $$PWD/src/client/linux/minidump_writer/proc_cpuinfo_reader.h
unix:HEADERS += $$PWD/src/client/linux/handler/exception_handler.h
unix:HEADERS += $$PWD/src/client/linux/crash_generation/crash_generation_client.h
unix:HEADERS += $$PWD/src/client/linux/handler/minidump_descriptor.h
unix:HEADERS += $$PWD/src/client/linux/minidump_writer/minidump_writer.h
unix:HEADERS += $$PWD/src/client/linux/minidump_writer/line_reader.h
unix:HEADERS += $$PWD/src/client/linux/minidump_writer/linux_dumper.h
unix:HEADERS += $$PWD/src/client/linux/minidump_writer/linux_ptrace_dumper.h
unix:HEADERS += $$PWD/src/client/linux/minidump_writer/directory_reader.h
unix:HEADERS += $$PWD/src/client/linux/log/log.h
unix:HEADERS += $$PWD/src/client/minidump_file_writer-inl.h
unix:HEADERS += $$PWD/src/client/minidump_file_writer.h
unix:HEADERS += $$PWD/src/common/linux/linux_libc_support.h
unix:HEADERS += $$PWD/src/common/linux/eintr_wrapper.h
unix:HEADERS += $$PWD/src/common/linux/ignore_ret.h
unix:HEADERS += $$PWD/src/common/linux/file_id.h
unix:HEADERS += $$PWD/src/common/linux/memory_mapped_file.h
unix:HEADERS += $$PWD/src/common/linux/safe_readlink.h
unix:HEADERS += $$PWD/src/common/linux/guid_creator.h
unix:HEADERS += $$PWD/src/common/linux/elfutils.h
unix:HEADERS += $$PWD/src/common/linux/elfutils-inl.h
unix:HEADERS += $$PWD/src/common/linux/elf_gnu_compat.h
unix:HEADERS += $$PWD/src/common/using_std_string.h
unix:HEADERS += $$PWD/src/common/memory.h
unix:HEADERS += $$PWD/src/common/basictypes.h
unix:HEADERS += $$PWD/src/common/memory_range.h
unix:HEADERS += $$PWD/src/common/string_conversion.h
unix:HEADERS += $$PWD/src/common/convert_UTF.h
unix:HEADERS += $$PWD/src/google_breakpad/common/minidump_format.h
unix:HEADERS += $$PWD/src/google_breakpad/common/minidump_size.h
unix:HEADERS += $$PWD/src/google_breakpad/common/breakpad_types.h
unix:HEADERS += $$PWD/src/common/scoped_ptr.h
unix:HEADERS += $$PWD/src/third_party/lss/linux_syscall_support.h
unix:SOURCES += $$PWD/src/client/linux/crash_generation/crash_generation_client.cc
unix:SOURCES += $$PWD/src/client/linux/handler/exception_handler.cc
unix:SOURCES += $$PWD/src/client/linux/handler/minidump_descriptor.cc
unix:SOURCES += $$PWD/src/client/linux/minidump_writer/minidump_writer.cc
unix:SOURCES += $$PWD/src/client/linux/minidump_writer/linux_dumper.cc
unix:SOURCES += $$PWD/src/client/linux/minidump_writer/linux_ptrace_dumper.cc
unix:SOURCES += $$PWD/src/client/linux/log/log.cc
unix:SOURCES += $$PWD/src/client/minidump_file_writer.cc
unix:SOURCES += $$PWD/src/common/linux/linux_libc_support.cc
unix:SOURCES += $$PWD/src/common/linux/file_id.cc
unix:SOURCES += $$PWD/src/common/linux/memory_mapped_file.cc
unix:SOURCES += $$PWD/src/common/linux/safe_readlink.cc
unix:SOURCES += $$PWD/src/common/linux/guid_creator.cc
unix:SOURCES += $$PWD/src/common/linux/elfutils.cc
unix:SOURCES += $$PWD/src/common/string_conversion.cc
unix:SOURCES += $$PWD/src/common/convert_UTF.c
#breakpad app need debug info inside binaries
unix:QMAKE_CXXFLAGS+=-g
```

* (Optional) If you prefer to check the breakpad sources into your main code repository to make building on multiple machines easier, only the above files are required instead of checking in everything contained in the breakpad repository. The tree under our _crashhandler _directory should look like this:

```
.
├── crash_handler.cpp
├── crash_handler.h
├── crash_handler.pri
└── src
    ├── client
    │   ├── linux
    │   │   ├── crash_generation
    │   │   │   ├── crash_generation_client.cc
    │   │   │   └── crash_generation_client.h
    │   │   ├── handler
    │   │   │   ├── exception_handler.cc
    │   │   │   ├── exception_handler.h
    │   │   │   ├── minidump_descriptor.cc
    │   │   │   └── minidump_descriptor.h
    │   │   ├── log
    │   │   │   ├── log.cc
    │   │   │   └── log.h
    │   │   └── minidump_writer
    │   │       ├── cpu_set.h
    │   │       ├── directory_reader.h
    │   │       ├── line_reader.h
    │   │       ├── linux_dumper.cc
    │   │       ├── linux_dumper.h
    │   │       ├── linux_ptrace_dumper.cc
    │   │       ├── linux_ptrace_dumper.h
    │   │       ├── minidump_writer.cc
    │   │       ├── minidump_writer.h
    │   │       └── proc_cpuinfo_reader.h
    │   ├── minidump_file_writer.cc
    │   ├── minidump_file_writer.h
    │   ├── minidump_file_writer-inl.h
    │   └── windows
    │       ├── common
    │       │   ├── auto_critical_section.h
    │       │   └── ipc_protocol.h
    │       ├── crash_generation
    │       │   ├── crash_generation_client.cc
    │       │   └── crash_generation_client.h
    │       └── handler
    │           ├── exception_handler.cc
    │           └── exception_handler.h
    ├── common
    │   ├── basictypes.h
    │   ├── convert_UTF.c
    │   ├── convert_UTF.h
    │   ├── linux
    │   │   ├── eintr_wrapper.h
    │   │   ├── elf_gnu_compat.h
    │   │   ├── elfutils.cc
    │   │   ├── elfutils.h
    │   │   ├── elfutils-inl.h
    │   │   ├── file_id.cc
    │   │   ├── file_id.h
    │   │   ├── guid_creator.cc
    │   │   ├── guid_creator.h
    │   │   ├── ignore_ret.h
    │   │   ├── linux_libc_support.cc
    │   │   ├── linux_libc_support.h
    │   │   ├── memory_mapped_file.cc
    │   │   ├── memory_mapped_file.h
    │   │   ├── safe_readlink.cc
    │   │   └── safe_readlink.h
    │   ├── memory.h
    │   ├── memory_range.h
    │   ├── memory_range_unittest.cc
    │   ├── scoped_ptr.h
    │   ├── string_conversion.cc
    │   ├── string_conversion.h
    │   ├── using_std_string.h
    │   └── windows
    │       ├── guid_string.cc
    │       ├── guid_string.h
    │       ├── string_utils.cc
    │       └── string_utils-inl.h
    ├── google_breakpad
    │   └── common
    │       ├── breakpad_types.h
    │       ├── minidump_cpu_amd64.h
    │       ├── minidump_cpu_arm64.h
    │       ├── minidump_cpu_arm.h
    │       ├── minidump_cpu_mips.h
    │       ├── minidump_cpu_ppc64.h
    │       ├── minidump_cpu_ppc.h
    │       ├── minidump_cpu_sparc.h
    │       ├── minidump_cpu_x86.h
    │       ├── minidump_exception_linux.h
    │       ├── minidump_exception_mac.h
    │       ├── minidump_exception_ps3.h
    │       ├── minidump_exception_solaris.h
    │       ├── minidump_exception_win32.h
    │       ├── minidump_format.h
    │       └── minidump_size.h
    └── third_party
        └── lss
            └── linux_syscall_support.h
```

* Add `crash_handler.pri` to the Qt application's .pro file.
* Add the required files to the Qt application's main file:

```C++
#include "crash_handler.h"
#include <QStandardPaths>

int buggyFunc() {
    delete reinterpret_cast<QString*>(0xFEE1DEAD);
    return 0;
}

int main(int argc, char *argv[]) {
    QCoreApplication a(argc, argv);

    // We put the dumps in the user's home directory for this example:
    Breakpad::CrashHandler::instance()->Init(QStandardPaths::writableLocation(QStandardPaths::HomeLocation));

    buggyFunc();

    return 0;
}
```

* Run the application. It will crash and produce crash dump file in the path specified during the Init call.(you can check the dump path at next startup for sending crash report including your dump file) 
* The above dump file + the symbol file (see next section) is used to debug the crash (see last section).

## Exporting the application's symbols

Exporting of the application symbols is OS dependent as far as I can tell. 

### Windows

* In the breakpad checkout, go to `src\tools\windows\binaries`. The `dump_syms.exe` application does the exporting for us. I had numerous issues in order to get `dump_syms` to work, especially for older versions. Finally I managed to get it working with the latest rev. 1291 of Breakpad repository. 

* If you don't have MSVC 2013 available on you system (more specifically msdia120.dll) you will be greeded with the following output when attempting to use dump_syms: `CoCreateInstance CLSID_DiaSource failed (msdia*.dll unregistered?)`

To fix it, download MSVC 2013 Express Edition and install it. For older versions of `dump_syms` you will require older versions of `msdia*.dll` as well. To get older version to work, following the steps below:

1. Download a copy of [msdia80.dll](http://www.dllme.com/download/dll-file/205365c3e4aa138c800936bdeca56c0f/msdia80.dll) and put it in `c:\Program Files\Common Files\Microsoft Shared\VC`.
2. Download a version of dump_syms built against MSVC9 [here](https://bug669384.bugzilla.mozilla.org/attachment.cgi?id=545295) into the `binaries` directory and rename the file to `dump_sums_vc9.exe`. It is also possible to build dump_syms manually, but I did not attempt it.
3. Also download the following files and place them into the `binaries` directory as well: [cygstdc++-6.dll](http://hg.mozilla.org/build/tools/raw-file/755e58ebc9d4/breakpad/win32/cygstdc++-6.dll), [cyggcc_s-1.dll](http://hg.mozilla.org/build/tools/raw-file/755e58ebc9d4/breakpad/win32/cyggcc_s-1.dll) and [cygwin1.dll](http://hg.mozilla.org/build/tools/raw-file/755e58ebc9d4/breakpad/win32/cygwin1.dll). 
4. Next register all copies of msdia on the computer. I registered the following 3 files:

```
c:\Windows\system32\regsvr32 "c:\Program Files\Common Files\Microsoft Shared\VC\msdia80.dll"
c:\Windows\system32\regsvr32 "c:\Program Files\Common Files\Microsoft Shared\VC\msdia90.dll"
c:\Windows\system32\regsvr32 "c:\Program Files\Common Files\Microsoft Shared\VC\msdia100.dll"
```

* The symbol export process basically converts the .pdb file generated by MSVC into a .sym file used by Breakpad. Run the following command from the `binaries` directory:

`dump_syms_vc9.exe <qt_app_build_path>\foo.pdb > foo.sym`

* That's it. This .sym file will be used when analyzing the minidump.

### Linux

For this I used the "Get the debugging symbols" section on [decoding-crash-dumps](http://www.chromium.org/developers/decoding-crash-dumps) as a reference.

The following steps were required from the breakpad checkout directory:

```bash
./configure
make
cd src/tools/linux/dump_syms
./dump_syms <path_to_build_dir>/foo.so > foo.sym
```

This command produced some warning, although it did not seem to break anything downstream.

```
<path_to_build_dir>/foo.so, section '.eh_frame': the call frame entry at offset 0x18 uses a DWARF expression to describe how to recover register '.cfa',  but this translator cannot yet translate DWARF expressions to Breakpad postfix expressions
```

* That's it. This .sym file will be used when analyzing the minidump. 

Note that dump_syms uses a library, not the main application.

## Analyzing the minidump

### Windows

I'm not sure if it is possible to properly analyze the dumps using the build in dump analysis applications found in the Debugging Tools for Windows set of tools since as far as I could figure out the Windows dump and Breakpad formats does not match exactly. 

Breakpad does however contains a small application which is intended to make sense out of the dump files.

* Download `minidump_stackwalk.exe` from [here](http://hg.mozilla.org/build/tools/raw-file/755e58ebc9d4/breakpad/win32/minidump_stackwalk.exe)
* Note that this .exe needs the same cygwin dependencies mentioned in the Windows section of "Exporting the application's symbols".
* Launch the `minidump_stackwalk.exe` with the dump file and pipe the output to `foo.txt`:

` minidump_stackwalk.exe foo.dmp symbols > foo.txt 2>&1`

* The above command prints a bunch of very useful information to help debug crashes (loaded modules, details of OS on which crash happened, reason for the crash, stack traces for all active threads). I noticed that the stack trace did not contain line numbers which indicates that the debug symbols was not correctly loaded. Inspecting the top part of the output I found this line:

`2014-02-26 11:49:53: simple_symbol_supplier.cc:171: INFO: No symbol file at foo.sym/foo.pdb/BD6D3E40BCF34C77861B0EADF13A901C69/foo.sym`

* To fix it you need to place the symbols in a specific directory structure. For example:

1. Create directory in the `binaries` directory called `foo.pdb`.
2. Inside this new directory, create another directory called (notice that I tood the hex characters from the above message) `BD6D3E40BCF34C77861B0EADF13A901C69`.
3. Copy the symbol file into this new directory.
4. Rerun the stack walk application like this: `minidump_stackwalk.exe ./foo.dmp .`

See [Notes on the directory structure required in order to use minidump_stackwalk](#general-notes) at the end of this document for more information on the required symbols directory structure.

* Looking at the output of `minidump_stackwalk.exe` now shows correct file numbers for the code in the Qt application.

### Linux

For this I used the "Get the debugging symbols" section on [decoding-crash-dumps](http://www.chromium.org/developers/decoding-crash-dumps) as a reference.

The following steps were required from within the breakpad checkout directory:

* `./configure && make`
* `minidump_stackwalk` can be found in /src/processor

After building, you can run `minidump_stackwalk` providing it with the .dmp file as well as the path to the symbols. For example:

```
minidump_stackwalk foo.dmp ./symbols 2>&1 > foo_stackwalk.txt
```

See "Notes on the directory structure required in order to use minidump_stackwalk" at the end of this document for more information on the required symbols directory structure.

## General Notes

* When using this approach to get crash reports from end users which will use release builds, we need to make sure the .pdb files on Windows are generated in order to do symbol exporting on the release libraries etc. To ensure that this happens, add the following to the .pro files or all libraries and executables:

```
# The following makes sure .pdb files are generated in release mode in order to analyze crash reports:
win32-msvc* {
    QMAKE_LFLAGS_RELEASE += /MAP
    QMAKE_CFLAGS_RELEASE += /Zi
    QMAKE_LFLAGS_RELEASE += /debug /opt:ref
}
```

* Notes on the directory structure required in order to use minidump_stackwalk:

In order to use these symbols with the `minidump_stackwalk` tool, you will need to place them in a specific directory structure. To see where they should be placed, you can do the following (note that you need to run it from within the symbols directory otherwise it does not work):

```
$ cd <symbols_path>
$ <breakpad_path>/src/processor/minidump_stackwalk foo.dmp . 2>&1 | grep "No symbol"
```

This will produce output like the following:

```
2014-03-20 12:41:17: simple_symbol_supplier.cc:196: INFO: No symbol file at ./libxcb.so.1/33466400C1C9785E1FADDFEA24D0D5F60/libxcb.so.1.sym
2014-03-20 12:41:17: simple_symbol_supplier.cc:196: INFO: No symbol file at ./libqxcb.so/37BD6BAC43D805F32EB4F3537000E40E0/libqxcb.so.sym
2014-03-20 12:41:17: simple_symbol_supplier.cc:196: INFO: No symbol file at ./ld-2.5.so/2D6E32C01DB690E6E6113D736D9B45AC0/ld-2.5.so.sym
2014-03-20 12:41:17: simple_symbol_supplier.cc:196: INFO: No symbol file at ./libqca-ossl.so/0EA2F5969C8B7B163AA67668688AEED30/libqca-ossl.so.sym
2014-03-20 12:41:17: simple_symbol_supplier.cc:196: INFO: No symbol file at ./libtcl8.4.so/F3E473507067ACA9672BF6E5DAF41ADC0/libtcl8.4.so.sym
2014-03-20 12:41:17: simple_symbol_supplier.cc:196: INFO: No symbol file at ./libstdc++.so.6/9366DEB563B557872C7CDA1F54FD78A90/libstdc++.so.6.sym
2014-03-20 12:41:17: simple_symbol_supplier.cc:196: INFO: No symbol file at ./gconv-modules.cache/000000000000000000000000000000000/gconv-modules.cache.sym
```

The system libraries can be ignored, and only the libraries for your application are of interest. Instead creating the required symbol tree structure manually, we can automate the process.

The first line of the symbol file contains the information you need to produce this directory structure, for example (your output will vary):

```
$ head -n1 test.sym
MODULE Linux x86_64 6EDC6ACDB282125843FD59DA9C81BD830 test
$ mkdir -p ./symbols/test/6EDC6ACDB282125843FD59DA9C81BD830
$ mv test.sym ./symbols/test/6EDC6ACDB282125843FD59DA9C81BD830
```

Obviously it makes sense to automate the process for bigger applications where multiple symbol files are involved. The bash script below will move all .sym files found in the directory from which it is called to the correct places:

```
for symbol_file in *.sym
do
    file_info=$(head -n1 $symbol_file)
    IFS=' ' read -a splitlist <<< "${file_info}"
    basefilename=${symbol_file:0:${#symbol_file} - 4}
    dest_dir=$basefilename/${splitlist[3]}
    mkdir -p $dest_dir
    mv $symbol_file $dest_dir
    echo "$symbol_file -> $dest_dir/$symbol_file"
done
```

Note that a couple of things can go wrong here:
1. First of all, when exporting your symbols make sure to specify the actual library paths to `dump_syms`, not any symbolic links.
2. For me, the hex code in the first line of some libraries was different to the hex code which was actually listed in the `grep "No symbols"` output and I had to manually fix it. Not sure why this is the case.
## How to Use

### With *CMake* projects:
Add subdirectory `./src` from this repository to your project's `CMakeLists.txt` and enable `ASM` language when on Unix:
```cmake
if(UNIX)
    enable_language(ASM)
endif(UNIX)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../src)
```
Add `QCrashHandler` library to your target:
```camke
target_link_libraries(<target> ... QCrashHandler ...)
```
For release builds select [RelWithDebInfo](https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html) build type.

### With *qmake* projects:
In your *Qt* project file (`*.pro`) simply *include* the `./src/qcrashhandler.pri` file from this repository:

```cmake
include($$PWD/../src/qcrashhandler.pri)
```

For release builds make sure to configure the project to create the debug symbols, for example:

```cmake
CONFIG(debug, debug|release) {
    TARGET = testd
} else {
    TARGET = test
    # create debug symbols for release builds
    CONFIG *= force_debug_info
    QMAKE_CXXFLAGS_RELEASE_WITH_DEBUGINFO -= -O2
}
```
### Usage in code
The on your `main` function create and intialize the crash handler, *after* creating the `QApplication` object;

```c++
int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    // write the dumps in the user's desktop:
    Breakpad::CrashHandler::instance()->Init(QStandardPaths::writableLocation(QStandardPaths::DesktopLocation));

    // ... other stuff

    return a.exec();
}
```

And that's it! The application will write dump files to the specified location whenever a crash occurs.

## Commandline Analysis

First compile necessary breakpad binaries using `gcc` (use **MSys2** on *Windows*).

```bash
which gcc

cd ${PWD}/deps/breakpad.git
./configure
make

cd ../../
```

Add to `PATH` necessary binary directories.

```bash
# on windows
PATH="${PATH}:${PWD}/deps/breakpad.git/src/tools/windows/binaries"
PATH="${PATH}:${PWD}/deps/breakpad.git/src/processor"

# on linux
PATH="${PATH}:${PWD}/deps/breakpad.git/src/tools/linux/dump_syms"
PATH="${PATH}:${PWD}/deps/breakpad.git/src/processor"
PATH="${PATH}:${PWD}/deps/breakpad.git/src/tools/linux/core2md"
PATH="${PATH}:${PWD}/deps/breakpad.git/src/tools/linux/md2core"

# check
which dump_syms
which minidump_stackwalk
```

Create symbols file, on windows the `*.pdb` file is required (more on this later), and on linux the binary file compiled with debug symbols is required.

```bash
# on windows
dump_syms test.pdb > test.sym
# on linux (binary/esecutable, could be *.so file)
dump_syms test > test.sym
# run a dummy stack walk over the dump file to see where is the symbols file expected to be
minidump_stackwalk test.dmp symbols 2>&1 | grep test.sym
# ... INFO: No symbol file at ./symbols/test.pdb/XXXXX/test.sym
# create expected directory
mkdir -p ./symbols/test.pdb/XXXXX
# move symbols file to expected location
mv test.sym ./symbols/test.pdb/XXXXX/test.sym
# finally run the stack walk
minidump_stackwalk ./test.dmp symbols > test_analysis.txt
```

Show show call stack starting with the crash on the top:

```
 1  Qt5Cored.dll + 0xbc531
    rsp = 0x000000c2132ffb90   rip = 0x000000005d1ac531
    Found by: stack scanning
 2  test.exe!QString::`scalar deleting destructor'(unsigned int) + 0x18
    rsp = 0x000000c2132ffbb0   rip = 0x00007ff6f1554148
    Found by: stack scanning
 3  test.exe!buggyFunc() [main.cpp : 7 + 0x2b]
    rsp = 0x000000c2132ffbe0   rip = 0x00007ff6f155403f
    Found by: call frame info
 4  test.exe!main [main.cpp : 19 + 0x5]
    rsp = 0x000000c2132ffc30   rip = 0x00007ff6f15540d1
    Found by: call frame info
```

There are references to `main.cpp` and line numbers which provide useful information about the crash.

**NOTE** : on windows we need a `*.pdb` file for release builds. To export debug symbols for release builds in **Qt** simply add to the `*.pro` project file:

```cmake
CONFIG *= force_debug_info
QMAKE_CXXFLAGS_RELEASE_WITH_DEBUGINFO -= -O2
```

Alternatively, symbols for *Release* versions can be obtained by configuring the *Visual Studio* project as follows:

* Open the **Properties** dialog box for the project.

* Click the **C/C++** node. Set **Debug Information Format** to `Program Database (/Zi)`.

* Select the **Optimization** node. Set **Optimization** to `Disabled (/Od)`.

* Expand **Linker** and click the **General** node. Set **Enable Incremental Linking** to `No (/INCREMENTAL:NO)`.

* Select the **Debugging** node. Set **Generate Debug Info** to `Yes (/DEBUG)`.

* Select the **Optimization** node. Set **References** to `/OPT:REF`.

### Script

A [`bash` script was developed](./src/qcrashdumper) to automate the analysis of dump `*.dmp` files. It can be added to the `PATH` for ease of use, e,g,:

```bash
PATH="${PATH}:${PWD}/src/"
which qcrashdumper
# pass minidump as first argument
qcrashdumper test.dmp /path/to/pdbfiles
```

---

## Windows Errors

The `dump_syms.exe` tool provided by the Windows distribution of breakpad sometimes does not generate the symbols and displays an error similar to:

```
CoCreateInstance CLSID_DiaSource {E6756135-1E65-4D17-8576-610761398C3C} failed (msdia*.dll unregistered?)
Open failed
```

This is because requires an specific `*.dll` from some Visual Studio version registered on the system. Looking at the source code of `pdb_source_line_writer.cc`, the following lines:

```c++
class DECLSPEC_UUID("B86AE24D-BF2F-4ac9-B5A2-34B14E4CE11D") DiaSource100;
class DECLSPEC_UUID("761D3BCD-1304-41D5-94E8-EAC54E4AC172") DiaSource110;
class DECLSPEC_UUID("3BFCEA48-620F-4B6B-81F7-B9AF75454C7D") DiaSource120;
class DECLSPEC_UUID("E6756135-1E65-4D17-8576-610761398C3C") DiaSource140;

// If the CoCreateInstance call above failed, msdia*.dll is not registered.
// We can try loading the DLL corresponding to the #included DIA SDK, but
// the DIA headers don't provide a version. Lets try to figure out which DIA
// version we're compiling against by comparing CLSIDs.
const wchar_t *msdia_dll = nullptr;
if (CLSID_DiaSource == _uuidof(DiaSource100)) {
msdia_dll = L"msdia100.dll";
} else if (CLSID_DiaSource == _uuidof(DiaSource110)) {
msdia_dll = L"msdia110.dll";
} else if (CLSID_DiaSource == _uuidof(DiaSource120)) {
msdia_dll = L"msdia120.dll";
} else if (CLSID_DiaSource == _uuidof(DiaSource140)) {
msdia_dll = L"msdia140.dll";
}
```

indicate that the error above is caused by the missing `msdia140.dll` (deduced by matching the `E6756135-1E65-4D17...` from the error line to the source code).

The solution is to find `msdia140.dll` in your system (simply search for it in `C:`, if not present then download the appropriate VisualStudio redistributables) and copy it to `C:\Program Files\Common Files\Microsoft Shared\VC` directory. Then open a command line instance with administrator rights and run the command:

```cmd
C:\Windows\system32\regsvr32 "C:\Program Files\Common Files\Microsoft Shared\VC\msdia140.dll"
```

After this, `dump_syms.exe` should work properly.

---

## Visual Studio Analysis (Windows)

Open the *Visual Studio* project with the *exact* source code version used to create the binary and build to create the relevant debug symbols. Then go to `File -> Open -> File...` and open the dump file. A window inside Visual Studio displays the dump file summary info. 

![alt text](./doc/01.jpg)

Normally if the `Debug with Native Only` on the right side of the windows is clicked, a debugging session should start, but must likely a *No compatible code running* error will appear. 

![alt text](./doc/02.jpg)

To fix this, it is necessary to reproduce the full environment in which the application crashed. Note the window displaying the dump file info shows the modules involved in the crash including:

```
C:\Users\User\Desktop\test\test.exe

// other modules...

C:\Users\User\Desktop\test\Qt5Core.dll

// other modules...
```

This is the location in the *Deployment* machine where the crash occured, but this location does not exist yet in the *Development* machine. So after deploying **the exact same version of the application, in the same location**, now is possible to click the `Debug with Native Only` on the right side of the windows, and then the debugger should show the crash line, call stack and other debug information.

![alt text](./doc/03.jpg)

---

## QtCreator Analysis (Linux)

First make sure the `PATH` includes `${PWD}/deps/breakpad.git/src/tools/linux/md2core`, then convert the dump file into a core file using breakpad's `minidump-2-core` tool:

```bash
minidump-2-core test.dmp > test.core
```

Open the *QtCreator* project with the *exact* source code version used to create the binary and build to create the relevant debug binary files. 

Go to `Debug -> Start Debugging -> Load Core File...`. Then select the core file and the compiled binary and click `OK`. 

Normally the debugger should show the crash line, call stack and other debug information.

![alt text](./doc/04.jpg)

If the application uses shared libraries though, the full call stack might not me shown correctly. One must pay attention to the `Application Output` messages;

```
Debugging starts
Could not load shared library symbols for XXX libraries, e.g. ...
```

This means it is necessary to tell the debugger where are the shared libraries used by the application. To to this go to `Tools -> Options...` change to the `GDB` tab and in the `Additional Starup Commands` add a line similar to:

```
set solib-search-path /path/to/the/shared/libs
```

Then restart the debugging session.

---

## Debbugging symbols on Linux

On Windows, debugging symbols are separated automatically from the binary files (`*.exe` or `*.dll`) into `*.pdb` files. This reduces the size of the binary files to be deployed. 

On Linux, this has to be done manually, the resulting binaries are too large because they contain all the debug information. To separate them, use the following commands:

```bash
objcopy --only-keep-debug "${binary_file}" "${debug_symbols_file}"
strip --strip-debug --strip-unneeded "${binary_file}"
objcopy --add-gnu-debuglink="${debug_symbols_file}" "${binary_file}"
```

This will make the binary file much smaller for deployment, while the  debug symbols file can be kept in the *Development* machine for crash analysis. Note the two files are *linked* together (via checsums and file name mechanisms) through the last command of the snippet above.

In the test project, the symbols separation is done automatically after building the application by the [`qpostprocess.pri` file](./src/qpostprocess.pri).

---

## Sources

The original wiki for using google's breakpad was taken from [here](https://github.com/JPNaude/dev_notes/wiki/Using-Google-Breakpad-with-Qt).

The breakpad source code cane be cloned from [here](https://chromium.googlesource.com/breakpad/breakpad/) or [here](https://github.com/google/breakpad.git).

For **Linux** the breakpad library requires the `linux_syscall_support.h` file which can be obtained from [here](https://chromium.googlesource.com/linux-syscall-support).

---

## References

* 1. <https://github.com/JPNaude/dev_notes/wiki/Using-Google-Breakpad-with-Qt>

* 2. <http://www.chromium.org/developers/decoding-crash-dumps>

* 3. <https://msdn.microsoft.com/en-us/library/fsk896zz.aspx>

* 4. <https://docs.microsoft.com/en-us/visualstudio/debugger/using-dump-files?view=vs-2019>

* 5. <https://developer.mozilla.org/en-US/docs/Mozilla/Debugging/Debugging_a_minidump>

* 6. <https://stackoverflow.com/questions/6993061/build-qt-in-release-with-debug-info-mode/35704181#35704181>

* 7. <https://developer.mozilla.org/en-US/docs/Mozilla/Debugging/Debugging_a_minidump#Using_minidump-2-core_on_Linux>

* 8. <https://doc.qt.io/qtcreator/creator-debugger-operating-modes.html#launching-in-core-mode>

* 9. <https://stackoverflow.com/questions/866721/how-to-generate-gcc-debug-symbol-outside-the-build-target>

* 10. <https://www.computerhope.com/unix/strip.htm>

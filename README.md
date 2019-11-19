## How to Use

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

A `bash` script was developed to automate the analysis of dump `*.dmp` files. It can be placed in any directory already added to the `PATH`, e,g,:

```bash
touch ${PWD}/src/qcrashdumper
PATH="${PATH}:${PWD}/src/"
which qcrashdumper
# pass in binary/symbols file as first argument, and minidump as second argument
qcrashdumper test.pdb test.dmp
```

Then pasting the contents:

```bash
#!/bin/sh
# arguments :
# 1) symbols file on Windows MSys2 (*.pdb), binary file on Linux
# 2) minidump file (*.dmp)
# usage windows (pdb file)  : qcrashdumper test.pdb ~/Desktop/xxxxxxx.dmp
# usage linux (binary file) : qcrashdumper test ~/Desktop/xxxxxxx.dmp

# get args
bin_file=$1
dmp_file=$2

# check arg
if [[ ! $bin_file ]]; then
    if [[ $machine -ne "Linux" ]] && [[ $machine -ne "Mac" ]]; then
        printf "\n[ERROR] missing first argument; provide symbols file name (*.pdb)\n\n" >&2; 
    else
        printf "\n[ERROR] missing first argument; provide binary file name\n\n" >&2; 
    fi
    exit 1; 
fi
if [[ ! $dmp_file ]]; then
    printf "\n[ERROR] missing second argument; provide minidump file (*.dmp)\n\n" >&2; 
    exit 1; 
fi

# check running machine
uname_out="$(uname -s)"
case "${uname_out}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    MSYS*)      machine=MSys;;
    *)          machine="UNKNOWN:${uname_out}"
esac
#echo "[INFO] machine is ${machine}."

# try to add relevant paths
scr_dir="$(dirname "$(readlink -f "$0")")"
if ! type "dump_syms" > /dev/null 2>&1; then
    if [[ $machine -ne "Linux" ]] && [[ $machine -ne "Mac" ]]; then
        PATH="${PATH}:${scr_dir}/../deps/breakpad.git/src/tools/windows/binaries"
    else
        PATH="${PATH}:${scr_dir}/../deps/breakpad.git/src/tools/linux/dump_syms"
    fi
fi
if ! type "minidump_stackwalk" > /dev/null 2>&1; then
    PATH="${PATH}:${scr_dir}/../deps/breakpad.git/src/processor"
fi

# check for dependencies
if ! type "dump_syms" > /dev/null 2>&1; then
    echo "[ERROR] dump_syms not found in PATH."
    exit 1
fi
if ! type "minidump_stackwalk" > /dev/null 2>&1; then
    echo "[ERROR] minidump_stackwalk not found in PATH."
    exit 1
fi

# get target symbols dir (adding *.sym to binary file)
bin_basefile=$(basename "${bin_file}")
md_out=$(minidump_stackwalk ${dmp_file} symbols 2>&1 | grep ${bin_basefile}.sym)
#echo "[DEBUG] md_out = ${md_out}"

# match to look for in ${md_out}
test_match="INFO: No symbol file at "
# get offset when match starts (format OFFSET:MATCH)
test_out=$(echo $md_out | grep -b -o "$test_match")
# parse the offset value
test_offset=$(echo "${test_out%:INFO*}")
# add match length to match offset to get total offset
declare -i test_intoff
test_intoff="${test_offset}+${#test_match}-1"
# get string starting from total offset
sym_targ=${md_out:${test_intoff}}
#echo "[DEBUG] sym_targ = ${sym_targ}"
sym_dir=$(dirname "${sym_targ}")
#echo "[DEBUG] sym_dir  = ${sym_dir}"

# create symbols dir
mkdir -p ${sym_dir}
# create symbols file
dump_syms ${bin_file} > ${bin_basefile}.sym
# move to expected location
mv ${bin_basefile}.sym ${sym_targ}

# get analysis and put in file
minidump_stackwalk ${dmp_file} symbols > ${bin_basefile}.txt  2>&1

# print 50 lines after "Crash" match
awk '/Crash/ {for(i=1; i<=50; i++) {getline; print}}' ${bin_basefile}.txt
#echo "[DEBUG] success!"
```

---

## Visual Studio Analysis (Windows)

Simply open the *Visual Studio* project with the *exact* source code version used to create the binary and build to create the relevant debug symbols. Then go to `File -> Open -> File...` and open the dump file.

A window inside Visual Studio displays the dump file summary info. Click the `Debug with Native Only` on the right sid eof the windows, and then the debugger should show the crash line, call stack and other debug information.

---

## QtCreator Analysis (Linux)

First convert the dump file into a core file using breakpad's `minidump-2-core` tool:

```bash
minidump-2-core test/test.dmp > test.core
```

Then open the *QtCreator* project with the *exact* source code version used to create the binary and build to create the relevant debug binary files. Then go to `Debug -> Start Debugging -> Load Core File...`. Then select the core file and the compiled binary and click `OK`. The debugger should show the crash line, call stack and other debug information.

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
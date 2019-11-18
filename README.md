## How to Use

Compile necessary binaries using **MSys2** (it does not matter that they are compiled with `gcc`).

```bash
which gcc

cd "${REPOS_DIR}/breakpad.git"
./configure
make

ls -la ./src/processor/minidump_stackwalk

subl ~/.bash_profile
```

Add to `PATH` necessary binary directories.

```
PATH="${PATH}:${REPOS_DIR}/breakpad.git/src/tools/windows/binaries"
PATH="${PATH}:${REPOS_DIR}/breakpad.git/src/processor"
```

Restart MSys2.

```bash
which dump_syms
which minidump_stackwalk

cd ${REPOS_DIR}/breakpad.git/qt_crashandler/test/debug

dump_syms test.pdb > test.sym

minidump_stackwalk test.dmp symbols 2>&1 | grep test.sym
# ... INFO: No symbol file at ./symbols/test.pdb/XXXXX/test.sym

mkdir -p ./symbols/test.pdb/XXXXX
cp test.sym ./symbols/test.pdb/XXXXX/test.sym

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

**NOTE** : there are references to `main.cpp` and line numbers which provide useful information.

**NOTE** : we need a `*.pdb` file for release builds (it does not provide as much info as for debug builds, but at least we get the file name and previous line). To export debug symbols for release builds:

In **Qt** simply add to the `*.pro` project file:

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

**VISUAL STUDIO** : to load the minidump files in VisualStudio follow reference 4.

---

## Script

A `bash` script was developed to automate the analysis of dump `*.dmp` files. It can be placed in any directory already added to the `PATH`, e,g,:

```bash
touch ${PWD}/src/qcrashdumper
PATH="${PATH}:${PWD}/src/"
which qcrashdumper
# Assume test.pdb and test.sym in ${PWD}
qcrashdumper test.pdb
```

Then pasting the contents:

```bash
#!/bin/sh
# NOTE : $PWD always contains the calling dir

# check for dependencies
if ! type "dump_syms" > /dev/null; then
	echo "[ERROR] dump_syms.exe not found in PATH."
	exit 1
fi
if ! type "minidump_stackwalk" > /dev/null; then
	echo "[ERROR] minidump_stackwalk.exe not found in PATH."
	exit 1
fi

# check arg
if [[ ! $1 ]]; then
	printf "\n[ERROR] missing arguments, provide symbols file name (*.pdb)\n\n" >&2; 
	exit 1; 
fi
# get arg
pdb_argfile=$1
pdb_basefile=$(basename "${pdb_argfile}")
file_base=$1
out_dir=$PWD
# check if contains extension to update base filename
if [[ $pdb_argfile = *".pdb"* ]]; then
	file_base="${pdb_basefile%.*}"
else
	pdb_argfile=${pdb_argfile}.pdb
fi
pdb_basefile=${file_base}.pdb
#echo "[DEBUG] pdb_argfile   = ${pdb_argfile}"
#echo "[DEBUG] pdb_basefile  = ${pdb_basefile}"
#echo "[DEBUG] file_base     = ${file_base}"
# check pdb file exists
if [[ ! -e $pdb_argfile ]]; then
    printf "\n[ERROR] symbols file with name :\n%s \ndoes not exist!\n\n" $pdb_argfile
    exit 1
fi
# get dump file name
dmp_file=${file_base}.dmp
# check dump file exists
if [[ ! -e $dmp_file ]]; then
    printf "\n[ERROR] dump file :\n%s \ndoes not exist!\n\n" $dmp_file
    exit 1
fi
#echo "[DEBUG] dmp_file      = ${dmp_file}"

# create symbols file from pdb
sym_fullfile=${out_dir}/test.sym
dump_syms ${pdb_argfile} > ${sym_fullfile}
#echo "[DEBUG] sym_fullfile  = ${sym_fullfile}"
sym_basefile=$(basename "${sym_fullfile}")
#echo "[DEBUG] sym_basefile  = ${sym_basefile}"

# get target symbols dir
md_out=$(minidump_stackwalk ${dmp_file} symbols 2>&1 | grep ${sym_basefile})
#echo "[DEBUG] md_out        = ${md_out}"
# match to look for in ${md_out}
test_match="INFO: No symbol file at "
# get match offset and clean it
test_out=$(echo $md_out | grep -b -o "$test_match")
test_offset=$(echo "${test_out%:INFO*}")
# add match length to offset
declare -i test_intoff
test_intoff="${test_offset}+${#test_match}-1"
sym_targ=${md_out:${test_intoff}}
#echo "[DEBUG] sym_targ      = ${sym_targ}"
sym_dir=$(dirname "${sym_targ}")
#echo "[DEBUG] sym_dir       = ${sym_dir}"

# create symbols dir and copy ${sym_fullfile}
mkdir -p ${sym_dir}
cp ${sym_fullfile} ${sym_targ}

# get analysis and put in file
minidump_stackwalk ${dmp_file} symbols > ${file_base}_analysis.txt  2>&1

# print 50 lines after "Crash" match
awk '/Crash/ {for(i=1; i<=50; i++) {getline; print}}' ${file_base}_analysis.txt
#echo "[DEBUG] success!"
```

---

## Source

The original wiki for using google's breakpad was taken from [here](https://github.com/JPNaude/dev_notes/wiki/Using-Google-Breakpad-with-Qt).

The breakpad source code cane be cloned from [here](https://chromium.googlesource.com/breakpad/breakpad/) or [here]().

---

## References

* 1. <https://github.com/JPNaude/dev_notes/wiki/Using-Google-Breakpad-with-Qt>

* 2. <http://www.chromium.org/developers/decoding-crash-dumps>

* 3. <https://msdn.microsoft.com/en-us/library/fsk896zz.aspx>

* 4. <https://docs.microsoft.com/en-us/visualstudio/debugger/using-dump-files?view=vs-2019>

* 5. <https://developer.mozilla.org/en-US/docs/Mozilla/Debugging/Debugging_a_minidump>

* 6. <https://stackoverflow.com/questions/6993061/build-qt-in-release-with-debug-info-mode/35704181#35704181>
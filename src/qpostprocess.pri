# in case of windows, create *.vcxproj.user file to automatically add dependencies paths
win32 {
  # test if already exists
  VCXPROJ_USER_FILE = "$${_PRO_FILE_PWD_}/$${TARGET}.vcxproj.user"
  !exists( $${VCXPROJ_USER_FILE}) {
    # generate file contents
    TEMPNAME = $${QMAKE_QMAKE}     # contains full dir of qmake used
    QTDIR    = $$dirname(TEMPNAME) # gets only the path
    # vcxproj.user template
    VCXPROJ_USER = "<?xml version=\"1.0\" encoding=\"utf-8\"?>$$escape_expand(\\n)\
    <Project xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">$$escape_expand(\\n)\
      <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Debug|Win32'\">$$escape_expand(\\n)\
        <LocalDebuggerEnvironment>PATH=$${QTDIR};%PATH%</LocalDebuggerEnvironment>$$escape_expand(\\n)\
        <DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>$$escape_expand(\\n)\
      </PropertyGroup>$$escape_expand(\\n)\
      <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Release|Win32'\">$$escape_expand(\\n)\
        <LocalDebuggerEnvironment>PATH=$${QTDIR};%PATH%</LocalDebuggerEnvironment>$$escape_expand(\\n)\
        <DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>$$escape_expand(\\n)\
      </PropertyGroup>$$escape_expand(\\n)\
      <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Debug|x64'\">$$escape_expand(\\n)\
        <LocalDebuggerEnvironment>PATH=$${QTDIR};%PATH%</LocalDebuggerEnvironment>$$escape_expand(\\n)\
        <DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>$$escape_expand(\\n)\
      </PropertyGroup>$$escape_expand(\\n)\
      <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Release|x64'\">$$escape_expand(\\n)\
        <LocalDebuggerEnvironment>PATH=$${QTDIR};%PATH%</LocalDebuggerEnvironment>$$escape_expand(\\n)\
        <DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>$$escape_expand(\\n)\
      </PropertyGroup>$$escape_expand(\\n)\
    </Project>$$escape_expand(\\n)\
    "
    # write file
    write_file($${VCXPROJ_USER_FILE}, VCXPROJ_USER)  
  }
}
# in case of linux, add post build commands to separate debug symbols
linux-g++ {
  load(resolve_target)
  TARGET_FULL = $$basename(QMAKE_RESOLVED_TARGET)
  TARGET_PATH = $$dirname(QMAKE_RESOLVED_TARGET)
  TARGET_PDB  = $${TARGET_FULL}.pdb
  QMAKE_POST_LINK += $$quote( cd "$${TARGET_PATH}"; objcopy --only-keep-debug "$${TARGET_FULL}" "$${TARGET_PDB}" $$escape_expand(\n\t))
  QMAKE_POST_LINK += $$quote( cd "$${TARGET_PATH}"; strip --strip-debug --strip-unneeded "$${TARGET_FULL}" $$escape_expand(\n\t))
  QMAKE_POST_LINK += $$quote( cd "$${TARGET_PATH}"; objcopy --add-gnu-debuglink="$${TARGET_PDB}" "$${TARGET_FULL}" $$escape_expand(\n\t))
}
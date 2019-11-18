# Linux Syscall Support (LSS)

The `linux_syscall_support.h` file was cloned from:

* <https://chromium.googlesource.com/linux-syscall-support>

Needs to be copied to the breakpad source code:

```bash
mkdir $PWD/breakpad.git/src/third_party/lss
cp $PWD/linux_syscall_support.h $PWD/breakpad.git/src/third_party/lss/linux_syscall_support.h
```
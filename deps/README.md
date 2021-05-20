# Linux Syscall Support (LSS)

For Linux, the `linux_syscall_support.h` is needed from:

* <https://chromium.googlesource.com/linux-syscall-support>

Which just

And needs to be copied to the breakpad source code:

```bash
mkdir $PWD/breakpad.git/src/third_party/lss
cp $PWD/linux_syscall_support.h $PWD/breakpad.git/src/third_party/lss/linux_syscall_support.h
```

This is automatically done by `qcrashhandler.pri`.
# Notes

## Docker
### Naive Way
Dockerfile:
```
FROM ubuntu:latest

RUN apt-get update && apt-get install -y build-essential gcc g++

WORKDIR /reactor-server

COPY . .

RUN g++ -o main main.cpp

CMD ["./main"]
```

main.cpp:
```
#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
```

Commands:
```
>> docker build -t ubuntu-cpp .
>> docker image prune -f
>> docker run -it --rm ubuntu-cpp
```

### Advanced Way
In Dockerfile, we just install the necessary packages:
```
FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        swig \
        vim \
        gdb \
        valgrind \
        cmake && \
    apt-get clean
```

Commands:
```
>> docker build -t ubuntu-cpp .
>> docker image prune -f
```

```
>> docker run -it --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v $(pwd):/root/projects/reactor-server --workdir=/root/projects/reactor-server ubuntu-cpp
```

`--cap-add=SYS_PTRACE`: This option adds the capability to ptrace to the container. Ptrace is a system call used for process tracing and debugging. This capability is necessary for tools like GDB (GNU Debugger) to debug processes inside the container.

`--security-opt seccomp=unconfined`: This option disables seccomp (secure computing mode) security restrictions within the container. Seccomp is a Linux kernel feature that filters system calls, and unconfined mode allows all system calls, which can be necessary for certain debugging tools.

## Build
### Compile Options
- `-o`: Output file.
- `-g`: Generate debugging information.
- `-On`: Optimize generated code for speed.
- `-c`: Compile or assemble the source files, but do not link to create an executable.
- `-std=c++11`: Use the C++11 standard.

For `-On`:
- `-O0`: No optimization.
- `-O` or `-O1`: Optimize.
- `-O2`: Optimize even more, which is recommended.
- `-O3`: Optimize yet more.

### Specify Include Path
```
>> g++ -I./include -o main main.cpp
```

## Library Tutorial
### Structure
```
├── dependency
│   ├── dependency.cpp
│   ├── dependency.h
└── main.cpp
```

### Content
dependency/dependency.h:
```
#ifndef DEPENDENCY_H
#define DEPENDENCY_H

void f();

#endif
```

dependency/dependency.cpp:
```
#include "./dependency.h"
#include <iostream>

void f() {
    std::cout << "Hello, World!" << std::endl;
}
```

main.cpp:
```
#include "./dependency/dependency.h"

int main() {
    f();
    return 0;
}
```

### Static Library
```
>> g++ -c -o libdependency.a dependency.cpp
```

```
// Not recommended:
>> g++ -o main main.cpp ./dependency/libdependency.a
>> ./main

// Recommended:
>> g++ -o main main.cpp -L./dependency -ldependency
>> ./main
```

### Dynamic Library
```
>> g++ -fPIC -shared -o libdependency.so dependency.cpp
```

```
// Not recommended:
>> g++ -o main main.cpp ./dependency/libdependency.so
>> ./main

// Recommended:
>> g++ -o main main.cpp -L./dependency -ldependency
>> ./main
```

Before running the executable, we need to set the `LD_LIBRARY_PATH` environment variable:
```
>> echo ${DYLD_LIBRARY_PATH}
>> export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:./dependency
```

#### Characteristics of dynamic library
- Code reuse: Multiple programs can use the same dynamic library code simultaneously, reducing memory usage and disk footprint compared to statically linking the code into each program.
- Modular updates: The library code can be updated independently of the programs that use it, without needing to recompile or re-link those programs.
- Flexibility: Programs can conditionally load different dynamic libraries at runtime based on requirements or available resources.
- Reduced distribution size: Executable file sizes are smaller since common library code is not bundled, but loaded from system libraries when needed.

## Makefile Demo
Notes: Use tab for indentation in Makefile.
```
all: libdependency.a libdependency.so

libdependency.a: dependency.cpp dependency.h
    g++ -c -o libdependency.a dependency.cpp

libdependency.so: dependency.cpp dependency.h
    g++ -fPIC -shared -o libdependency.so dependency.cpp

clean:
    rm -f libdependency.a libdependency.so
```

```
>> make clean
>> make
```

Variables:
```
INCLUDE_PATH = -I./include_alpha -I./include_beta
LIBRARY_PATH = -L./dependency_alpha -L./dependency_beta
```
Use `$(INCLUDE_PATH)` and `$(LIBRARY_PATH)` in the Makefile.

## Basic C & C++ & Linux
### Main Function
```
#include <iostream>
using namespace std;

int main(int argc, char* argv[], char* envp[]) {
    for (int i = 0; i < argc; i++) {
        cout << "argv[" << i << "]: " << argv[i] << endl;
    }

    // It's similar to run `env` in shell.
    for (int i = 0; envp[i] != 0; i++) {
        cout << "envp[" << i << "]: " << envp[i] << endl;
    }

    setenv("HELLO_WORLD", "Hello, World!", 0); // If the third argument is 0, it will not overwrite the existing value.
    cout << "HELLO_WORLD: " << getenv("HELLO_WORLD") << endl;

    return 0;
}
```

### Time
Focus on `<time.h>`
#### time_t
time_t: alias for a long type, defined in `<time.h>` header file.
```
typedef long time_t;
```

#### time function
```
time_t time(time_t* t);
```

```
#include <time.h>

time_t now = time(0);

time_t now;
time(&now);
```

#### structure tm
```
struct tm {
    int tm_sec;   // seconds after the minute (0 to 61)
    int tm_min;   // minutes after the hour (0 to 59)
    int tm_hour;  // hours since midnight (0 to 23)
    int tm_mday;  // day of the month (1 to 31)
    int tm_mon;   // months since January (0 to 11)
    int tm_year;  // years since 1900
    int tm_wday;  // days since Sunday (0 to 6 Sunday=0)
    int tm_yday;  // days since January 1 (0 to 365)
    int tm_isdst; // Daylight Saving Time flag
};
```

#### localtime function
localtime: converts the time_t value to a tm structure, defined in `<time.h>` header file.    
localtime() is not thread-safe, and localtime_r() is the thread-safe version.

```
struct tm* localtime(const time_t* timep);
struct tm* localtime_r(const time_t* timep, struct tm* result);
```

```
#include <iostrean>
#include <time.h>
using namespace std;

int main() {
    time_t now = time(0);
    cout << "now = " << now << endl;

    tm tm_now;
    localtime_r(&now, &tm_now);

    string stime = 
        to_string(tm_now.tm_year + 1900) + "-" + 
        to_string(tm_now.tm_mon + 1) + "-" + 
        to_string(tm_now.tm_mday) + " " + 
        to_string(tm_now.tm_hour) + ":" + 
        to_string(tm_now.tm_min) + ":" + 
        to_string(tm_now.tm_sec);

    cout << "stime = " << stime << endl;

    return 0;
}
```

#### mktime function
mktime: converts the tm structure to a time_t value, defined in `<time.h>` header file.
```
time_t mktime(struct tm* tm);
```

#### gettimeofday function
gettimeofday: gets the current time and timezone information, defined in `<sys/time.h>` header file.
```
int gettimeofday(struct timeval* tv, struct timezone* tz);

struct timeval {
    time_t tv_sec;       // seconds
    suseconds_t tv_usec; // microseconds
};

struct timezone {
    int tz_minuteswest; // minutes west of Greenwich
    int tz_dsttime;     // type of DST correction
};
```

#### sleep function
sleep: suspends the execution of the current thread for a specified number of seconds, defined in `<unistd.h>` header file.
```
unsigned int sleep(unsigned int seconds);
int usleep(useconds_t usec);
```

### Directory
#### Get current directory
```
// unistd.h

char* getcwd(char* buf, size_t size);
char* get_current_dir_name(void);
```

```
#include <iostream>
#include <unistd.h>
using namespace std;

int main() {
    char path1[256];
    getcwd(path1, sizeof(buf));
    cout << "Current Directory: " << path1 << endl;

    char* path2 = get_current_dir_name();
    cout << "Current Directory: " << path2 << endl;
    free(path2);

    return 0;
}
```

#### Change directory
```
// unistd.h

int chdir(const char* path);
```

#### Create directory
```
// sys/stat.h
int mkdir(const char* pathname, mode_t mode);
// pathname: directory name
// mode: directory permission, e.g. 0755 (0 cannot be omitted because it is an octal number)
```

#### Delete directory
```
// unistd.h
int rmdir(const char* pathname);
```

#### Get file list
```
// dirent.h

DIR* opendir(const char* name);
struct dirent* readdir(DIR* dirp);
int closedir(DIR* dirp);
```

```
struct dirent {
    ino_t d_ino;             // inode number
    off_t d_off;             // offset to the next dirent
    unsigned short d_reclen; // length of this record
    unsigned char d_type;    // type of file: 8 for regular file, 4 for directory
    char d_name[256];        // filename
};
```

```
#include <iostream>
#include <dirent.h>
using namespace std;

int main(int argc, char* agrv[]) {
    if (argc != 2) {
        cout << "Usage: " << argv[0] << " <directory>" << endl;
        return 1;
    }

    DIR* dir;

    if ((dir = opendir(argv[1])) == nullptr) {
        cout << "Failed to open directory: " << argv[1] << endl;
        return 1;
    }

    struct dirent* stdinfo = nullptr;
    while (1) {
        if ((stdinfo = readdir(dir)) == nullptr) {
            break;
        }

        cout << "filename: " << stdinfo->d_name << endl;
        cout << "file type: " << (int)stdinfo->d_type << endl;
    }

    closedir(dir);
}
```

#### access function
defined in `<unistd.h>` header file, checks the real user's permissions for the file.

```
#define R_OK 4 // Test for read permission
#define W_OK 2 // Test for write permission
#define X_OK 1 // Test for execute permission
#define F_OK 0 // Test for existence of file
```

```
// return 0 if the file exists and the user has the specified permission, otherwise return -1, errno is set.
int access(const char* pathname, int mode);
```

#### stat function
```
struct stat {
    dev_t st_dev;         // ID of device containing file
    ino_t st_ino;         // inode number
    mode_t st_mode;       // protection
    nlink_t st_nlink;     // number of hard links
    uid_t st_uid;         // user ID of owner
    gid_t st_gid;         // group ID of owner
    dev_t st_rdev;        // device ID (if special file)
    off_t st_size;        // total size, in bytes
    blksize_t st_blksize; // blocksize for file system I/O
    blkcnt_t st_blocks;   // number of 512B blocks allocated
    time_t st_atime;      // time of last access
    time_t st_mtime;      // time of last modification
    time_t st_ctime;      // time of last status change
};
```

st_mode, st_size, st_mtime can be used to check the file type, size, and modification time.

st_mode:
```
S_ISREG(mode)  // check if it is a regular file
S_ISDIR(mode)  // check if it is a directory
```

```
// sys/stat.h
int stat(const char* path, struct stat* buf);
```

```
#include <iostream>
#include <cstdio>
#include <cstring>
#include <sys/stat.h>
#include <unistd.h>

using namespace std;

int main(int argc, char* argv[]) {
    if (argc != 2) {
        cout << "Usage: " << argv[0] << " <file>" << endl;
        return 1;
    }

    struct stat buf;
    if (stat(argv[1], &buf) == -1) {
        cout << "Failed to get file information: " << argv[1] << " - " << strerror(errno) << endl;
        return 1;
    }

    if (S_ISREG(buf.st_mode)) {
        cout << "Regular file" << endl;
    }
    
    if (S_ISDIR(buf.st_mode)) {
        cout << "Directory" << endl;
    }

    return 0;
}
```

#### remove function
Defined in `<stdio.h>` header file.

```
int rename(const char* src, const char* dst);
```

### Error
#### strerror function
Defined in `<string.h>` header file.
```
char* strerror(int errnum); // not thread-safe
int strerror_r(int errnum, char* buf, size_t buflen); // thread-safe
```

```
#include <iostream>
#include <cstring>
using namespace std;

int main() {
    int i;

    for (i = 0; i < 150; i++) {
        cout << "Error " << i << ": " << strerror(i) << endl;
    }
}
```

#### perror function
Defined in `<stdio.h>` header file.
```
void perror(const char* s);
```

### Signal
#### Demo
```
>> ./demo
```

```
>> killall demo

>> killall -15 demo

>> killall -1 demo

>> killall -8 demo
```

killall: sends a signal to all processes with the specified name.  
kill: sends a signal to a process with the specified PID.

#### Signal handling
Three ways to handle signals:
- Ignore the signal.
- Use the default signal handler. (Most signals have a default action of terminating the process.)
- Use a custom signal handler.

#### Custom signal handler
```
#include <iostream>
#include <unistd.h>
#include <signal.h>

void signal_handler(int signum) {
    std::cout << "Received signal: " << signum << std::endl;
}

void signal_handler_reset_default(int signum) {
    std::cout << "Received signal: " << signum << std::endl;
    signal(signum, SIG_DFL);
}

int main() {
    signal(1, signal_handler);
    signal(2, signal_handler);
    signal(3, SIG_IGN);
    signal(4, signal_handler_reset_default);

    while (1) {
        std::cout << "Sleeping..." << std::endl;
        sleep(1);
    }

    return 0;
}
```

If we send two signales with 4, the first signal will be handled by the custom signal handler, and the second signal will be handled by the default signal handler.

#### Special signals
Signal 9 (SIGKILL) cannot be caught or ignored.

### Stop the Process
#### How to stop the process
- Use `return` in the main function.
- Call `exit` in any function.
- Call `_exit` or `_Exit` in any function.

#### Resource release
- When `return` is used, local objects' destructors are called. If it is called in main, global objects' destructors are called.
- When `exit` is called, global objects' destructors are called, but local objects' destructors are not called.
- `exit` does cleanup work (close the file, flush the cache), while `_exit` and `_Exit` do not do cleanup work or call the destructors.

#### Termination method of the process
We can use `atexit` to register a function that will be called when the process terminates. These functions are called by `exit`. The order of the functions is the reverse of the registration order.

```
int atexit(void (*function)(void));
```

```
using namespace std;

void f() {
    cout << "f()" << endl;
}

void g() {
    cout << "g()" << endl;
}

int main(int argc, char* argv[]) {
    atexit(f);
    atexit(g);

    return 0;
}
```

## Debugging
Use `gdb` or `lldb` to debug the program.  
Check GDB to LLDB command mapping: [GDB to LLDB command map](https://lldb.llvm.org/use/map.html)

### Start Debugging
```
>> g++ -g -o test test.cpp

>> gdb ./test
or
>> lldb ./test
```

### Set Arguments
```
(gdb) set args x y z

(lldb) settings set target.run-args x y z
```

### Breakpoints
```
(gdb) break main

(lldb) breakpoint set --name main
(lldb) br s -n main
(lldb) b main
```

```
(gdb) break test.cpp:14

(lldb) breakpoint set --file test.cpp --line 14
(lldb) br s -f test.cpp -l 14
(lldb) b test.cpp:14
```

### Run
```
(gdb) run
(gdb) r

(lldb) process launch
(lldb) run
(lldb) r
```

### Single Step Over (Source Level)
```
(gdb) next
(gdb) n

(lldb) thread step-over
(lldb) next
(lldb) n
```

### Single Step In (Source Level)
```
(gdb) step
(gdb) s

(lldb) thread step-in
(lldb) step
(lldb) s
```

### Single Step In (Instruction Level)
```
(gdb) stepi
(gdb) si

(lldb) thread step-inst
(lldb) si
```

### Continue
```
(gdb) continue

(lldb) process continue
(lldb) continue
(lldb) c
```

### Change Variable Value
```
(gdb) set var x = 10

(lldb) expr x = 10
```

or 
```
(gdb) p x = 10

(lldb) p x = 10
```

### Segmentation Fault
In Ubuntu the core dumps are handled by Apport, and can be located in `/var/crash` or `/var/lib/apport/coredump/`.

Check core file size.
```
>> ulimit -a (similar to uname -a)
-t: cpu time (seconds)              unlimited
-f: file size (blocks)              unlimited
-d: data seg size (kbytes)          unlimited
-s: stack size (kbytes)             <stack size>
-c: core file size (blocks)         <core file size>
-v: address space (kbytes)          unlimited
-l: locked-in-memory size (kbytes)  unlimited
-u: processes                       <processes>
-n: file descriptors                <file descriptors>
```

Set core file size to unlimited.
```
>> ulimit -c unlimited
```

Check the core file.
```
>> gdb test core
```

### Debugging the running process
```
>> ps -ef | grep test

>> gdb test -p <pid>
```

## Git
#### Discard local commits and overwrite local branch with the remote branch
```
>> git fetch
>> git reset --hard origin/main
```

## Nano
### Save and Exit
```
^O
Enter
^X
```

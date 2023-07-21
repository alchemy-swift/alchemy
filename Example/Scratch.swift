import Foundation

#if os(Linux)
import Glibc

func posix_openpt(_ oflag: Int32) -> Int32 {
    return open("/dev/ptmx", oflag)
}

func grantpt(_ fd: Int32) -> Int32 {
    return ioctl(fd, UInt(TIOCGPTPEER), (PTM_RDWR | O_NOCTTY | O_CLOEXEC))
}

func unlockpt(_ fd: Int32) -> Int32 {
    var unlock: Int32 = 0
    return ioctl(fd, UInt(TIOCSPTLCK), &unlock)
}

let TIOCGPTPEER: Int32 = 0x5441
let TIOCSPTLCK: Int32 = 0x40045431
let PTM_RDWR: Int32 = 0x0002

#else
import Darwin
#endif

/*
 passthru("sudo echo 'hello!'")
 passthru("git clone https://github.com/alchemy-swift/alchemy-examples")
 */

func passthru(_ command: String) {
    let masterFD = posix_openpt(O_RDWR | O_NOCTTY)
    if masterFD == -1 {
        print("Failed to open PTY")
        return
    }

    if grantpt(masterFD) == -1 {
        print("Failed to grantpt")
        return
    }

    if unlockpt(masterFD) == -1 {
        print("Failed to unlockpt")
        return
    }

    let slaveName = ptsname(masterFD)
    if slaveName == nil {
        print("Failed to get slave PTY name")
        return
    }

    var pid = pid_t()
    var fileActions: posix_spawn_file_actions_t?

    posix_spawn_file_actions_init(&fileActions)
    posix_spawn_file_actions_addopen(&fileActions, STDIN_FILENO, slaveName, O_RDWR, 0)
    posix_spawn_file_actions_adddup2(&fileActions, STDIN_FILENO, STDOUT_FILENO)
    posix_spawn_file_actions_adddup2(&fileActions, STDIN_FILENO, STDERR_FILENO)

    let argv = ["/bin/sh", "-c", command, nil].map { $0.flatMap { strdup($0) } }

    if posix_spawn(&pid, argv[0]!, &fileActions, nil, argv, environ) != 0 {
        print("Failed to spawn process")
        return
    }

    let masterHandle = FileHandle(fileDescriptor: masterFD, closeOnDealloc: true)

    while true {
        let data = masterHandle.availableData
        if data.isEmpty {
            break
        }

        if let str = String(data: data, encoding: .utf8) {
            print(str, terminator: "")
        }
    }

    var status = Int32()
    waitpid(pid, &status, 0)

    posix_spawn_file_actions_destroy(&fileActions)
    argv.forEach { free($0) }
}

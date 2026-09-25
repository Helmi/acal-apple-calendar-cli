import Darwin
import MachO

/// Makes acal its own "responsible process" for macOS TCC.
///
/// By default TCC attributes Calendar access to the process that launched acal (Terminal, bun,
/// Claude Desktop, a launchd job, ...). A grant made in one terminal therefore does not carry over
/// to agents or MCP clients, and hardened-runtime parents without the calendar entitlement get an
/// instant denial without a prompt. Re-executing ourselves with the private
/// `responsibility_spawnattrs_setdisclaim` spawn attribute makes TCC check `com.helmi.acal` itself,
/// so a single grant works from every caller.
enum ResponsibilityDisclaim {
    static let environmentKey = "ACAL_RESPONSIBILITY_DISCLAIMED"

    private typealias SetDisclaimFunction = @convention(c) (
        UnsafeMutablePointer<posix_spawnattr_t?>,
        Int32
    ) -> Int32

    /// Replaces the current process image with a disclaimed copy of itself (same pid, same file
    /// descriptors, same arguments). Returns only when the re-exec is skipped or fails, in which case
    /// acal continues with the inherited attribution.
    static func reexecIfNeeded() {
        guard getenv(environmentKey) == nil else { return }

        // RTLD_DEFAULT is `(void *)-2`; the macro is not importable into Swift.
        guard
            let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "responsibility_spawnattrs_setdisclaim"),
            let executablePath = currentExecutablePath()
        else { return }
        let setDisclaim = unsafeBitCast(symbol, to: SetDisclaimFunction.self)

        var attributes: posix_spawnattr_t?
        guard posix_spawnattr_init(&attributes) == 0 else { return }
        defer { posix_spawnattr_destroy(&attributes) }

        guard
            posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETEXEC)) == 0,
            setDisclaim(&attributes, 1) == 0
        else { return }

        setenv(environmentKey, "1", 1)
        var pid: pid_t = 0
        _ = posix_spawn(&pid, executablePath, nil, &attributes, CommandLine.unsafeArgv, environ)

        // Only reached if the re-exec failed.
        unsetenv(environmentKey)
    }

    private static func currentExecutablePath() -> String? {
        var size: UInt32 = 0
        _ = _NSGetExecutablePath(nil, &size)
        var buffer = [CChar](repeating: 0, count: Int(size) + 1)
        guard _NSGetExecutablePath(&buffer, &size) == 0 else { return nil }
        return String(cString: buffer)
    }
}

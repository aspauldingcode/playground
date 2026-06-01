# Plugin Playground

An open-source runtime tweak subsystem for macOS Apple Silicon.

Plugin Playground provides a framework for intercepting and modifying the behavior of
running processes at the kernel level — no `DYLD_INSERT_LIBRARIES`, no `ptrace`, no SIP
workarounds.  It's the foundation for building runtime plugins, introspection tools, and
behavior-modification tweaks on modern macOS.

## Core engine: syphon

The `syphon/` library is the low-level interception engine:

- **Mach exception ports** — receive kernel-delivered exceptions for breakpoints and traps
- **ARM64 hardware breakpoints** (DebugState64 `BVR`/`BCR`) — set execution breakpoints in
  any process without modifying code pages (avoids W^X and I-cache coherency issues on
  Apple Silicon shared-cache regions)
- **Per-thread state tracking** — safely manage concurrent breakpoint hits across multiple
  threads
- **Synchronous trapping** — the exception handler completes all work (reads registers,
  reads target memory, logs output) before replying, giving tweaks full control over
  the target process state during each trap

The engine is small, embeddable, and exposes a C API (`syphon.h`) for building custom
tweaks and tracers.

## Components

| Component | Description |
|-----------|-------------|
| `syphon/` | Core interception library — targets, breakpoints, exception handling, stepping state |
| `fangs`   | Reference tweak / tracer — attaches to launchd (PID 1), demonstrates `__posix_spawn` interception |
| `grant`   | Privilege helper — patches amfid so `task_for_pid` works for PID 1 (required once per boot) |
| `libsyphon.a` | Core interception library (not yet distributed) |

## Build

```sh
./build.sh
```

Binaries land in `.build/`:
- `.build/fangs`   — signed ad-hoc with `Master.entitlements`
- `.build/grant`   — unsigned
- `.build/libsyphon.a`

## Install

Build and install via the GUI installer:

```sh
sudo ./install.sh
sudo installer -pkg PluginPlayground-1.0.0.pkg -target /
```

Or install directly without the GUI:

```sh
sudo ./install.sh /opt/pluginplayground
```

Layout:

```
/opt/pluginplayground/
├── bin/
│   ├── fangs
│   └── grant
└── tweaks/       (user-owned, for runtime tweak bundles)
```

## Usage

```sh
# Terminal 1: patch amfid (once per boot), then launch fangs
sudo /opt/pluginplayground/bin/grant

# Terminal 2: or run fangs directly
sudo /opt/pluginplayground/bin/fangs
```

## Writing tweaks (internal)

The `syphon` library (not yet distributed) provides the C API for building custom tweaks.
See `syphon/syphon.h` in the source tree for the full API while it remains in-development.

## Project structure

```
├── build.sh                  Build script
├── install.sh                .pkg builder
├── CMakeLists.txt            CMake build
├── Master.entitlements       Required entitlements for process introspection
├── installer/                .pkg GUI resources (Distribution.xml, pages, background)
├── syphon/
│   ├── syphon.h              Public C API
│   ├── main.c                fangs entry point and event loop
│   ├── breakpoint.c          HW breakpoint install / clear / template
│   ├── mach_exc.c            send_reply, reset_exception_ports
│   ├── stepping.c            Per-thread stepping state
│   ├── target.c              Target address management
│   └── process.c             find_process helper
└── grant/
    ├── amfid_handler.h       amfid patch / unpatch API
    ├── amfid_handler.m       Objective-C amfid hook
    └── main.m                grant entry point
```

## Caveats

- **PID 1 is fragile.** The reference tweak (`fangs`) demonstrates interception on launchd.
  Bugs can freeze the system. Always keep a reboot method handy.
- **`grant` once per boot.** amfid state resets on reboot.
- **6 hardware breakpoint registers** on ARM64 (`BVR`/`BCR` 0–5).
- **Apple Silicon only.** The engine uses ARM64-specific debug register state.

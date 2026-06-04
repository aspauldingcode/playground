#pragma once
#include <string>

enum class DaemonStatus {
    NotInstalled,
    InstalledRunning,
    InstalledStopped,
};

std::string daemonStatusString(DaemonStatus s);

class DaemonManager {
public:
    static std::string plistPath();
    static DaemonStatus status();
    static bool install();
    static bool uninstall();
};

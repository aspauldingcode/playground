#!/bin/sh
set -eu

echo "[+] Uninstalling Plugin Playground..."

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run with sudo to uninstall system-wide files."
    exit 1
fi

echo "Removing Configurator application..."
rm -rf "/Applications/Plugin Playground.app"

echo "Removing core binaries..."
rm -rf "/opt/pluginplayground/bin"

echo "Forgetting package receipt..."
pkgutil --forget "com.pluginplayground.core" > /dev/null 2>&1 || true

echo "[+] Uninstallation complete."

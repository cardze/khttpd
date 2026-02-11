#!/bin/bash
set -e

# Build kernel module for the host kernel at runtime
echo "Building khttpd kernel module for host kernel..."
cd /khttpd
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

if [ ! -f /khttpd/khttpd.ko ]; then
    echo "Failed to build kernel module"
    exit 1
fi

# Load the kernel module
echo "Loading khttpd kernel module..."
insmod /khttpd/khttpd.ko port=${PORT:-8081}

# Check if module is loaded
if lsmod | grep -q khttpd; then
    echo "khttpd module loaded successfully on port ${PORT:-8081}"
else
    echo "Failed to load khttpd module"
    exit 1
fi

# Keep container running and monitor module
echo "khttpd is running. Press Ctrl+C to stop."
trap "echo 'Stopping khttpd...'; rmmod khttpd; exit 0" SIGINT SIGTERM

# Wait indefinitely
while true; do
    sleep 10
    # Check if module is still loaded
    if ! lsmod | grep -q khttpd; then
        echo "khttpd module was unloaded unexpectedly"
        exit 1
    fi
done

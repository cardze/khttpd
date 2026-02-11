# Use Ubuntu base image with kernel headers
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building kernel modules
RUN apt-get update && apt-get install -y \
    build-essential \
    kmod \
    linux-headers-generic \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /khttpd

# Copy source files
COPY . .

# Download http_parser files
RUN make http_parser.c

# Build htstress (userspace tool)
RUN make htstress

# Expose the default port
EXPOSE 8081

# Create entrypoint script that builds kernel module at runtime
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Build kernel module for the host kernel at runtime\n\
echo "Building khttpd kernel module for host kernel..."\n\
cd /khttpd\n\
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules\n\
\n\
if [ ! -f /khttpd/khttpd.ko ]; then\n\
    echo "Failed to build kernel module"\n\
    exit 1\n\
fi\n\
\n\
# Load the kernel module\n\
echo "Loading khttpd kernel module..."\n\
insmod /khttpd/khttpd.ko port=${PORT:-8081}\n\
\n\
# Check if module is loaded\n\
if lsmod | grep -q khttpd; then\n\
    echo "khttpd module loaded successfully on port ${PORT:-8081}"\n\
else\n\
    echo "Failed to load khttpd module"\n\
    exit 1\n\
fi\n\
\n\
# Keep container running and monitor module\n\
echo "khttpd is running. Press Ctrl+C to stop."\n\
trap "echo \"Stopping khttpd...\"; rmmod khttpd; exit 0" SIGINT SIGTERM\n\
\n\
# Wait indefinitely\n\
while true; do\n\
    sleep 1\n\
    # Check if module is still loaded\n\
    if ! lsmod | grep -q khttpd; then\n\
        echo "khttpd module was unloaded unexpectedly"\n\
        exit 1\n\
    fi\n\
done\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Run the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

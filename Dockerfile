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

# Set executable permission for entrypoint script
RUN chmod +x /khttpd/entrypoint.sh

# Run the entrypoint script
ENTRYPOINT ["/khttpd/entrypoint.sh"]

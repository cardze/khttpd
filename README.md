# khttpd

`khttpd` is an experimental HTTP server implemented as Linux kernel module.
The server defaults to port 8081, but this can be easily configured using
command line argument `port=?` when you are about to load the kernel module.

## Usage

### Running with Docker

The easiest way to run `khttpd` is using Docker. The Docker container builds the kernel module at runtime to match your host kernel:

```bash
# Build and run with docker-compose
docker-compose up --build

# Or build and run manually
docker build -t khttpd .
docker run --privileged -v /lib/modules:/lib/modules:ro -p 8081:8081 khttpd

# To use a custom port (note: both the host port mapping and PORT env var should match)
docker run --privileged -v /lib/modules:/lib/modules:ro -p 9000:9000 -e PORT=9000 khttpd
```

**Important Notes**:
- The `--privileged` flag is required because the container needs to load kernel modules
- The `-v /lib/modules:/lib/modules:ro` volume mount is required so the module can be built for your host kernel
- The kernel module is built at container startup to match your host's kernel version

### Testing the server

Once running, you can test the server with:

```bash
curl http://localhost:8081/
```

### Manual Installation

To build and run without Docker:

```bash
make
sudo insmod khttpd.ko
# Test with curl or the included stress tool
./htstress -n 1000 -c 1 -t 4 http://localhost:8081/
# Unload module when done
sudo rmmod khttpd
```

## TODO
* Release resources when HTTP connection is about to be closed.
* Introduce CMWQ.
* Improve memory management.
* Request queue and/or cache

## License

`khttpd` is released under the MIT License. Use of this source code is governed by
a MIT License that can be found in the LICENSE file. 

External source code:
* `http_parser.[ch]`: taken from [nodejs/http-parser](https://github.com/nodejs/http-parser)
  - Copyrighted by Joyent, Inc. and other Node contributors.
  - MIT License
* `htstress.c`: derived from [htstress](https://github.com/arut/htstress)
  - Copyrighted by Roman Arutyunyan
  - 2-clause BSD license

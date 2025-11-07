# NetBird ACAP for Axis Cameras

NetBird-ACAP packages [NetBird](https://netbird.io/) linux armv6 and arm64 binaries for the Axis Camera Application Platform. This allows AXIS cameras to join NetBird networks.

## Building
### Requirements
- Docker
- bash/sh
- curl
- jq

### Build Process
Edit the `build.sh` file to set the `NETBIRD_VERSION` to match the version to build.

```shell
./build.sh
```
This builds `.eap` packages for AXIS arm7hf and aarch64 platforms.

The script copies and configures the `app` template for each architecture. `manifest.json` is updated with the correct version and the NetBird binary is downloaded to the `lib` directory.

### Install and Configure

1. Access the Axis camera's web interface
2. Navigate to **Apps**
3. Allow unsigned apps
4. Click **Add App** and upload the `.eap` file
5. Click **Install**
6. Configure the following parameters:
    - **SetupKey** (required) - NetBird setup key
    - **ManagementURL** - NetBird management server URL (default: `https://api.netbird.io:443`)
    - **EnableLazyConnections** - Enable lazy peer connections (default: `no`)
7. Start the application


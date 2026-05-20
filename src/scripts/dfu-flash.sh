#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]
  then echo "ERROR: Please run as root"
  exit
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=./src/scripts/common.sh
source "$SCRIPT_DIR/common.sh"

MCU=$1
if [ "$MCU" == "" ]; then
	echo "ERROR: Please specify a device to flash"
	exit
fi
pushd "${KLIPPER_DIR}" || exit
service klipper stop
echo "Flashing DFU device"

# Create a local wrapper for dfu-util to intercept and strip ':leave' and '-R' from Klipper's Makefile call.
# This prevents the instant USB transceiver shutdown that leads to broken pipe errors during the download verification stage.
mkdir -p /tmp/dfu-wrapper
cat << 'EOF' > /tmp/dfu-wrapper/dfu-util
#!/usr/bin/env bash
REAL_DFU_UTIL=$(which -a dfu-util | grep -v "/tmp/dfu-wrapper" | head -n1)
if [ -z "$REAL_DFU_UTIL" ]; then
    REAL_DFU_UTIL="/usr/bin/dfu-util"
fi

ARGS=()
for arg in "$@"; do
    if [ "$arg" == "-R" ]; then
        # Decouple the reset flag during the main payload download block to prevent broken pipe
        continue
    fi
    # Strip the ':leave' suffix from the jump start address
    clean_arg="${arg//:leave/}"
    ARGS+=("$clean_arg")
done

exec "$REAL_DFU_UTIL" "${ARGS[@]}"
EOF
chmod +x /tmp/dfu-wrapper/dfu-util

# Prep PATH to use our interceptor wrapper
ORIG_PATH="$PATH"
export PATH="/tmp/dfu-wrapper:$PATH"

# Run the Klipper make flash command
make flash FLASH_DEVICE=0483:df11
make_exit_code=$?

# Restore original PATH and clean up the wrapper
export PATH="$ORIG_PATH"
rm -rf /tmp/dfu-wrapper

if [ $make_exit_code -ne 0 ]; then
    echo "Flashing failed at compile or make flash stage :("
    service klipper start
    popd || exit
    exit 1
fi

chown "${RATOS_USERNAME}":"${RATOS_USERGROUP}" -R "${KLIPPER_DIR}"

# Trigger decoupled hardware re-initialization reset sequence separately
echo "Payload written successfully. Sending reset signal to MCU..."
/usr/bin/dfu-util -d 0483:df11 -a 0 -R >/dev/null 2>&1

# Post-flash asynchronous polling delay loop to allow port topology to naturally re-populate
echo "Waiting for physical USB topology to detach, reset, and re-populate..."
sleep 3

DEVICE_FOUND=false
for i in {1..10}; do
    if [ -h "$MCU" ] || [ -e "$MCU" ]; then
        DEVICE_FOUND=true
        break
    fi
    sleep 1
done

if [ "$DEVICE_FOUND" = false ]; then
    # Follow-up verification sweep checking for target signature under /dev/serial/by-id/
    echo "Symlink not found at $MCU. Scanning /dev/serial/by-id/ for Klipper signatures..."
    KLIPPER_NODE=$(ls /dev/serial/by-id/*Klipper* 2>/dev/null | head -n1)
    if [ -n "$KLIPPER_NODE" ]; then
        echo "Verified Klipper device node at: $KLIPPER_NODE"
        DEVICE_FOUND=true
    fi
fi

if [ "$DEVICE_FOUND" = true ]; then
    echo "Flashing Successful!"
else
    echo "Flashing failed: target device signature did not populate in time :("
    service klipper start
    popd || exit
    exit 1
fi

service klipper start
popd || exit


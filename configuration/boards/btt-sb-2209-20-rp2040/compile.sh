#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]
  then echo "ERROR: Please run as root"
  exit
fi
cp -f /home/pi/printer_data/config/RatOS/boards/btt-sb-2209-20-rp2040/firmware.config /home/pi/klipper/.config
pushd /home/pi/klipper || exit
make olddefconfig
make clean
make out/klipper.uf2

if [ ! -d "/home/pi/printer_data/config/firmware_binaries" ]
then
    mkdir /home/pi/printer_data/config/firmware_binaries
    chown pi:pi /home/pi/printer_data/config/firmware_binaries
fi
cp -f /home/pi/klipper/out/klipper.uf2 /home/pi/printer_data/config/firmware_binaries/firmware-btt-sb-2209-20-rp.uf2
chown pi:pi /home/pi/printer_data/config/firmware_binaries/firmware-btt-sb-2209-20-rp.uf2
popd || exit

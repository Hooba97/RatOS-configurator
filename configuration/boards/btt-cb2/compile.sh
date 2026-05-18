#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
  then echo "ERROR: Please run as root"
  exit
fi

pushd /home/pi/klipper || exit
echo "flashing cb2-mcu"
cp -f /home/pi/printer_data/config/RatOS/boards/btt-cb2/firmware.config /home/pi/klipper/.config
make olddefconfig
make clean
# Reset ownership
chown pi:pi -R /home/pi/klipper
popd || exit

#!/bin/bash
# Run powertop --auto-tune but disable autosuspend for USB HID devices,
# because most of them become unusable with autosuspend.

# Script was from https://askubuntu.com/a/1026527/623103
powertop --auto-tune
HIDDEVICES=$(ls /sys/bus/usb/drivers/usbhid | grep -oE '^[0-9]+-[0-9\.]+' | sort -u)
for i in $HIDDEVICES; do
  echo -n "Enabling " | cat - /sys/bus/usb/devices/$i/product
  echo 'on' > /sys/bus/usb/devices/$i/power/control
done

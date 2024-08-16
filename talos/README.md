## Update Turing Pi 2 BMC Firmware

* https://docs.turingpi.com/docs/turing-pi2-bmc-v1x-to-v2x

```shell
# download latest turingpi firmware
# - source: https://firmware.turingpi.com/turing-pi2
curl -LO https://firmware.turingpi.com/turing-pi2/v2.0.5/tp2-firmware-sdcard-v2.0.5.img

# Write firmware to microsd card
# - this command works on mac and linux
# - replace your firmware file name and disk path with your actual file and disk
# - use extreme caution this command can cause permanent data loss, mistakes can be costly
sudo dd if=tp2-firmware-sdcard-v2.0.5.img of=/dev/disk6 conv=sync bs=32k status=progress

# Insert microsd card on bottom of Turing Pi 2 board & power on
# Press the power button 3x after you observe all nic led lights solid on indicating it is ready to flash
# Node will auto reboot

# SSH to BMC
# root:turing
ssh root@turingpi
```

## Flash Talos image to RK1

* SSH to BMC

```shell
# Download Talos metal rk1 arm64 image
# - source: https://github.com/nberlee/talos/releases
cd /mnt/sdcard
curl -LOk https://github.com/nberlee/talos/releases/download/v1.7.6/metal-turing_rk1-arm64.raw.xz

# Extract the xz compressed image
unxz /mnt/sdcard/metal-turing_rk1-arm64.raw.xz

# Flash the four nodes
tpi flash --local --image-path /mnt/sdcard/metal-turing_rk1-arm64.raw --node 1
tpi flash --local --image-path /mnt/sdcard/metal-turing_rk1-arm64.raw --node 2
tpi flash --local --image-path /mnt/sdcard/metal-turing_rk1-arm64.raw --node 3
tpi flash --local --image-path /mnt/sdcard/metal-turing_rk1-arm64.raw --node 4
```

## Boot all 4 nodes

```shell
tpi power on --node 1
tpi power on --node 2
tpi power on --node 3
tpi power on --node 4
```

Give these nodes a couple minutes to start up so you can collect the entire uart log output in one command.

## Pull serial uart console to find each node's IP address

```shell
tpi uart --node 1 get | tee /mnt/sdcard/uart.1.log | grep "assigned address"
tpi uart --node 2 get | tee /mnt/sdcard/uart.2.log | grep "assigned address"
tpi uart --node 3 get | tee /mnt/sdcard/uart.3.log | grep "assigned address"
tpi uart --node 4 get | tee /mnt/sdcard/uart.4.log | grep "assigned address"
```

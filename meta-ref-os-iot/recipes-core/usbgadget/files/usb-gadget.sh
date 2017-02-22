#!/bin/sh

loaded_ok=0
host_mac="42:48:21:09:60:40"
dev_mac="e2:fe:55:4d:63:17"
dev_ip="169.254.2.2"
idVendor="0x8086"
idProduct="0x0104"
serialnumber=$(cat /sys/devices/virtual/dmi/id/product_serial)
manufacturer="Intel Corp."
product="Intel Device"
configuration="CDC ACM+ECM"
declare -a mmcdevices=("mmcblk0" "mmcblk1")

start()
{
    mmcdevice=""
    for i in "${mmcdevices[@]}"
    do
        if [ -f /sys/block/$i/device/type ]; then
            if grep -xq SD "/sys/block/$i/device/type"; then
                mmcdevice=$i
                break
            fi
        fi
    done
    modprobe configfs
    modprobe libcomposite
    sleep 1
    mkdir -p /sys/kernel/config/usb_gadget/g1
    mkdir -p /sys/kernel/config/usb_gadget/g1/configs/c.1
    if [ ! -z "$mmcdevice" ]; then
        mkdir -p /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0
        echo "/dev/$mmcdevice" > /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0/lun.0/file
        ln -s /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0 /sys/kernel/config/usb_gadget/g1/configs/c.1
    fi
    mkdir -p /sys/kernel/config/usb_gadget/g1/functions/acm.GS0
    mkdir -p /sys/kernel/config/usb_gadget/g1/functions/ecm.usb0
    mkdir -p /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409
    mkdir -p /sys/kernel/config/usb_gadget/g1/strings/0x409
    echo "${idVendor}" > /sys/kernel/config/usb_gadget/g1/idVendor
    echo "${idProduct}" > /sys/kernel/config/usb_gadget/g1/idProduct
    echo "${serialnumber}" > /sys/kernel/config/usb_gadget/g1/strings/0x409/serialnumber
    echo "${manufacturer}" > /sys/kernel/config/usb_gadget/g1/strings/0x409/manufacturer
    echo "${product}" > /sys/kernel/config/usb_gadget/g1/strings/0x409/product
    echo "${host_mac}" > /sys/kernel/config/usb_gadget/g1/functions/ecm.usb0/host_addr
    echo "${dev_mac}" > /sys/kernel/config/usb_gadget/g1/functions/ecm.usb0/dev_addr
    echo "${configuration}" > /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration
    ln -s /sys/kernel/config/usb_gadget/g1/functions/acm.GS0 /sys/kernel/config/usb_gadget/g1/configs/c.1
    ln -s /sys/kernel/config/usb_gadget/g1/functions/ecm.usb0 /sys/kernel/config/usb_gadget/g1/configs/c.1
    echo $(ls /sys/class/udc) > /sys/kernel/config/usb_gadget/g1/UDC
    sleep 1
    ifconfig usb0 "${dev_ip}" netmask 255.255.255.0
    ifconfig usb0 up
    exit 0
}

stop()
{
    echo "" > /sys/kernel/config/usb_gadget/g1/UDC
    ifconfig usb0 down
    unlink /sys/kernel/config/usb_gadget/g1/configs/c.1/acm.GS0
    unlink /sys/kernel/config/usb_gadget/g1/configs/c.1/ecm.usb0
    unlink /sys/kernel/config/usb_gadget/g1/configs/c.1/mass_storage.0
    exit 0
}

$1


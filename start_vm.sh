# Change these paths appropriately, here I am putting all relevant files in ~/debianQemuVM.
# But you could probably share `initrd.img` and `vmlinuz` between different VM instances.
initrdPath=$HOME/debianQemuVM/initrd.img-5.10.0-18-arm64
vmlinuzPath=$HOME/debianQemuVM/vmlinuz-5.10.0-18-arm64
diskImagePath=$HOME/debianQemuVM/debian11-5.10.0-18-arm64.qcow2


# On M1 Macs, can add -accel hvf and change to -cpu max to boost performance
# https://stackoverflow.com/questions/66819049/qemu-system-aarch64-accel-hvf-invalid-accelerator-hvf
# https://www.sevarg.net/2021/01/09/arm-mac-mini-and-boinc/
# https://airbus-seclab.github.io/qemu_blog/

qemu-system-aarch64 -M virt -cpu cortex-a53 -m 1G -initrd $initrdPath \
    -kernel $vmlinuzPath -append "root=/dev/vda2 console=ttyAMA0" \
    -drive if=virtio,file=$diskImagePath,format=qcow2,id=hd \
    -net user,hostfwd=tcp::10022-:22 -net nic \
    -nographic # -device intel-hda -device hda-duplex

# To shutdown the VM cleanly, execute
#     /sbin/shutdown -P 0
# as root (or sudo)

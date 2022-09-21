# Change these paths appropriately, here I am putting all relevant files in ~/debianQemuVM.
# But you could probably share `initrd.img` and `vmlinuz` between different VM instances.
initrdPath=$HOME/debianQemuVM/initrd.img-5.10.0-18-arm64
vmlinuzPath=$HOME/debianQemuVM/vmlinuz-5.10.0-18-arm64
diskImagePath=$HOME/debianQemuVM/debian11-5.10.0-18-arm64.qcow2

qemu-system-aarch64 -M virt -cpu cortex-a53 -m 1G -initrd $initrdPath \
    -kernel $vmlinuzPath -append "root=/dev/vda2 console=ttyAMA0" \
    -drive if=virtio,file=$diskImagePath,format=qcow2,id=hd \
    -net user,hostfwd=tcp::10022-:22 -net nic \
    -nographic # -device intel-hda -device hda-duplex

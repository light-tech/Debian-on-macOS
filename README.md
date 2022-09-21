# Running ARM64 Debian 11 on macOS via qemu

The first guide I found was [the one on Debian wiki](https://wiki.debian.org/Arm64Qemu).
The advantage is that there is no need to spend time installing Debian but only Debian 9 and 10 are available.
This guide uses `nbd` to edit the images, which feels nicer than `libguestfs-tools`.
However, to my knowledge, `nbd` client is only available on Linux machine.
To follow this guide on macOS, one can download [`QEMU_EFI.fd`](https://github.com/hoobaa/qemu-aarc64/raw/master/QEMU_EFI.fd) directly.

Then I found [this instruction](http://phwl.org/2022/qemu-aarch64-debian/) that allows us to install latest Debian and felt like easier to make it work on macOS.
I couldn't be so wrong. The unfortunate part in this guide is that compiling [libguestfs](https://libguestfs.org/) is truly a pain on macOS.
With `--enable-daemon=no --disable-appliance --with-distros=none --with-qemu=qemu-system-aarch64`, the library depends on [cdrtools](http://cdrtools.sourceforge.net/private/cdrecord.html), [xz](https://tukaani.org/xz/),  [ncurses](https://invisible-mirror.net/archives/ncurses/), [pcre2](https://github.com/PCRE2Project/pcre2), [augeas](http://augeas.net/) which needs [libxml2](http://xmlsoft.org/download/), [libmagic](https://github.com/file/file), [jansson](https://github.com/akheron/jansson), [hivex](https://github.com/libguestfs/hivex) which does not come with pre-generated `configure` script so we needs `autoconf`, `automake`, `libtool`, `m4`, ... to generate `configure` and I give up at this point after a whole afternoon was wasted!

Now here is the smart part: I don't have to run the extraction on my own macOS machine.
So yeah, upload the 1.5GB `qcow2` file to Google Linux VM on the cloud and use `nbd` method in the previous guide.
Good thing is that we only need to do this once because once our Debian machine is up and running, we have access to Linux locally without reliance on Google!

The above two methods requires accessing files in the qcow2 image (adding SSH keys or extracting kernel).
I believe you could also use the UEFI boot (that is, just like a normal PC and similar to VirtualBox/VMWare) as well.
This [third guide](http://cdn.kernel.org/pub/linux/kernel/people/will/docs/qemu/qemu-arm64-howto.html) does not need that.
See also [this page](https://station.eciton.net/uefi-for-armarm64-on-qemu.html).

 1. Download [`mini.iso`, `debian-installer/arm64/linux` and `debian-installer/arm64/initrd.gz`](https://deb.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/netboot/).

 2. Create disk image and install Debian
    ```shell
    export DEBIAN_VM_IMAGE_NAME=debian11-5.10.0-18-arm64.qcow2

    qemu-img create -f qcow2 $DEBIAN_VM_IMAGE_NAME 32G

    qemu-system-aarch64 -M virt -cpu cortex-a53 -m 1G -kernel ./linux -initrd ./initrd.gz \
        -hda $DEBIAN_VM_IMAGE_NAME -append "console=ttyAMA0" \
        -drive file=mini.iso,id=cdrom,if=none,media=cdrom \
        -device virtio-scsi-device -device scsi-cd,drive=cdrom -nographic
    ```
    My convention is to use `debian$VERSION-$KERNEL_VERSION-arm64.qcow2` for the name of the disk image.

    Once the basic software is installed, you will see the message
    ```
    No boot loader has been installed, either because you chose not to or
    because your specific architecture doesn't support a boot loader yet.

    You will need to boot manually with the /vmlinuz kernel on partition
    /dev/vda1 and root=/dev/vda2 passed as a kernel argument.
    ```
    which is fine.

    Turn off the virtual machine by killing the terminal. (Can't Ctrl+C here!)

    Keep a compressed copy of the disk image just in case as well as save uploading time in the next step
    ```shell
    xz -9 -k $DEBIAN_VM_IMAGE_NAME
    ```

 3. Upload the compressed disk image to a Linux machine and decompress it. Then we can extract the kernel and initrd from it by
    ```shell
    sudo apt-get install qemu-utils qemu-efi-aarch64 qemu-system-arm
    sudo modprobe nbd
    sudo qemu-nbd -c /dev/nbd0 $DEBIAN_VM_IMAGE_NAME
    sudo mount /dev/nbd0p2 /mnt

    cp /mnt/boot/initrd.img-* ~
    cp /mnt/boot/vmlinuz-* ~

    sudo umount /mnt
    sudo qemu-nbd -d /dev/nbd0
    ```
    _Note_: In the 4th command, `nbd0p2` might be `nbd0p1` if you choose to have only one partition during installation.

    Copy the two files back to your Mac.

 4. Now we can launch the virtual machine with
    ```shell
    qemu-system-aarch64 -M virt -cpu cortex-a53 -m 1G -initrd initrd.img-5.10.0-18-arm64 \
        -kernel vmlinuz-5.10.0-18-arm64 -append "root=/dev/vda2 console=ttyAMA0" \
        -drive if=virtio,file=$DEBIAN_VM_IMAGE_NAME,format=qcow2,id=hd \
        -net user,hostfwd=tcp::10022-:22 -net nic \
        -device intel-hda -device hda-duplex -nographic
    ```
    _Note_: `/dev/vda2` could be `/dev/vda1` in case you have only one partition.

    For convenience, we have the script [`start_vm.sh`](start_vm.sh) to avoid typing/copying the above long command.
    (Change it appropriately before use though.)

 5. You can now SSH into the machine
    ```shell
    ssh -Y $YOUR_VM_USER_NAME@localhost -p 10022
    ```

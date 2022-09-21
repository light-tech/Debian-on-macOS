# Running ARM64 Debian 11 on macOS via qemu

Many times, it is desirable to have access to Linux (ARM64) on a Mac.
For example, we can build software for the Raspberry Pi, faster than building on the Pi itself.

The first guide I found was [the one on Debian wiki](https://wiki.debian.org/Arm64Qemu).
The advantage is that there is no need to spend time installing Debian but only Debian 9 and 10 are available.

Then I found [this instruction](http://phwl.org/2022/qemu-aarch64-debian/) that allows us to install latest Debian and felt like easier to make it work on macOS.
I couldn't be so wrong: compiling [libguestfs](https://libguestfs.org/) is truly a pain on macOS.

Both method depends on one crucial thing: access to files in the `qcow2` disk image file.

Here is the smart part: I don't have to run the extraction on my own macOS machine.
So yeah, upload the 1.5GB `qcow2` file to Google Linux VM on the cloud and use `nbd` method in the previous guide.
Good thing is that we only need to do this once because once our Debian machine is up and running, we have access to Linux locally without reliance on Google!

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

    Once installation completes, turn off the virtual machine by killing the terminal. (Can't Ctrl+C here!)

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
    _Note_:
      * `/dev/vda2` could be `/dev/vda1` in case you have only one partition.
      * On M1 Macs, change the CPU to `-cpu max` and add `-accel hvf` and possibly increase the memory to `2G` to achieve near native performance.

    For convenience, we have the script [`start_vm.sh`](start_vm.sh) to avoid typing/copying the above long command.
    Change it appropriately before use.

 5. You can now SSH into the machine
    ```shell
    ssh -Y $YOUR_VM_USER_NAME@localhost -p 10022
    ```

 6. To shutdown the VM cleanly, switch to `root` (su) and then execute
    ```shell
    /sbin/shutdown -P 0
    ```
    or `sudo` but you will have to [set it up](https://linuxize.com/post/how-to-add-user-to-sudoers-in-debian/) first.

### Other things

  * [This SO question](https://stackoverflow.com/questions/66819049/qemu-system-aarch64-accel-hvf-invalid-accelerator-hvf) leads to [this post](https://www.sevarg.net/2021/01/09/arm-mac-mini-and-boinc/) which gives another guide to get Ubuntu running which do not need access to files in `qcow2` image so no Linux access is needed.
  * See [this](https://airbus-seclab.github.io/qemu_blog/) to understand more about the internal of qemu.
  * Our script [build_qemu.sh](build_qemu.sh) builds qemu on macOS if you do not want to use homebrew.

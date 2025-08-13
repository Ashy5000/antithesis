echo "Building..."
cd ~/dev/gpu
cd linux
echo " - Building the Linux kernel..."
make -j $(nproc) || { echo "Failed to build kernel!"; exit 1; }
echo " - Done."
echo " - Building QEMU..."
cd ../qemu/build
make -j $(nproc) || { echo "Failed to build qemu!"; exit 1; }
cd ../..
echo " - Done."
echo "Build complete."
echo "Connect GDB to localhost:1234 and use the 'c' command to start up the system."
./qemu/build/qemu-system-x86_64 -kernel linux/arch/x86_64/boot/bzImage -initrd initramfs.cpio.gz -nographic -append "console=ttyS0 nokaslr" -m 1024 -s -S -device antithesis

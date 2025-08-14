../deps/linux/arch/x86_64/boot/bzImage: ../deps/linux/drivers/gpu/drm/antithesis
	cd ../deps/linux; make -j $(nproc)

../deps/qemu/build/qemu-system-x86_64: ../deps/qemu/hw/misc/antithesis.c ../deps/qemu/build/Makefile
	cd ../deps/qemu/build; make -j $(nproc)

../deps/qemu/build/Makefile:
	cd ../deps/qemu; rm -rf build; ./configure

build: ../deps/linux/arch/x86_64/boot/bzImage ../deps/qemu/build/qemu-system-x86_64

vm: build
	echo "Connect GDB to localhost:1234 and use the 'c' command to start up the system."
	cd ../deps; ./qemu/build/qemu-system-x86_64 -kernel linux/arch/x86_64/boot/bzImage -initrd ./initramfs.cpio.gz -nographic -append "console=ttyS0 nokaslr" -m 1024 -s -S -device antithesis



../deps/linux/arch/x86_64/boot/bzImage: ../deps/linux/drivers/gpu/drm/antithesis
	# cd ../deps/linux; make -j $(nproc)
	cd ../deps/linux; make -j 10

../deps/qemu/build/qemu-system-x86_64: ../deps/qemu/hw/misc/antithesis.c ../deps/qemu/build/Makefile
	# cd ../deps/qemu/build; make -j $(nproc)
	cd ../deps/qemu/build; make -j 10

../deps/qemu/build/Makefile:
	cd ../deps/qemu; rm -rf build; ./configure

../deps/intramfs/usr/sbin/antithesis_example:
	cd api; zig build -Dexamples -Dtarget=x86_64-linux

../deps/initramfs.cpio: ../deps/intramfs/usr/sbin/antithesis_example
	cd ../deps/initramfs; find . | cpio -o -H newc --owner=+0:+0 > ../initramfs.cpio

verilog/gpu.json: verilog/gpu.sv
	cd verilog; yosys -D LEDS_NR=6 -p "read_verilog -sv gpu.sv; synth_gowin -top gpu -json gpu.json" || { echo "yosys failed!"; exit 1; }

verilog/pnrgpu.json: verilog/gpu.json
	cd verilog; nextpnr-himbaechel --json gpu.json --write pnrgpu.json --device GW1NR-LV9QN88PC6/I5 --vopt family=GW1N-9C --vopt cst=tangnano9k.cst --freq 27 || { echo "nextpnr failed!"; exit 1; }

verilog/pack.fs: verilog/pnrgpu.json
	cd verilog; gowin_pack --device GW1N-9C -o pack.fs pnrgpu.json || { echo "gowin_pack failed!"; exit 1; }

build: ../deps/linux/arch/x86_64/boot/bzImage ../deps/qemu/build/qemu-system-x86_64 ../deps/initramfs.cpio verilog/pack.fs

vm: build
	echo "Connect GDB to localhost:1234 and use the 'c' command to start up the system."
	cd ../deps; ./qemu/build/qemu-system-x86_64 -kernel linux/arch/x86_64/boot/bzImage -initrd ./initramfs.cpio -append "console=ttyS0 nokaslr" -m 1024 -s -S -device antithesis -vga none -serial stdio

synthesize: build
	cd verilog; openFPGALoader -b tangnano9k pack.fs || { echo "openFPGALoader failed!"; exit 1; }

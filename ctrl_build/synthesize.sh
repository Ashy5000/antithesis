cd ~/dev/gpu/verilog
# BOARD=tangnano9k
BOARD=tangprimer20k
# DEVICE=GW1NR-LV9QN88PC6/I5
DEVICE=GW2A-LV18PG256C8/I7
yosys -D LEDS_NR=6 -p "read_verilog -sv gpu.sv; synth_gowin -top gpu -json gpu.json" || { echo "yosys failed!"; exit 1; }
# nextpnr-himbaechel --json gpu.json --write pnrgpu.json --device $DEVICE --vopt family=GW1N-9C --vopt cst=$BOARD.cst --freq 27 || { echo "nextpnr failed!"; exit 1; }
nextpnr-himbaechel --json gpu.json --write pnrgpu.json --device $DEVICE --vopt family=GW2A-18C --vopt cst=wernher.cst --top=gpu || { echo "nextpnr failed!"; exit 1; }
# gowin_pack --device GW1N-9C -o pack.fs pnrgpu.json || { echo "gowin_pack failed!"; exit 1; }
gowin_pack --device GW2A-18C -o pack.fs pnrgpu.json || { echo "gowin_pack failed!"; exit 1; }
sudo openFPGALoader -b tangprimer20k pack.fs || { echo "openFPGALoader failed!"; exit 1; }

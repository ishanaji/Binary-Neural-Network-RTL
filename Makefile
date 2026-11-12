# Screener build targets. Run from this directory.
#   make test        run both provided testbenches with Icarus Verilog
#   make test P=4    run tb_bnn_top with 4 neurons per cycle
#   make lint        check your RTL with Verilator
#   make synth       synthesise for a Gowin LUT4 FPGA (Tang Nano) with Yosys
#   make synth FLATTEN=0   keep the module hierarchy (statistics per module)
#   make wave        open the last waveform in GTKWave
RTL ?= rtl
P   ?= 1
FLATTEN ?= 1
SYNTH_OPTS = $(if $(filter 0,$(FLATTEN)),-noflatten,)
SRC  = $(RTL)/popcount.v $(RTL)/bnn_neuron.v $(RTL)/bnn_top.v

.PHONY: test test_popcount test_neuron test_top lint synth wave clean
test: test_popcount test_neuron test_top

build:
	mkdir -p build

test_popcount: build
	iverilog -g2012 -o build/tb_popcount.vvp tb/tb_popcount.v $(RTL)/popcount.v
	vvp -n build/tb_popcount.vvp

test_neuron: build
	iverilog -g2012 -o build/tb_neuron.vvp tb/tb_neuron.v $(RTL)/popcount.v $(RTL)/bnn_neuron.v
	vvp -n build/tb_neuron.vvp

test_top: build
	iverilog -g2012 -P tb_bnn_top.P=$(P) -o build/tb_bnn_top.vvp tb/tb_bnn_top.v $(SRC)
	vvp -n build/tb_bnn_top.vvp

lint:
	verilator --lint-only -Wall -GP=$(P) --top-module bnn_top $(SRC)

synth: build
	yosys -q -p "read_verilog $(SRC); chparam -set P $(P) bnn_top; \
	  synth_gowin -top bnn_top $(SYNTH_OPTS); tee -o build/synth_P$(P).txt stat"
	@grep -E "Number of cells|LUT|ALU|DFF|RAM|MUX" build/synth_P$(P).txt

wave:
	gtkwave build/dump.vcd

clean:
	rm -rf build

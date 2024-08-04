
REPO_DIR = /home/shaun/repos/uart

PKG_DIR := $(REPO_DIR)/packages
ITF_DIR := $(REPO_DIR)/interfaces
RTL_DIR := $(REPO_DIR)/rtl
SIM_DIR := $(REPO_DIR)/sim
TCL_DIR := $(REPO_DIR)/tcl

SRCS += $(SIM_DIR)/tb_uart_pkg.sv

SRCS += $(ITF_DIR)/axi4_lite_if.sv

SRCS += $(RTL_DIR)/fifo/sp_ram.sv
SRCS += $(RTL_DIR)/fifo/rd_ptr.sv
SRCS += $(RTL_DIR)/fifo/wr_ptr.sv
SRCS += $(RTL_DIR)/fifo/fifo.sv
SRCS += $(RTL_DIR)/cdc_sync.sv
SRCS += $(RTL_DIR)/elastic_buffer.sv
SRCS += $(RTL_DIR)/skid_buffer.sv
SRCS += $(RTL_DIR)/uart_rx.sv
SRCS += $(RTL_DIR)/uart_tx.sv
SRCS += $(RTL_DIR)/uart_controller.sv
SRCS += $(RTL_DIR)/uart.sv

SRCS += $(SIM_DIR)/tb_uart_top.sv

COMP_ARGS += --incr --relax
COMP_ARGS += -L uvm

ELAB_ARGS += -L uvm

DEFINES := 

TOP = tb_uart_top

.PHONY: simulate
simulate: $(TOP)_snapshot.wdb

.PHONY: elaborate
elaborate: .elab.timestamp

.PHONY: compile
compile: .comp.timestamp

.PHONY: waves
waves:
	gtkwave dump.vcd

$(TOP)_snapshot.wdb: .elab.timestamp
	xsim $(TOP)_snapshot -tclbatch $(TCL_DIR)/xsim_cfg.tcl

.elab.timestamp: .comp.timestamp
	xelab -debug all $(ELAB_ARGS) -top $(TOP) -snapshot $(TOP)_snapshot
	touch .elab.timestamp

.comp.timestamp: $(SRCS)
	xvlog $(COMP_ARGS) $(DEFINES) --sv $(SRCS)
	touch .comp.timestamp

.PHONY: clean
clean:
	rm -rf *.jou *.log *.pb *.wdb xsim.dir
	rm -rf .*.timestamp

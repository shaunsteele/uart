
REPO_DIR = /home/shaun/repos/uart

PKG_DIR := $(REPO_DIR)/packages
ITF_DIR := $(REPO_DIR)/interfaces
RTL_DIR := $(REPO_DIR)/rtl
SIM_DIR := $(REPO_DIR)/sim
TCL_DIR := $(REPO_DIR)/tcl

SRCS += $(SIM_DIR)/tb_uart_pkg.sv
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

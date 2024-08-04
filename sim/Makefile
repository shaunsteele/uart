
REPO_DIR = /home/shaun/repos/uart

PKG_DIR := $(REPO_DIR)/packages
ITF_DIR := $(REPO_DIR)/interfaces
RTL_DIR := $(REPO_DIR)/rtl
SIM_DIR := $(REPO_DIR)/sim

SRCS += $(SIM_DIR)/tb_uart_pkg.sv
SRCS += $(SIM_DIR)/tb_uart_top.sv

COMP_ARGS := --incr --relax

DEFINES := 

TOP = tb_uart_top

.PHONY: simulate
simulate: $(TOP)_snapshot.wdb

.PHONY: elaborate
elaborate: .elab.timestamp

.PHONY: compile
compile: .comp.timestamp

# waves generation

$(TOP)_snapshot.wdb: .elab.timestamp
	xsim $(TOP)_snapshot -tclbatch xsim_cfg.tcl

.elab.timestamp: .comp.timestamp
	xelab -debug all -top $(TOP) -snapshot $(TOP)_snapshot
	touch .elab.timestamp

.comp.timestamp: $(SRCS)
	xvlog --sv $(COMP_ARGS) $(DEFINES) $(SRCS)
	touch .comp.timestamp

.PHONY: clean
clean:
	rm -rf *.jou *.log *.pb *.wdb xsim.dir
	rm -rf .*.timestamp

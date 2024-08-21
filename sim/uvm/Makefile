
REPO_DIR = /home/shaun/repos/uart

PKG_DIR := $(REPO_DIR)/packages
IP_DIR	:= $(REPO_DIR)/ip
ITF_DIR := $(REPO_DIR)/interfaces
RTL_DIR := $(REPO_DIR)/rtl
SIM_DIR := $(REPO_DIR)/sim/uvm
TCL_DIR := $(REPO_DIR)/tcl

FIFO_DIR := $(IP_DIR)/fifo/rtl

SRCS += $(SIM_DIR)/tb_uart_pkg.sv

SRCS += $(SIM_DIR)/uart_seq_item.sv
SRCS += $(SIM_DIR)/uart_sequence.sv
SRCS += $(SIM_DIR)/axi4_lite_driver.sv
SRCS += $(SIM_DIR)/axi4_lite_monitor.sv
SRCS += $(SIM_DIR)/axi4_lite_agent.sv
SRCS += $(SIM_DIR)/uart_scoreboard.sv
SRCS += $(SIM_DIR)/uart_env.sv
SRCS += $(SIM_DIR)/uart_test.sv

SRCS += $(ITF_DIR)/axi4_lite_if.sv

SRCS += $(FIFO_DIR)/sp_ram.sv
SRCS += $(FIFO_DIR)/rd_ptr.sv
SRCS += $(FIFO_DIR)/wr_ptr.sv
SRCS += $(FIFO_DIR)/fifo.sv

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

SIM_ARGS += -testplusarg UVM_VERBOSITY=UVM_LOW

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
	xsim $(TOP)_snapshot -tclbatch $(TCL_DIR)/xsim_cfg.tcl $(SIM_ARGS)

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

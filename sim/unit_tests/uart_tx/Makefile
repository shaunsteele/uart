# CocoTB Makefile

REPO_DIR := /home/shaun/repos/uart

# IF_DIR	:= $(REPO_DIR)/interfaces
PKG_DIR := $(REPO_DIR)/packages
RTL_DIR := $(REPO_DIR)/rtl
SIM_DIR := $(REPO_DIR)/sim/unit_tests/uart_tx

SIM ?= verilator
WAVEFILE = dump.vcd

EXTRA_ARGS += --trace --trace-structs
EXTRA_ARGS += -Wall

TOPLEVELLANG ?= verilog

VERILOG_SOURCES += $(RTL_DIR)/skid_buffer.sv
VERILOG_SOURCES += $(RTL_DIR)/uart_tx.sv

TOPLEVEL = uart_tx

MODULE = tb_uart_tx

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: waves
waves:
	gtkwave $(WAVEFILE)

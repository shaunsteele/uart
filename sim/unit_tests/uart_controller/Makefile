# CocoTB Makefile

REPO_DIR := /home/shaun/repos/uart

# IF_DIR	:= $(REPO_DIR)/interfaces
PKG_DIR := $(REPO_DIR)/packages
RTL_DIR := $(REPO_DIR)/rtl
SIM_DIR := $(REPO_DIR)/sim/unit_tests/uart_rx

SIM ?= icarus
WAVES = 1

TOPLEVELLANG ?= verilog

VERILOG_SOURCES += $(RTL_DIR)/uart_controller.sv

TOPLEVEL = uart_controller
WAVEFILE = sim_build/$(TOPLEVEL).fst

MODULE = tb_uart_controller

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: waves
waves:
	gtkwave $(WAVEFILE)

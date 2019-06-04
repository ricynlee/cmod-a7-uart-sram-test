# CMOD-A7 UART/SRAM test

> This project can be built with Xilinx&trade; Vivado&trade; 2018.2 Web Edition.

This is a loop-back UART test project. The CMOD-A7 module, connected to a Windows PC via a USB A-micro cable, "reflects" data coming from PC.

> USB-UART driver and PC host tool `sercomm.py` is provided in this repo.

The UART interface runs at the maximum 12MBaud. The on-board SRAM functions as a first-word-fall-through FIFO for the (though it may be unnecessary).
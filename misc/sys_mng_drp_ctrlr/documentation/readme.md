# sys_mng_drp_ctrlr

Component for read RAW data of temperature, voltage from Xilinx UltraScale System Manager (or SystemMonitor). Read From registers which declarated in UG580 

![sys_mng_drp_ctrlr_struct][sys_mng_drp_ctrlr_struct_link]

[sys_mng_drp_ctrlr_struct_link]:https://github.com/MasterPlayer/xilinx-sv/blob/main/misc/sys_mng_drp_ctrlr/documentation/sys_mng_drp_ctrlr_struct.png

## Ports 

### Clock and Reset signals 

Name | Direction | Width | Description
-----|-----------|-------|-----------
CLK | input | 1 | clock signal 
RESET | input | 1 | syncronous active high reset 

### Status signals

Name | Direction | Width | Description
-----|-----------|-------|-----------
TEMP | out | 16 | Current TEMP 16-bit value
TEMP_MAX | out | 16 | minimal TEMP 16-bit value after reset
TEMP_MIN | out | 16 | maximal TEMP 16-bit value after reset
VCCINT | out | 16 | Current VCCINT 16-bit value
VCCINT_MAX | out | 16 | minimal VCCINT 16-bit value after reset
VCCINT_MIN | out | 16 | maximal VCCINT 16-bit value after reset
VCCAUX | out | 16 | Current VCCAUX 16-bit value
VCCAUX_MAX | out | 16 | minimal VCCAUX 16-bit value after reset
VCCAUX_MIN | out | 16 | maximal VCCAUX 16-bit value after reset
VCCBRAM | out | 16 | Current VCCBRAM 16-bit value
VCCBRAM_MAX | out | 16 | minimal VCCBRAM 16-bit value after reset
VCCBRAM_MIN | out | 16 | maximal VCCBRAM 16-bit value after reset

### DRP Signal Group

This signal group for support DynamicReconfigurationProtocol support

Name | Direction | Width | Description
-----|-----------|-------|-----------
DRP_ADDR | out | 8 | Address of register which needs to reading 
DRP_DI | out | 16 | Data to remote component. Currently is 0
DRP_DO | in | 16 | Data readed from remote component
DRP_EN | out | 1 | Valid signal for operation start
DRP_RDY | in | 1 | Signal from remote component. With this signal valid data returns
DRP_WE | out | 1 | signal for writing to remote register. Currently is 0

## FSM

### FSM diagram 

![sys_mng_drp_ctrlr_fsm][sys_mng_drp_ctrlr_fsm_link]

[sys_mng_drp_ctrlr_fsm_link]:https://github.com/MasterPlayer/xilinx-sv/blob/main/misc/sys_mng_drp_ctrlr/documentation/sys_mng_drp_ctrlr_fsm.png

### FSM states

Current state | Next state | Condition
--------------|------------|----------
IDLE_ST | ESTABLISH_DRP_ADDR_ST | Absolute
ESTABLISH_DRP_ADDR_ST | WAIT_FOR_RDY_ST | Absolute
WAIT_FOR_RDY_ST | ESTABLISH_DRP_ADDR_ST | DRP_RDY=1

## Files

- sysmng_wrapper: for example how sys_mng_drp_ctrlr connects to system monitor core


## Change log

**1. 04.05.2021 : v1.0 - First Version**
- add description



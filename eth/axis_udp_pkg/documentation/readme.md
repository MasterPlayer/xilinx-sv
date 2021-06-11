# axis_udp_pkg_vs
_vs - variable size of packet_

Component for packaging input data and sending to out as UDP-packets. Additional information not inserted. Only Eth/IP/UDP header. UDP checksum not calculated in this module. 

## Generic 
Name | Type | Range | Description 
-----|------|-------|------------
MAX_SIZE | integer | 1...2^32 | maximum size of packet in words
N_BYTES | integer | 8 | data bus width
HEAD_WORD_LIMIT | integer | number of words for header or part of header
HEAD_PART | integer | 1..N_BYTES | number of bytes which used for last word of header
ASYNC_MODE | string | "FULL", "S_SIDE", "M_SIDE", "SYNC" | asyncronous mode selection for using internal fifos

Next table for information about which values establish for sending data without additional information and with only headers ETH/IP/UDP:
N_BYTES | HEAD_PART | HEAD_WORD_LIMIT
--------|-----------|----------------
8 | 6 | 5 

## Parameters 
Next table for calculation IPv4 size and calculate checksum
Name | Type | Range | Description 
-----|------|-------|------------
C_ADDITION_HEADER | integer | 0..2^32 | Addition header size in bytes
C_IPV4_HEADER | integer | 0..2^32 | IPv4 header size in bytes
C_UDP_HEADER | integer | 0..2^32 | UDP header size in bytes
C_HEADER_SIZE | integer | 0..2^32 | Total size for all headers (IP/UDP/addtn)

## Functional description 
- Component supports AXI-Stream interface
- Component perform packing data to UDP traffic
 - Component supports different clock domain scheme: 
1 `FULL` : S_AXIS_*, M_AXIS_* and internal logic in different clock domain
2 `S_SIDE` : `S_AXIS_*` works on `S_AXIS_CLK` clock domain, internal logic and `M_AXIS_*` works in `CLK` clock domain
3 `M_SIDE` : `S_AXIS` and internal logic works on `CLK` clock domain, `M_AXIS_` works in `M_AXIS_CLK` clock domain 
4 `SYNC` : `S_AXIS_*`, `M_AXIS_*` and internal logic works in `CLK` clock domain
- Component separates data to packets, if size of input packet exceeds `MAX_SIZE` words. 
- Component save packet structure, if size of input packet smaller `MAX_SIZE` value in words.
- Component calculates ipv4 checksum. 
- ARP table not presented in this component, data sends with `DEST_*` parameters 

## Change log 
**1. 11.06.2021 : v1.0 - First Version** 
- add component and small description 
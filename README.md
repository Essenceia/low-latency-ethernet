# Single socket TCP client

RTL implementation of a single socket `TCP` module prioritizing low latency, build for the `NASDAQ HFT FPGA` project.

## Requirements 

Because I am targetting a specific workload and because I wish to ultimatly push down lantency in part by
limiting the total logic depth, this implementation will not feature all `TCP` features.

Assumptions :

- No out of order packets 

- Remote server address and port will never change

- No packet segmentation
 
## Module list 

- `tcp_entry.v` : manages a single socket per entry module


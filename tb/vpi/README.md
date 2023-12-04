# RTL Network Stack C Testbench Code

This directory contains the `C` and `C++` code utilized for the primary
ethernet network stack, The objective of this code is, during simulation, drive
the values on the signals connected to the RTL implementation of the
`MAC/IPv4/UDP` network stack.

**Objective:**  Generate simulated layer 2 network packets and stream them to
the `RTL` logic using the custom physical layer interface. Additionally,
generate the expected output of the `UDP` module, and the `SystemVerilog` side
of the testbench will compare this expected output with the actual `RTL`
result. Any detected mismatches may indicate a bug.

:warning: This physical layer does not use the standard `(x|g)mii` interface!

## Build Test Application

In addition to the RTL testbench, we provide a recipe for a small test
application that mirrors the functionality of the RTL testbench, aiding in
debugging.

To build the test application for the `C` side of the testbench: 

```bash 
make test 
```

### Wireshark Dump

By default, `wireshark` dump is disabled. To enable dumping all generated
packets to a Wireshark-compatible format, invoke the makefile with the
`wireshark=1` flag.  

```bash 
make wireshark=1 test 
```

Refer to the [`README.md` of the Ethernet Packet Library](https://github.com/Essenceia/ethernet_packet_C_lib) 
for details on opening the generated `network_dump.hex` file in Wireshark.

### Debug Logs

By default, debug logs are disabled. To enable debug logs, add the `debug=1`
flag to the build.  

```bash 
make debug=1 test 
```

## Run Test Application

To run the test application, use: 

```bash 
./test 
```


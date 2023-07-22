# Low latency verilog ethernet for Nasdaq HFT FPGA

RTL implementation of a low latency ethernet interface for the purposes of the HFT FPGA project.

In order to help acheive a lower latency all features not stricktly necessary for our
use case will be stripped out. External users should assume this project will be re-usable 
for a different use case or that it is compliant with 802.3.

Our objective is to implement 2 different ethernet interface, each having a limited feature scope : 

- UDP : 
    rx for data stream and replayed messages only 
    tx for re-transmission request only

- TCP, single connection 


### PHY 

Features :

- 10GBASE-T

Assumptions :

- No need to support EEE ( clause 78 )  
    PCS control code LPI ( low power idle ) will be ~~treated as an error~~ ignored

### MAC

Features :

- XMII

Assumptions :

- Non compliance with 802.3 is okay 

- Full duplex interface only 

### UDP 

#### rx data stream

Features : 

- IPv4, no support for framgmentation

- only supports UDP, ignors all other packet types

Assumptions : 

- UDP packets containing MoldUDP64 datagrams will never be framgmented

#### tx retransmission request

Features : 

- IPv4

- all data will be packaged into an UDP packet

- all packets will be destined to the same destination

- No backpressure will be applied on UDP data provider

Assumptions : 

- UDP data provider will transmit data without holes or bubbles 

### TCP

Features : 

- IPv4

Assumptions : 

- ITCH server is located at a single designation address

- There will only be 1 connection alive at a time

### Common features and assumptions

Features and assumptions shared amoung all ethernet interface.

Features :

- IP is staticly defined 

- Gateway MAC is statically defined

Assumptions :

- Remote server address will never change 


# Low latency verilog ethernet for Nasdaq HFT FPGA

RTL implementation of a low latency ethernet interface for the purposes of the HFT FPGA project.

In order to help acheive a lower latency all features not stricktly necessary for our
use case will be stripped out. External users should assume this project will be re-usable 
for a different use case.

Our objective is to implement 3 different ethernet interface, each having only 1 function : 

- UDP for data stream only 

- UDP for re-transmission request only

- TCP, single connection 

## UDP data stream

Features : 

- rx only, no tx 

- IPv4, no support for framgmentation

- only supports UDP, ignors all other packet types

Assumptions : 

- UDP packets containing MoldUDP64 datagrams will never be framgmented

## UDP retransmission request

Features : 

- tx only, no rx

- IPv4

- all data will be packaged into an UDP packet

- all packets will be destined to the same destination

- No backpressure will be applied on UDP data provider

Assumptions : 

- UDP data provider will transmit data without holes or bubbles 

## TCP

Features : 

- IPv4

Assumptions : 

- ITCH server is located at a single designation address

- There will only be 1 connection alive at a time

## Common features and assumptions

Features and assumptions shared amoung all ethernet interface.

Features :

- IP is staticly defined 

- Gateway MAC is statically defined

Assumptions :

- Remote server address will never change 


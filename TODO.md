# TODO list

- create tb and connect rx and tx pipe to check for xprop
- crc :
    - update crc implementation to specify per byte
    data validity : needed to calculate crc when data
    valid len % crc\_data\_w != 0

- Write C libs for tb, need to support :
    - crc generation and check
    - mac packet generation
    - get output data per cycle

- rx tb:
    - test bypass funcitonality : wrong type/ error in mac
    - test cancel

- tx:
    - move mac footer from eth tx to it's own module
    - check if switch support IPG of zero, if not enforce IPG of >=96 ( 802.3 ) 

- tb:
    - cut packet into data width chunks
    - re-write mac interface ( reuse the one on the phy ? )
    - make a schematic to plan next work
    - move tb\_rand into utils lib 

- rtl:
    - add cancel signals
    - add start signals


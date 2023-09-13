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
    - write mechanism to stall new header when sending last
    term bytes from phy

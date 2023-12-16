# TODO list

- mac crc rtl :
    - update crc implementation to specify per byte
    data validity : needed to calculate crc when data
    valid len % crc\_data\_w != 0
    If anyone is reading this, I am NOT proud of the current
    mac crc module ... but other tasks have higher priority

- tx:
    - move mac footer from eth tx to it's own module
    
- homelab tb:
    - check if switch support IPG of zero, if not enforce IPG of >=96 ( 802.3 ) 

- tb:
    - drive expected udp output
    - add verilator support
    - move tb\_rand into utils lib 
    - add support for bubbles in data validity from PHY 
    - add cancels phy errors on mac interface to test cancel logic


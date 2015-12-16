# Namespace `PoC.net.ipv4`

The namespace `PoC.net.ipv4` offers an "Internet Protocol - Version 4" (IPv6) implementation. 


## Entities

 -  [`PoC.net.ipv4.TX`][net_ipv4_TX]
 -  [`PoC.net.ipv4.RX`][net_ipv4_RX]
 -  [`PoC.net.ipv4.FrameLoopback`][net_ipv4_FrameLoopback]
 -  [`PoC.net.ipv4.Wrapper`][net_ipv4_Wrapper]

 
 [net_ipv4_TX]:							ipv4_TX.vhdl
 [net_ipv4_RX]:							ipv4_RX.vhdl
 [net_ipv4_FrameLoopback]:	ipv4_FrameLoopback.vhdl
 [net_ipv4_Wrapper]:				ipv4_Wrapper.vhdl

## Internet Protocol - Version 4

The following ASCII art shows the basic structure of an IPv4 paket:

    Endianess: big-endian
    Alignment: 4 byte
    
    							Byte 0													Byte 1														Byte 2													Byte 3
    +----------------+---------------+--------------------------------+--------------------------------+--------------------------------+
    | IPVers. (0x04) | IHL(HeaderLen)| TypeOfService									| TotalLength																											|
    +----------------+---------------+--------------------------------+-------+------------------------+--------------------------------+
    | Identification																									|R DF MF| FragmentOffset																					|
    +--------------------------------+--------------------------------+-------+------------------------+--------------------------------+
    | TimeToLive										 | Protocol												| HeaderChecksum																									|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | SourceAddress																																																											|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | DestinationAddress																																																								|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | Options																																													 | Padding												|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | Payload																																																														|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
 
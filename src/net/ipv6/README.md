# Namespace `PoC.net.ipv6`

The namespace `PoC.net.ipv6` offers an "Internet Protocol - Version 6" (IPv6) implementation. 


## Entities

 -  [`PoC.net.ipv6.TX`][net_ipv6_TX]
 -  [`PoC.net.ipv6.RX`][net_ipv6_RX]
 -  [`PoC.net.ipv6.FrameLoopback`][net_ipv6_FrameLoopback]
 -  [`PoC.net.ipv6.Wrapper`][net_ipv6_Wrapper]

 
 [net_ipv6_TX]:							ipv6_TX.vhdl
 [net_ipv6_RX]:							ipv6_RX.vhdl
 [net_ipv6_FrameLoopback]:	ipv6_FrameLoopback.vhdl
 [net_ipv6_Wrapper]:				ipv6_Wrapper.vhdl

## Internet Protocol - Version 6

The following ASCII art shows the basic structure of an IPv6 paket:

    Endianess: big-endian
    Alignment: 8 byte
    
    							Byte 0													Byte 1														Byte 2													Byte 3
    +----------------+---------------+----------------+---------------+--------------------------------+--------------------------------+
    | IPVers. (0x06) | TrafficClass 							 		| FlowLabel																																				|
    +----------------+---------------+----------------+---------------+--------------------------------+--------------------------------+
    | PayloadLength																										| NextHeader										 | HopLimit												|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | SourceAddress																																																											|
    +                                +                                +                                +                                +
    |																																																																		|
    +                                +                                +                                +                                +
    |																																																																		|
    +                                +                                +                                +                                +
    |																																																																		|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | DestinationAddress																																																								|
    +                                +                                +                                +                                +
    |																																																																		|
    +                                +                                +                                +                                +
    |																																																																		|
    +                                +                                +                                +                                +
    |																																																																		|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | ExtensionHeader(s)																																																								|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | Payload																																																														|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+

 
# Namespace `PoC.net.icmpv4`

The namespace `PoC.net.icmpv4` offers an "Internet Control Message Protocol - Version 4" (ICMPv4) implementation.

The following ICMP message types are supported:

 -  **ECHO REPLY (0)**
 -  **ECHO REQUEST (8)**


 
## Package

*No files published, yet.*


## Entities

*No files published, yet.*


## Internet Control Message Protocol - Version 4

The following ASCII art shows the general bit-layout of an ICMP paket:

    Endianess: big-endian
    Alignment: 1 byte
    
    							Byte 0													Byte 1														Byte 2													Byte 3
    +================================+================================+================================+================================+
    | Type 							 						 | Code														| Checksum																												|
    +================================+================================+================================+================================+
    | Payload	(optional)																																																								|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    +================================+================================+================================+================================+
    
The following ASCII art shows a type 0 (echo reply) and type 8 (echo request) ICMP payload frame:
		
    ICMPv4 - Type = {0, 8} => echo reply, echo request
    
    							Byte 0													Byte 1														Byte 2													Byte 3
    +================================+================================+================================+================================+
    | SourceAddress 							 																																																			|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | DestinationAddress																																																								|
    +--------------------------------+--------------------------------+--------------------------------+--------------------------------+
    | 0x00 							 						 | Protocol												| Length																													|
    +================================+================================+================================+================================+
    | UDP header (see above)																																																						|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    +================================+================================+================================+================================+
    | Payload																																																														|
    ~                                ~                                ~                                ~                                ~
    |																																																																		|
    +================================+================================+================================+================================+

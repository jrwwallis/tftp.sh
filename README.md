# tftp.sh - Bash implementation of TFTP protocol

The bash shell is an unlikely choice of language in to implement network protocols.  However TFTP (the Trivial File Transfer Protocol) ([RFC1350](https://tools.ietf.org/html/rfc1350)) has a slightly unusual mandate:

- "TFTP is a very simple protocol used to transfer files."
- "It is designed to be small and easy to implement."

The common use-case for TFTP is in memory-constricted and other resource-constricted systems (e.g. early in bootstrap).  Thus implementing in bash can actually be a good fit due to the ubiquity of bash.  This project makes significant effort to minimize dependencies on external shell utilities.

Another consideration is performance.  bash is generally not optimsed for fast performance, and this again detracts from its usage for network protocol implementation.  However by virtue of the ping-pong nature of the TFTP protocol, performance bottlenecks will still most likely dominate in fundamental network delay, rather than implementation.

# tftp.sh - Bash implementation of TFTP protocol

The bash shell is an unlikely choice of language in which to implement network protocols.  However TFTP (the Trivial File Transfer Protocol) ([RFC1350](https://tools.ietf.org/html/rfc1350)) has a slightly unusual mandate:

- "TFTP is a very simple protocol used to transfer files."
- "It is designed to be small and easy to implement."

The common use-case for TFTP is in memory-constricted and other resource-constricted systems (e.g. early in bootstrap).  Thus implementing in bash can actually be a good fit due to the ubiquity of bash.  This project makes significant effort to minimize dependencies on external shell utilities.

Another consideration is performance.  bash is generally not optimsed for fast performance, and this again detracts from its usage for network protocol implementation.  However by virtue of the ping-pong nature of the TFTP protocol, performance bottlenecks will still most likely dominate in fundamental network delay, rather than implementation.

### Dependencies

1) This script.  The script size should be under 10k and must be under 20k.  This makes for easy pasting over e.g. a serial console.
1) The bash shell itself (/bin/bash).  Some advanced bash features are used, so bash version TBD or greater must be used.
1) /usr/bin/mkfifo.  Hopefully this can be replaced with bash coprocs
1) /usr/bin/nc. netcat is required for opening a listening UDP port for server operation.  Hopefully the bash /dev/udp can be used for the client implementation.
1) /usr/bin/od. Read and translate of binary octets from protocol headers.  This may be replacable with dd.
1) /bin/dd. Read and output of binary payload data.  Bash read is insufficient because NUL bytes cannot be stored in bash strings
1) /bin/rm. For deleting fifos.  Unnecesary if coprocs are used.
1) /bin/kill. This is generally a bash builtin, so the external utility should not be required.
1) Writable /tmp for named-pipe/fifo creation.  Again, hopefully this can be replaced with bash coprocs

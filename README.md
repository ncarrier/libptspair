# ptspair

## Overview

Event-loop friendly small library for creating a pair of connected pts.

## Compilation

Assumes PWD is the root of the unpacked archive. Adapt *BASE\_SRC\_DIR*'s value
to your needs.

        $ mkdir build
        $ cd build
        $ make -f ../Makefile BASE_SRC_DIR=..

Produces *libptspair.so* in the current directory. The header file is in the
*include/* directory.

## Usage

Please see *example/main.c* for an example on how to use it.  
To execute the example (assuming you're in the build/ directory):

        $ LD_LIBRARY_PATH=. ./ptspair

The name of the two created pts is displayed, one can open them with e.g.
*microcom*. What is typed into one should be displayed by the other.  
Then *Ctrl+C* to quit.  
The program is roughly equivalent to :

        $ socat -d -d pty,raw,echo=0 pty,raw,echo=0

## From a technical point of view

This library exposes a file descriptor from an epoll_create1 call. Two master
end for each pts are always registered for EPOLLIN events and when there is data
ready to be written to a pts, it's master fd is registered for EPOLLOUT events
also. A ring buffer of size *PTSPAIR\_BUFFER\_SIZE* (overridable at
compile-time) is attached to each pts. Reads from foo's master are stored to
bar's ring buffer, then bar's master starts listening to EPOLLOUT until it's
ring buffer is empty. And vice-versa if one swaps the roles of foo and bar.  
Note: a writer fd is opened for each slave, otherwise, the event loop will
trigger EPOLLHUP events as soon as one slave is closed by it's user.

## Licence

This library is published under the MIT licence, please see COPYING for more
details.


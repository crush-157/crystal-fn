# Writing a function without an FDK - Helper Pattern

This example demonstrates how to write functions in a language without
an FDK using a "Helper".

## Process
The process for running the function will be as follows:

1. Fn starts the Docker container for the function
2. As per the Dockerfile, the file containing the function code is executed
The "helper" code opens a UNIX socket in the container.  The path for the socket is read from an environment variable that Fn sets when it runs the container.
3. The "helper" code begins listening on the socket.
4. Fn sends the function payload over HTTP via the socket.
5. The "helper" code reads the input data from the socket and calls the actual (business) function code, passing it the input data.
6. The function returns the output.
7. The "helper" code sends the output back over HTTP via the socket.
8. The "helper" code continues to listen on the socket for repeat invocations until Fn terminates the function container.

In the process, the helper is carrying out some of the tasks that would
be performed by an FDK.  However, it does *not* provide all of the
capabilities of an FDK, and it is strongly preferred to use an FDK if one
is available.

## Example Overview

### Reverse big bang
The example walk through takes a "reverse - big - bang" approach,
starting with an "exploded view" which is admittedly verbose (but makes it
easy to see all the parts of the machinery separately).

Then the code will be refactored to make it more concise.

### http-stream
Note that the Fn server communicates with the Function in a container
using HTTP over UNIX sockets ("http - stream").

### Programming Language
The programming language used in this example is [Crystal](https://crystal-lang.org).
However, the approach should be applicable for any language.

### Code
The code for this example is all found in this repository under
[crystal-hello](./crystal-hello).

### Pre requisites
Before you start, please ensure that you have the following:
- A working [Oracle Functions]() or [Fn]() environment.
- Fn CLI configured so that you can deploy to that environment.
- Logging configured and tested.

## Building the Example

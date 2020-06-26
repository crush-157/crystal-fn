# Writing a function without an FDK - Helper Pattern

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
### Reverse big bang
The example walk through takes a "reverse - big - bang" approach,
starting with an "exploded view" which is admittedly verbose (but makes it
easy to see all the parts of the machinery separately).

Then the code will be refactored to make it more concise.

### http-stream
Note that the Fn server communicates with the Function in a container
using HTTP over UNIX sockets ("http - stream").

### Programming Language
The programming language used in this example is [Crystal](https://crystal-lang.org).
However, the approach should be applicable for any language.

### Code
The code for this example is all found in this repository under
[crystal-hello](./crystal-hello).

### Pre requisites
Before you start, please ensure that you have the following:

- A working [Oracle Functions](https://www.oracle.com/cloud/cloud-native/functions/) or [Fn](https://fnproject.io) environment.
- Fn CLI configured so that you can deploy to that environment.
- Logging configured and tested.
- An app created to deploy your function to (e.g. `no-fdk`)

## Building the Example


### Create `func.cr` and `Dockerfile`
  1. Create a directory for your function (e.g. `crystal-hello`).
  2. In that directory create a minimal file for your function `func.cr`:

  `STDERR.puts "HELP, I AM TRAPPED IN A CRYSTAL MAZE!"`

  3. Create a `Dockerfile` to run the "function"

  ```
  FROM crystallang/crystal
  RUN mkdir /tmp/crystal-cache
  ENV CRYSTAL_CACHE_DIR /tmp/crystal-cache
  WORKDIR /app
  COPY func.cr .
  RUN crystal build func.cr

  RUN mkdir -p /tmp/iofs
  CMD ./func
  ```

### Initialise and deploy the "function"
  
```
fn init
fn deploy --app no fdk
```
  
### Invoke the function
  
`fn invoke no-fdk crystal-hello`
  
It should fail, but you should see your error message in the log.
So now you know that Fn can start your function container and that you can see error 
messages.
  
### Creating the "exploded view"
Now edit `func.cr` to add meaningful code that follows the [process](# Process) described above:

```
require "socket"
require "file_utils"
require "http/server"
require "json"

# The Helper
class FnHelper
  getter(url : String) { ENV.fetch "FN_LISTENER", "unix:/tmp/iofs/lsnr.sock" }
  getter(socket_path : String) { url[5..] }
  getter(private_socket_path : String) { socket_path + ".private" }
  getter? linked : Bool = false

  getter(private_socket : UNIXServer) do
    UNIXServer.new private_socket_path
  end

  def link_socket_file
    File.chmod(private_socket_path, 0o666)
    FileUtils.ln_s(File.basename(private_socket_path), socket_path)
    @linked = true
  end

  def linked_socket
    unless linked?
      private_socket
      link_socket_file
    end
    private_socket
  end

  def handle(&block : JSON::Any -> String)
    server = HTTP::Server.new do |context|
      body = context.request.body.try(&.gets_to_end)
      body = "{}" if body.try(&.empty?) || body.nil?
      context.response.content_type = "application/json"
      body.try { |b| context.response.print block.call JSON.parse b }
    end
    server.bind linked_socket
    server.listen
  end

  def self.handle(&block : JSON::Any -> String)
    FnHelper.new.handle &block
  end
end

# The function
my_proc = ->(input : JSON::Any) do
  name = input["name"]? || "world"
  %({"message": "Hello #{name}"})
end

# The helper handles the function
FnHelper.handle &my_proc
```
(see [exploded-view-func.cr](./crystal-hello/exploded-view-func.cr))
 
The code reads the `FN_LISTENER` environment variable and creates the socket.

The part about the `private_socket_path` is defensive - during development of some of the FDKs there was a race condition where Fn started writing to the socket before the function was ready.  So the code waits until the `private_socket` is available then links it to the path where Fn expects the socket.

Once the socket is available, the helper needs to listen to it. Something that listens for HTTP requests and sends responses back sounds like an HTTP server, so Crystal's built in `HTTP::Server` class is used to handle that part.

If you redeploy and invoke the function, it should reply to you:

```
$ fn invoke no-fdk crystal hello
{"message": "Hello world"}
$ echo '{"name":"Marvin"}' | fn invoke no-fdk crystal-hello
{"message": "Hello Marvin"}
```


### Shrink the Code #1

The code can be shrunk slightly by removing the `linked_socket` method:

```
require "socket"
require "file_utils"
require "http/server"
require "json"

class FnHelper
  getter(url : String) { ENV.fetch "FN_LISTENER", "unix:/tmp/iofs/lsnr.sock" }
  getter(socket_path : String) { url[5..] }
  getter(private_socket_path : String) { socket_path + ".private" }
  getter? linked : Bool = false

  getter(private_socket : UNIXServer) do
    UNIXServer.new private_socket_path
  end

  getter(linked_socket : UNIXServer) do
    private_socket.tap do |ps|
      ps.path.try do |path|
        File.chmod(path, 0o666)
        FileUtils.ln_s(File.basename(path), socket_path)
      end
    end
  end

  def handle(&block : JSON::Any -> String)
    server = HTTP::Server.new do |context|
      body = context.request.body.try(&.gets_to_end)
      body = "{}" if body.try(&.empty?) || body.nil?
      context.response.content_type = "application/json"
      body.try { |b| context.response.print block.call JSON.parse b }
    end
    server.bind linked_socket
    server.listen
  end

  def self.handle(&block : JSON::Any -> String)
    FnHelper.new.handle &block
  end
end

my_proc = ->(input : JSON::Any) do
  name = input["name"]? || "world"
  %({"message": "Hello #{name}"})
end

FnHelper.handle &my_proc
```
(see [tighter-func.cr](./crystal-hello/tighter-func.cr))


### Shrink the Code #2

The `private_socket_path` piece is still a bit ugly though :-(

Depending on how fast your helper starts listening you _may_ be able to skip it.

___YMMV / "here be dragons"___, but I have found with Crystal I can drop it, leaving just 15 lines of helper code:

```
require "http/server"
require "json"

module FnHelper
  def self.socket_path
    ENV.["FN_LISTENER"].try(&.[5..]) || "/tmp/iofs/lsnr.sock"
  end

  def self.handle(&block : JSON::Any -> String)
    server = HTTP::Server.new do |context|
      body = context.request.body.try(&.gets_to_end)
      body = "{}" if body.try(&.empty?) || body.nil?
      context.response.content_type = "application/json"
      body.try { |b| context.response.print block.call JSON.parse b }
    end
    server.bind UNIXServer.new socket_path
    server.listen
  end
end

my_proc = ->(input : JSON::Any) do
  name = input["name"]? || "world"
  %({"message": "Hello #{name}"})
end

FnHelper.handle &my_proc
```
(see [tight-func.cr](./crystal-hello/tight-func.cr))

## Summary
As stated before, this is *not* a fully fledged FDK, but it is a helper that can be used and reused to write functions in Crystal.

If you follow this pattern, you'll be able to write your functions in languages for which there is no FDK and run them on Oracle Functions service (or Fn).
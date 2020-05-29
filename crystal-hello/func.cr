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

  def handle
    server = HTTP::Server.new do |context|
      body = context.request.body.try(&.gets_to_end)
      STDERR.puts "server received body: #{body}"
      context.response.content_type = "application/json"
      context.response.print body
    end
    server.bind linked_socket
    server.listen
  end
end

f = FnHelper.new
f.handle

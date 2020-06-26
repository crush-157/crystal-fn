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

my_proc = ->(input : JSON::Any) do
  name = input["name"]? || "world"
  %({"message": "Hello #{name}"})
end

FnHelper.handle &my_proc

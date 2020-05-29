require "socket"
require "file_utils"
require "http/server"
require "json"

class FnHelper
  getter(socket_path : String) do
    ENV.["FN_LISTENER"].try(&.[5..]) || "unix:/tmp/iofs/lsnr.sock"
  end

  def handle(&block : JSON::Any -> String)
    server = HTTP::Server.new do |context|
      body = context.request.body.try(&.gets_to_end)
      body = "{}" if body.try(&.empty?) || body.nil?
      context.response.content_type = "application/json"
      body.try { |b| context.response.print block.call JSON.parse b }
    end
    STDERR.puts "socket_path: #{socket_path}"
    server.bind UNIXServer.new socket_path
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

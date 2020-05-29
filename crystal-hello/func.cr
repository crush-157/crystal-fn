require "http/server"
require "json"

module FnHelper
  def self.socket_path
    ENV.["FN_LISTENER"].try(&.[5..]) || "unix:/tmp/iofs/lsnr.sock"
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

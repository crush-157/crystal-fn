class FnHelper
  getter(url) { ENV["FN_LISTENER"]? }
  getter(socket_path : String) { url.try(&.[5..]) }
end

f = FnHelper.new
STDERR.puts "CRYSTAL RUNTIME"
STDERR.puts "url: #{f.url}"
STDERR.puts "socket_path: #{f.socket_path}"
STDERR.puts "f.inspect: #{f.inspect}"

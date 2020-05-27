class FnHelper
  getter(url) { ENV["FN_LISTENER"]? }
  getter(socket_path : String) { url.try(&.[5..]) }
  getter(private_socket_path : String) { socket_path.try(&. + ".private") }
end

f = FnHelper.new
STDERR.puts "CRYSTAL RUNTIME"
STDERR.puts "url: #{f.url}"
STDERR.puts "socket_path: #{f.socket_path}"
STDERR.puts "private_socket_path: #{f.private_socket_path}"
STDERR.puts "f.inspect: #{f.inspect}"

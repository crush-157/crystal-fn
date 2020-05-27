require "socket"
require "file_utils"

class FnHelper
  getter(url : String) { ENV.fetch "FN_LISTENER", "unix:/tmp/iofs/lsnr.sock" }
  getter(socket_path : String) { url[5..] }
  getter(private_socket_path : String) { socket_path + ".private" }
  getter? linked : Bool = false

  getter(private_socket : UNIXServer) do
    UNIXServer.new private_socket_path
  end

  def socket
    link_socket_file unless linked?
    private_socket
  end

  def link_socket_file
    File.chmod(private_socket_path, 0o666)
    FileUtils.ln_s(File.basename(private_socket_path), socket_path)
    @linked = true
  end
end

f = FnHelper.new
STDERR.puts "CRYSTAL RUNTIME"
STDERR.puts "url: #{f.url}"
STDERR.puts "socket_path: #{f.socket_path}"
STDERR.puts "private_socket_path: #{f.private_socket_path}"
STDERR.puts "private_socket: #{f.private_socket}"
STDERR.puts "linked: #{f.linked?}"
STDERR.puts "socket: #{f.socket}"
STDERR.puts "linked: #{f.linked?}"

STDERR.puts "f.inspect: #{f.inspect}"

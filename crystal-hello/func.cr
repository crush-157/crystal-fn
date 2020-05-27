class FnHelper
  getter(url) { ENV["FN_LISTENER"]? }

end

f = FnHelper.new
STDERR.puts "CRYSTAL RUNTIME"
STDERR.puts "f.url: #{f.url}"

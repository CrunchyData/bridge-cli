require "base64"

filename = ARGV[0]

begin
  puts Base64.encode File.read(filename)
rescue e : File::Error
  STDERR.puts e.message
  exit 1
end

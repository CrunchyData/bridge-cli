require "./action"

class CB::Login < CB::Action
  def run
    host = CB::HOST

    raise CB::Program::Error.new "No valid credentials found. Please login." unless output.tty?
    hint = "from https://www.crunchybridge.com/account" if host == "api.crunchybridge.com"
    output.puts "add credentials for #{host.colorize.t_name} #{hint}>"
    output.print "  application ID: "
    id = input.gets
    if id.nil? || id.empty?
      STDERR.puts "#{"error".colorize.red.bold}: application ID must be present"
      exit 1
    end

    print "  application secret: "
    secret = input.noecho { input.gets }
    output.print "\n"
    if secret.nil? || secret.empty?
      STDERR.puts "#{"error".colorize.red.bold}: application secret must be present"
      exit 1
    end

    Creds.new(host, id, secret).store
  end
end

require "./action"

class CB::Login < CB::Action
  def run
    host = CB::HOST

    raise CB::Program::Error.new "No valid credentials found. Please login." unless output.tty?
    hint = "from https://www.crunchybridge.com/account" if host == "api.crunchybridge.com"
    output.puts "add credentials for #{host.colorize.t_name} #{hint}"

    output.print "  application secret: "
    secret = input.noecho { input.gets }

    if secret.nil? || secret.empty?
      STDERR.puts "#{"error".colorize.red.bold}: application secret must be present"
      exit 1
    end
    output.print "\n"

    secret = secret.strip

    unless secret.starts_with? "cbkey_"
      msg = "\n#{"error".colorize.red.bold}: The key provided is not a valid API key.\n" \
            "  Verify that you are using an API key that is prefixed with 'cbkey_'.\n" \
            "  You can manage your API keys here: https://crunchybridge.com/account/api-keys\n"

      STDERR.puts msg
      exit 1
    end

    output << "Storing credentials... "
    creds = Creds.new(host, secret).store
    status = creds ? "OK".colorize.green.bold : "Failed".colorize.red.bold
    output << "#{status}\n"
    creds
  end
end

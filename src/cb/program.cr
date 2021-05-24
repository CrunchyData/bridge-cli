class IO
  # no-op for non-file descriptor IOs, e.g. specs
  def noecho
    yield
  end
end

class CB::Program
  class Error < Exception
  end

  property input : IO
  property output : IO
  property host : String
  property creds : CB::Creds?
  property token : CB::Token?

  def initialize(@host = "api.crunchybridge.com", @input = STDIN, @output = STDOUT)
  end

  def login
    output.puts "add credentials for #{host} >"
    output.print "  application ID: "
    id = input.gets
    raise Error.new "applicaton ID must be present" if id.nil? || id.empty?

    print "  application secret: "
    secret = input.noecho { input.gets }
    raise Error.new "applicatoin secret must be present" if secret.nil? || secret.empty?
    output.print "\n"

    Creds.new(host, id, secret).store
  end

  def creds : CB::Creds
    if c = @creds
      return creds
    end
    @cred = Creds.for_host(host) || login
  end

  def token : CB::Token
    if t = @token
      return t
    end
    t = Token.for_host(host) || Client.get_token(creds)
    @token = t
  end
end

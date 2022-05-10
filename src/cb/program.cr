require "./creds"
require "./token"

class CB::Program
  class Error < Exception
    property show_usage : Bool = false
  end

  property input : IO
  property output : IO
  property host : String
  property subdomain : String
  property creds : CB::Creds?
  property token : CB::Token?

  def initialize(host = nil, subdomain = nil, @input = STDIN, @output = STDOUT)
    @host = host || "api.crunchybridge.com"
    @subdomain = subdomain || "db"
    Colorize.enabled = false unless output == STDOUT && input == STDIN
  end

  def login
    raise Error.new "No valid credentials found. Please login." unless output.tty?
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

  def creds : CB::Creds
    if c = @creds
      return c
    end
    @cred = Creds.for_host(host) || login
  end

  def token : CB::Token
    if t = @token
      return t
    end
    t = Token.for_host(host) || get_token
    @token = t
  end

  private def get_token
    Client.get_token(creds)
  rescue e : Client::Error
    if e.unauthorized?
      STDERR << "error".colorize.t_warn << ": Credentials invalid. Please login again.\n"
      creds.delete
      exit 1
    end
    raise e
  end

  # api may lose the token before it's actually expired
  # returns false if the token didn't need to be refreshed
  #         true if refreshing the token worked and the user should retry
  # it is assumed that the token will work after a refresh
  def ensure_token_still_good : Bool
    return false if test_token # token already works
    @token = get_token
    return true if test_token # token was fixed after refresh

    STDERR << "error".colorize.t_warn << ": Could not refresh token. Please login again.\n"
    exit 1
  end

  private def test_token
    token_works = false
    begin
      client.get_teams
      token_works = true
    rescue Client::Error
    end
    token_works
  end

  def client
    Client.new token
  end
end

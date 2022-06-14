require "./creds"
require "./token"
require "./action/*"

class CB::Program
  class Error < Exception
    property show_usage : Bool = false

    def message
      @message || @cause.try &.message
    end
  end

  property input : IO
  property output : IO
  property creds : CB::Creds?
  property token : CB::Token?

  def initialize(@input = STDIN, @output = STDOUT)
    Colorize.enabled = false unless output == STDOUT && input == STDIN
  end

  def creds : CB::Creds
    if c = @creds
      return c
    end
    @cred = Creds.for_host(CB::HOST) || Action::Login.new.run
  end

  def token : CB::Token
    if t = @token
      return t
    end
    t = Token.for_host(CB::HOST) || get_token
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

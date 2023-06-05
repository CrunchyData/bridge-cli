require "./creds"

class CB::Program
  class Error < Exception
    property show_usage : Bool = false

    def message
      @message || @cause.try &.message
    end
  end

  property input : IO
  property output : IO
  property creds : String?

  def initialize(@input = STDIN, @output = STDOUT)
    Colorize.enabled = false unless output == STDOUT && input == STDIN
  end

  def creds : String?
    return @creds if @creds
    @creds = Credentials.get || CB::Login.new.run
  end

  def client
    Client.new host: CB::HOST, bearer_token: creds
  end
end

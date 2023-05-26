require "./action"

module CB
  # Uses the API key bundled into cb to open a Dashboard session for them by
  # creating a session and opening a browser via appropriate system command.
  class Open < APIAction
    # Make the open command stub-able for testing purposes.
    property open : Proc(Array(String), Process::Env, NoReturn?)

    def initialize(@client, @input = STDIN, @output = STDOUT)
      @open = ->(args : Array(String), env : Process::Env) { CB::Lib::Open.exec(args, env: env) }
    end

    def run
      raise Error.new "Cannot open browser session with #{"CB_API_KEY".colorize.red.bold} set." if ENV["CB_API_KEY"]?

      session = client.create_session Client::SessionCreateParams.new(generate_one_time_token: true)
      # A one-time token is sent via query string since we don't have any choice
      # while using an executable like `open`, which means that there is some
      # potential danger of it leaking to logs. To protect against this, tokens
      # are always burned by the API on first sight, so unless the request fails
      # before entering the API stack, it'll never be possible to retry logging
      # in with this session. One-time tokens are also automatically expired a
      # minute after first creation, so they must always be used immediately.
      login_url = "https://#{client.host}/sessions/#{session.id}/actions/login?one_time_token=#{session.one_time_token}"

      self.open.call([login_url], {} of String => String)
    end
  end
end

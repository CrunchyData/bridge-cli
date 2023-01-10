require "./action"

module CB
  # Uses the API key bundled into cb to open a Dashboard session for them by
  # creating a session and opening a browser via appropriate system command.
  class Open < APIAction
    # Make the open command stub-able for testing purposes.
    property open : Proc(Array(String), Process::Env, NoReturn?)

    # At compile time is bundled with the name of an executable that can be made
    # to open a web browser to a URL on a target system.
    def self.open_command
      {% if flag?(:darwin) %}
        "open"
      {% elsif flag?(:linux) %}
        "xdg-open"
      {% else %}
        raise Error.new "Sorry, don't know how to open a web browser on your operating system"
      {% end %}
    end

    def initialize(@client, @input = STDIN, @output = STDOUT)
      @open = ->(args : Array(String), env : Process::Env) { Process.exec(self.class.open_command, args, env: env) }
    end

    def run
      session = client.create_session Client::SessionCreateParams.new(generate_one_time_token: true)

      # A one-time token is sent via query string since we don't have any choice
      # while using an executable like `open`, which means that there is some
      # potential danger of it leaking to logs. To protect against this, tokens
      # are always burned by the API on first sight, so unless the request fails
      # before entering the API stack, it'll never be possible to retry logging
      # in with this session. One-time tokens are also automatically expired a
      # minute after first creation, so they must always be used immediately.
      login_url = "https://#{client.host}/sessions/#{session.id}/actions/login?one_time_token=#{session.one_time_token}"

      begin
        self.open.call([login_url], {} of String => String)
      rescue e : File::NotFoundError
        raise Error.new "Command '#{self.class.open_command}' could not be found"
      end
    end
  end
end

module CB::Lib
  class Open
    private OPEN_COMMAND = {% if flag?(:darwin) %}
                             "open"
                           {% elsif flag?(:linux) %}
                             "xdg-open"
                           {% else %}
                             raise CB::Program::Error.new "Sorry, don't know how to open a web browser on your operating system"
                           {% end %}

    def self.can_open_browser?
      {% if flag?(:darwin) %}
        true
      {% elsif flag?(:linux) %}
        begin
          Process.run("xdg-settings", ["get", "default-web-browser"]).success?
        rescue IO::Error
          false
        end
      {% else %}
        false
      {% end %}
    end

    def self.run(args : Array(String), env : Process::Env = {} of String => String) : Bool
      status = Process.run(OPEN_COMMAND, args: args, env: env)
      status.success?
    rescue e : File::NotFoundError
      raise CB::Program::Error.new "Command '#{OPEN_COMMAND}' could not be found."
    end

    def self.exec(args : Array(String), env : Process::Env = {} of String => String) : NoReturn?
      Process.exec(OPEN_COMMAND, args, env: env)
    end
  end
end

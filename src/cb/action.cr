require "log"

module CB
  abstract class Action
    Log   = ::Log.for("Action")
    Error = Program::Error

    property input : IO
    property output : IO
    getter client

    def initialize(@client : Client, @input = STDIN, @output = STDOUT)
    end

    def call
      Log.info { "calling #{self.class}" }
      run
    end

    abstract def run

    private def raise_arg_error(field, value)
      raise Error.new "Invalid #{field.colorize.bold}: '#{value.to_s.colorize.red}'"
    end

    private def check_required_args
      missing = [] of String
      yield missing
      unless missing.empty?
        s = missing.size > 1 ? "s" : ""
        raise Error.new "Missing required argument#{s}: #{missing.map(&.colorize.red).join(", ")}"
      end
      true
    end

    private def print_team_slash_cluster(c, io : IO)
      team_name = team_name_for_cluster c
      io << team_name << "/" if team_name
      io << c.name.colorize.t_name << "\n"
      team_name
    end

    private def team_name_for_cluster(c)
      # no way to look up a single team yet
      client.get_teams.find { |t| t.id == c.team_id }.try &.name.colorize.t_alt
    end
  end
end

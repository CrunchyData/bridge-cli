module CB
  struct Display
    getter client

    def initialize(@client : Client)
    end

    def print_team_slash_cluster(c, io : IO)
      team_name = team_name_for_cluster c
      io << team_name << "/" if team_name
      io << c.name.colorize.t_name << "\n"
      team_name
    end

    def team_name_for_cluster(c)
      # no way to look up a single team yet
      client.get_teams.find { |t| t.id == c.team_id }.try &.name.colorize.t_alt
    end
  end
end

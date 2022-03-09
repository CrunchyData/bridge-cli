require "./action"

class CB::TeamList < CB::Action
  def run
    teams = client.get_teams
    name_max = teams.map(&.name.size).max? || 0
    teams.each do |team|
      output << team.id.colorize.t_id
      output << "\t"
      output << team.name.ljust(name_max).colorize.t_name
      output << "\t"
      output << team.role.to_s.titleize
      output << "\n"
    end
  end
end

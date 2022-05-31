require "./action"

class CB::List < CB::APIAction
  def run
    teams = client.get_teams
    clusters = client.get_clusters(teams)
    cluster_max = clusters.map(&.name.size).max? || 0

    clusters.each do |cluster|
      output << cluster.id.colorize.t_id
      output << "\t"
      output << cluster.name.ljust(cluster_max).colorize.t_name
      output << "\t"
      team_name = teams.find { |t| t.id == cluster.team_id }.try &.name || cluster.team_id
      output << team_name.colorize.t_alt
      output << "\n"
    end
  end
end

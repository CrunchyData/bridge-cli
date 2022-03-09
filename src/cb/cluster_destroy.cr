require "./action"

class CB::ClusterDestroy < CB::Action
  eid_setter cluster_id

  def run
    c = client.get_cluster cluster_id
    output << "About to " << "delete".colorize.t_warn << " cluster " << c.name.colorize.t_name
    team_name = team_name_for_cluster c
    output << " from team #{team_name}" if team_name
    output << ".\n  Type the cluster's name to confirm: "
    response = input.gets
    if c.name == response
      client.destroy_cluster cluster_id
      output.puts "Cluster #{c.id.colorize.t_id} destroyed"
    else
      output.puts "Response did not match, did not destroy the cluster"
    end
  end
end

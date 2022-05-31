require "./action"

class CB::ClusterRename < CB::APIAction
  eid_setter cluster_id
  property new_name : String?

  def run
    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    new_c = client.update_cluster cluster_id, {"name" => new_name}

    output << "renamed to " << new_c.name.colorize.t_name << "\n"
  end
end

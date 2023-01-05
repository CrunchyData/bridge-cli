require "./action"

class CB::Restart < CB::APIAction
  cluster_identifier_setter cluster_id
  bool_setter confirmed
  bool_setter full

  def validate
    check_required_args do |missing|
      missing << "cluster" if cluster_id.empty?
    end
  end

  def run
    validate

    c = client.get_cluster cluster_id[:cluster]
    confirm_action("restart", "cluster", c.name) unless confirmed

    service = full ? "server" : "postgres"

    client.restart_cluster cluster_id[:cluster], service
    output.puts "Cluster #{c.id.colorize.t_id} restarted."
  end
end

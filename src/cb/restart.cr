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

    unless confirmed
      output << "About to " << "restart".colorize.t_warn << " cluster " << c.name.colorize.t_name
      output << ".\n  Type the cluster's name to confirm: "
      response = input.gets

      if c.name == response
        self.confirmed = true
      else
        raise Error.new "Response did not match, did not restart the cluster."
      end
    end

    service = full ? "server" : "postgres"

    client.restart_cluster cluster_id[:cluster], service
    output.puts "Cluster #{c.id.colorize.t_id} restarted."
  end
end

require "./action"

class CB::Restart < CB::Action
  eid_setter cluster_id
  property confirmed : Bool = false

  def run
    validate

    c = client.get_cluster cluster_id

    unless confirmed
      output << "About to " << "restart".colorize.t_warn << " cluster " << c.name.colorize.t_name
      output << ".\n  Type the cluster's name to confirm: "
      response = input.gets

      if c.name == response
        self.confirmed = true
      else
        raise Error.new "Response did not match, did not restart the cluster"
      end
    end

    client.restart_cluster cluster_id
    output.puts "Cluster #{c.id.colorize.t_id} restarted"
  end

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
    end
  end
end

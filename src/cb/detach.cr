require "./action"

class CB::Detach < CB::APIAction
  cluster_identifier_setter cluster_id
  property confirmed : Bool = false

  def validate
    check_required_args do |missing|
      missing << "cluster" if cluster_id.empty?
    end
  end

  def run
    validate

    c = client.get_cluster cluster_id[:cluster]
    confirm_action("detach", "cluster", c.name) unless confirmed

    client.detach_cluster cluster_id[:cluster]
    output.puts "Cluster #{c.id.colorize.t_id} detached."
  end
end

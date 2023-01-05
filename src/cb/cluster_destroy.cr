require "./action"

class CB::ClusterDestroy < CB::APIAction
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
    confirm_action("destroy", "cluster", c.name) unless confirmed

    client.destroy_cluster c.id
    output << "Cluster #{c.id.colorize.t_id} destroyed\n"
  end
end

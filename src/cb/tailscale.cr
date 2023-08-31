require "./action"

abstract class CB::TailscaleAction < CB::APIAction
  cluster_identifier_setter cluster_id

  def validate
    check_required_args { |missing| missing << "cluster" unless cluster_id }
  end
end

# Action to connect a cluster to a tailscale network
class CB::TailscaleConnect < CB::TailscaleAction
  property auth_key : String?

  def validate
    super
    check_required_args { |missing| missing << "authkey" unless auth_key }
  end

  def run
    validate
    output.puts client.cluster_action_tailscale_connect(@cluster_id[:cluster])
  end
end

# Action to remove a cluster to a tailscale network
class CB::TailscaleDisconnect < CB::TailscaleAction
  def run
    validate
    output.puts client.cluster_action_tailscale_disconnect(@cluster_id[:cluster])
  end
end

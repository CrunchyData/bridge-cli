require "./action"

abstract class CB::TailscaleAction < CB::APIAction
  eid_setter cluster_id

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

    response = client.put "clusters/#{cluster_id}/actions/tailscale-connect", {auth_key: auth_key}
    output.puts JSON.parse(response.body)["message"]
  end
end

# Action to remove a cluster to a tailscale network
class CB::TailscaleDisconnect < CB::TailscaleAction
  def run
    validate

    response = client.put "clusters/#{cluster_id}/actions/tailscale-disconnect"
    output.puts JSON.parse(response.body)["message"]
  end
end

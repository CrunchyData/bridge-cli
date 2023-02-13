require "./client"

module CB
  class Client
    jrecord FirewallRule, id : String, rule : String

    # Add a firewall rule to a cluster.
    #
    # TODO (abrightwell): Add docs reference.
    def add_firewall_rule(network_id, cidr)
      post "networks/#{network_id}/firewall-rules", {rule: cidr}
    end

    # Remove a firewall rule from a cluster.
    #
    # TODO (abrightwell): Add docs reference.
    def delete_firewall_rule(network_id, firewall_rule_id)
      delete "networks/#{network_id}/firewall-rules/#{firewall_rule_id}"
    end

    # List current firewall rules for a cluster.
    #
    # TODO (abrightwell): Add docs reference.
    def get_firewall_rules(network_id)
      resp = get "networks/#{network_id}/firewall-rules"
      Array(FirewallRule).from_json resp.body, root: "firewall_rules"
    end
  end
end

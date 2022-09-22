require "./client"

module CB
  class Client
    jrecord FirewallRule, id : String, rule : String

    # Add a firewall rule to a cluster.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridfirewall/create-firewall-rule
    def add_firewall_rule(cluster_id, cidr)
      post "clusters/#{cluster_id}/firewall", {rule: cidr}
    end

    # Remove a firewall rule from a cluster.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridfirewallruleid/destroy-firewall-rule
    def delete_firewall_rule(cluster_id, firewall_rule_id)
      delete "clusters/#{cluster_id}/firewall/#{firewall_rule_id}"
    end

    # List current firewall rules for a cluster.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridfirewall/list-firewall-rules
    def get_firewall_rules(cluster_id)
      resp = get "clusters/#{cluster_id}/firewall"
      Array(FirewallRule).from_json resp.body, root: "firewall_rules"
    end
  end
end

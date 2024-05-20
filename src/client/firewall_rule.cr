require "json"

require "./client"

module CB
  class Client
    jrecord FirewallRuleCreateParams,
      description : String? = nil,
      rule : String = ""

    # Add a firewall rule to a network.
    #
    # https://docs.crunchybridge.com/api/network-firewall-rule#create-firewall-rule
    def create_firewall_rule(network_id, params : FirewallRuleCreateParams)
      resp = post "networks/#{network_id}/firewall-rules", params
      CB::Model::FirewallRule.from_json resp.body
    end

    # Remove a firewall rule from a network.
    #
    # https://docs.crunchybridge.com/api/network-firewall-rule#destroy-firewall-rule
    def destroy_firewall_rule(network_id, firewall_rule_id)
      resp = delete "networks/#{network_id}/firewall-rules/#{firewall_rule_id}"
      CB::Model::FirewallRule.from_json resp.body
    end

    # List current firewall rules for a network.
    #
    # https://docs.crunchybridge.com/api/network-firewall-rule#list-firewall-rules
    def get_firewall_rules(network_id)
      resp = get "networks/#{network_id}/firewall-rules"
      Array(CB::Model::FirewallRule).from_json resp.body, root: "firewall_rules"
    end

    jrecord FirewallRuleUpdateParams, description : String?, rule : String?

    # Update a firewall rule for a network.
    #
    # https://docs.crunchybridge.com/api/network-firewall-rule#update-firewall-rule
    def update_firewall_rule(network_id, firewall_rule_id, params : FirewallRuleUpdateParams)
      resp = patch "networks/#{network_id}/firewall-rules/#{firewall_rule_id}", params
      CB::Model::FirewallRule.from_json resp.body
    end
  end
end

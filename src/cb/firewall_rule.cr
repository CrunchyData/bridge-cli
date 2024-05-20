require "./action"

module CB
  # API Action for network firewall rules.
  #
  # All network firewall rule actions must inherit this action.
  abstract class FirewallRuleAction < APIAction
    # The output format. The default format is `table` format.
    format_setter format

    # The ID of the target network.
    eid_setter network_id

    # Flag to indicate whether the output should include a header. This only
    # has an effect when the output format is a table.
    property? no_header : Bool = false

    def validate
      check_required_args do |missing|
        missing << "network" unless @network_id
      end
    end

    abstract def run

    def display(firewall_rules : Array(Model::FirewallRule))
      case @format
      when Format::Default, Format::Table
        output_table(firewall_rules)
      when Format::JSON
        output_json(firewall_rules)
      end
    end

    def output_json(firewall_rules : Array(Model::FirewallRule))
      output << {
        "firewall_rules": firewall_rules,
      }.to_pretty_json << '\n'
    end

    def output_table(firewall_rules : Array(Model::FirewallRule))
      table = Table::TableBuilder.new(border: :none) do
        columns do
          add "ID"
          add "Rule"
          add "Description"
        end

        header unless @no_header

        rows firewall_rules.map { |fwr| [fwr.id, fwr.rule, fwr.description] }
      end

      output << table.render << '\n'
    end
  end

  # Action for adding a firewall rule to a network.
  class FirewallRuleAdd < FirewallRuleAction
    # The rule (required).
    property rule : String = ""

    # The description of the rule.
    property description : String?

    def validate
      super

      check_required_args do |missing|
        missing << "rule" if @rule.empty?
      end
    end

    def run
      validate

      firewall_rule = client.create_firewall_rule(
        network_id: @network_id,
        params: CB::Client::FirewallRuleCreateParams.new(
          description: @description,
          rule: @rule.to_s
        )
      )

      display([firewall_rule])
    end
  end

  # Action for listing existing firewall rules for a network.
  class FirewallRuleList < FirewallRuleAction
    def run
      validate

      firewall_rules = client.get_firewall_rules(@network_id)

      display(firewall_rules)
    end
  end

  # Action for removing a firewall rule from a network
  class FirewallRuleRemove < FirewallRuleAction
    # The ID of the firewall rule to remove.
    eid_setter firewall_rule_id

    def validate
      super

      check_required_args do |missing|
        missing << "firewall-rule" unless @firewall_rule_id
      end
    end

    def run
      validate

      firewall_rule = client.destroy_firewall_rule(network_id, firewall_rule_id)

      display([firewall_rule])
    end
  end

  # Action for updating an existing firewall rule for a network.
  class FirewallRuleUpdate < FirewallRuleAction
    # The ID of the firewall rule to update.
    eid_setter firewall_rule_id

    # The rule.
    property rule : String?

    # The description of the rule.
    property description : String?

    def validate
      super

      check_required_args do |missing|
        missing << "firewall-rule" unless @firewall_rule_id
      end
    end

    def run
      validate

      firewall_rule = client.update_firewall_rule(
        network_id: @network_id,
        firewall_rule_id: @firewall_rule_id,
        params: CB::Client::FirewallRuleUpdateParams.new(
          description: @description,
          rule: @rule,
        )
      )

      display([firewall_rule])
    end
  end
end

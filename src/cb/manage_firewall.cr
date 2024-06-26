class CB::ManageFirewall < CB::APIAction
  Error = Program::Error

  eid_setter cluster_id
  property network_id : String?
  property to_add = [] of String
  property to_remove = [] of String

  def add(cidr : String)
    to_add << cidr
  end

  def remove(cidr : String)
    to_remove << cidr
  end

  def run
    raise Error.new "--cluster not set" unless cluster_id
    @network_id = @client.get_cluster(cluster_id).network_id
    remove_all
    add_all
    display_rules
  end

  def remove_all
    return if to_remove.empty?
    current_rules = @client.get_firewall_rules(@network_id)

    to_remove.uniq.each do |cidr|
      cidr_str = cidr.colorize.t_name
      if rule = current_rules.find { |r| r.rule == cidr }
        output << "removing #{cidr_str} … " << remove_rule(rule) << "\n"
      else
        output << "not removing".colorize.t_warn << " #{cidr_str} — does not exist\n"
      end
    end
  end

  def add_all
    to_add.uniq.each do |cidr|
      cidr_str = cidr.colorize.t_name
      output << "adding #{cidr_str} … " << add_rule(cidr) << "\n"
    end
  end

  def display_rules
    current_rules = @client.get_firewall_rules(@network_id)

    pad = if output.tty?
            output.puts "allowed cidrs:"
            output.puts "  none" if current_rules.empty?
            "  "
          else
            ""
          end

    current_rules.each { |r| output.puts "#{pad}#{r.rule.colorize.t_name}" }
  end

  def remove_rule(rule : CB::Model::FirewallRule)
    @client.destroy_firewall_rule @network_id, rule.id
    "done".colorize.t_success
  rescue e : Client::Error
    output.print e
  end

  def add_rule(cidr : String)
    @client.create_firewall_rule @network_id, CB::Client::FirewallRuleCreateParams.new(rule: cidr)
    "done".colorize.t_success
  rescue e : Client::Error
    output.print e
  end
end

require "./action"

class CB::ClusterInfo < CB::Action
  eid_setter cluster_id

  def run
    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    details = {
      "state"    => c.state,
      "created"  => c.created_at.to_rfc3339,
      "plan"     => "#{c.plan_id} (#{c.memory}GiB ram, #{c.cpu}vCPU)",
      "version"  => c.major_version,
      "storage"  => "#{c.storage}GiB",
      "ha"       => (c.is_ha ? "on" : "off"),
      "platform" => c.provider_id,
      "region"   => c.region_id,
    }

    if source = c.source_cluster_id
      details["source cluster"] = source
    end

    details["network"] = c.network_id if c.network_id

    pad = (details.keys.map(&.size).max || 8) + 2
    details.each do |k, v|
      output << k.rjust(pad).colorize.bold << ": "
      output << v << "\n"
    end

    firewall_rules = client.get_firewall_rules cluster_id
    output << "firewall".rjust(pad).colorize.bold << ": "
    if firewall_rules.empty?
      output << "no rules\n"
    else
      output << "allowed cidrs".colorize.underline << "\n"
    end
    firewall_rules.each { |fr| output << " "*(pad + 4) << fr.rule << "\n" }
  end
end

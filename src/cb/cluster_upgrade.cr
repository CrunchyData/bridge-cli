require "./action"

abstract class CB::Upgrade < CB::Action
  eid_setter cluster_id
  property confirmed : Bool = false

  abstract def run

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
    end
  end
end

# Action to start cluster upgrade.
class CB::UpgradeStart < CB::Upgrade
  bool_setter ha
  i32_setter postgres_version
  i32_setter storage
  property plan : String?

  def run
    validate

    c = client.get_cluster cluster_id

    unless confirmed
      output << "About to " << "upgrade".colorize.t_warn << " cluster " << c.name.colorize.t_name
      output << ".\n  Type the cluster's name to confirm: "
      response = input.gets

      if c.name == response
        confirmed = true
      else
        raise Error.new "Response did not match, did not upgrade the cluster"
      end
    end

    client.upgrade_cluster self
    output.puts "  Cluster #{c.id.colorize.t_id} upgrade started."
  end
end

# Action to cancel cluster upgrade.
class CB::UpgradeCancel < CB::Upgrade
  def run
    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    client.upgrade_cluster_cancel cluster_id
    output << "  upgrade cancelled\n".colorize.bold
  end
end

# Action to get the cluster upgrade status.
class CB::UpgradeStatus < CB::Upgrade
  def run
    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    operations = client.upgrade_cluster_status cluster_id

    if operations.empty?
      output << "  no upgrades in progress\n".colorize.bold
    else
      pad = (operations.map(&.flavor.size).max || 8) + 2
      operations.each do |op|
        output << op.flavor.rjust(pad).colorize.bold << ": "
        output << op.state << "\n"
      end
    end
  end
end

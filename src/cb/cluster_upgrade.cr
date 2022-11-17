require "./action"

abstract class CB::Upgrade < CB::APIAction
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
        self.confirmed = true
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
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    client.upgrade_cluster_cancel cluster_id
    output << "  operation cancelled\n".colorize.bold
  end
end

# Action to get the cluster upgrade status.
class CB::UpgradeStatus < CB::Upgrade
  property maintenance_only : Bool = false

  def run
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    operations = client.upgrade_cluster_status cluster_id
    details = {
      "maintenance window" => MaintenanceWindow.new(c.maintenance_window_start).explain,
    }

    operation_kind = "operations"
    if maintenance_only
      operation_kind = "maintenance operations"
      operations = operations.select { |op| op.flavor != "ha_change" }
    end

    operations.each do |op|
      details[op.flavor] = op.state
    end

    if operations.empty?
      output << "  no #{operation_kind} in progress\n".colorize.bold
    end

    pad = (details.keys.map(&.size).max || 8) + 2
    details.each do |k, v|
      output << k.rjust(pad).colorize.bold << ": "
      output << v << '\n'
    end
  end
end
